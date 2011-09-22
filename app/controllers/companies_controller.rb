class CompaniesController < ApplicationController

  unloadable
  menu_item :haltr_community
  layout 'haltr'
  helper :haltr

  before_filter :project_patch
  before_filter :find_project, :except => [:update, :logo]
  before_filter :find_company, :only => [:update]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:logo]
  skip_before_filter :check_if_login_required, :only => [:logo]

  def index
    if @project.company.nil?
      @company = Company.new(:project=>@project, :name=>@project.name)
      @company.save(false)
    else
      @company = @project.company
    end
    render :action => 'edit'
  end

  def update
    #TODO: need to access company taxes before update_attributes, if not
    # updated taxes are not saved.
    # maybe related to https://rails.lighthouseapp.com/projects/8994/tickets/4642
    @company.taxes.each {|t| }
    if @company.update_attributes(params[:company])
      if params[:attachments]
        #TODO: validate content-type ?
        @company.attachments.each {|a| a.destroy }
        Attachment.attach_files(@company, params[:attachments])
        render_attachment_warning_if_needed(@company)
      end
      flash[:notice] = l(:notice_successful_update) 
      redirect_to :action => 'index', :id => @project
    else
      render :action => 'edit'
    end
  end

  def logo
    c = Company.find_by_taxcode params[:id]
    render :text=>"" and return unless c
    a = c.attachments.first
    render :text=>"" and return unless a
    send_file a.diskfile, :filename => filename_for_content_disposition(a.filename),
                                    :type => detect_content_type(a),
                                    :disposition => (a.image? ? 'inline' : 'attachment')
  end

  private

  def find_company
    @company = Company.find params[:id]
    @project = @company.project
  end

  def project_patch
    Project.send(:include, ProjectHaltrPatch) #TODO: perque nomes funciona el primer cop sense aixo?
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end

  def set_iso_countries_language
    ISO::Countries.set_language I18n.locale.to_s
  end

end
