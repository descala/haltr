class CompaniesController < ApplicationController

  unloadable
  menu_item :haltr_community
  layout 'haltr'
  helper :haltr

  before_filter :find_project, :except => [:update, :logo]
  before_filter :find_company, :only => [:update]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:logo]
  skip_before_filter :check_if_login_required, :only => [:logo]

  verify :method => [:post,:put], :only => [:update], :redirect_to => :root_path

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
      unless @company.taxes.collect {|t| t unless t.marked_for_destruction? }.compact.any?
        @company.taxes = []
        @company.taxes = TaxList.default_taxes_for(@company.country)
      end
      if params[:attachments]
        #TODO: validate content-type ?
        @company.attachments.each {|a| a.destroy }
        attachments = Attachment.attach_files(@company, params[:attachments])
        attachments[:files].each do |attachment|
          if attachment.content_type =~ /^image/
            begin
              require 'RMagick'
              image = Magick::Image.read("#{attachment.storage_path}/#{attachment.disk_filename}").first
              image.change_geometry!('350x130>') {|cols,rows,img| img.resize!(cols, rows)}
              image.write("#{attachment.storage_path}/#{attachment.disk_filename}")
            rescue LoadError => e
            end
          else
            flash[:warning] = l(:logo_not_image)
            attachment.destroy
          end
        end
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
    a = c.attachments.first
    send_file a.diskfile, :filename => filename_for_content_disposition(a.filename),
      :type => detect_content_type(a),
      :disposition => (a.image? ? 'inline' : 'attachment')
  rescue
    send_file "#{RAILS_ROOT}/public/plugin_assets/haltr/images/transparent.gif",
      :type => 'image/gif',
      :disposition => 'inline'
  end

  private

  def find_company
    @company = Company.find params[:id]
    @project = @company.project
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
