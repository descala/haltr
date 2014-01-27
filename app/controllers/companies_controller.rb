class CompaniesController < ApplicationController

  unloadable
  menu_item Haltr::MenuItem.new(:companies,:my_company)
  menu_item Haltr::MenuItem.new(:companies,:linked_to_mine), :only => [:linked_to_mine]
  layout 'haltr'
  helper :haltr

  helper :sort
  include SortHelper
  include Haltr::TaxHelper

  before_filter :find_project_by_project_id, :only => [:my_company,:linked_to_mine,:logo,:add_bank_info,:check_iban]
  before_filter :find_company, :only => [:update]
  before_filter :set_iso_countries_language
  before_filter :authorize, :except => [:logo,:logo_by_taxcode]
  skip_before_filter :check_if_login_required, :only => [:logo,:logo_by_taxcode]

  def my_company
    if @project.company.nil?
      user_mail = User.find_by_project_id(@project.id).mail rescue ""
      # company should be already created by lib/company_filter
      @company = Company.new(:project=>@project,
                             :name=>@project.name,
                             :email=>user_mail)
      @company.save(:validate=>false)
    else
      @company = @project.company
    end
    @company.bank_infos.build if @company.bank_infos.empty?
    render :action => 'edit'
  end

  def linked_to_mine
    # TODO sort and paginate
    sort_init 'name', 'asc'
    sort_update %w(taxcode name)
    @companies = Client.all(:conditions => ['company_id = ?', @project.company]).collect do |client|
      client.project.company
    end
  end

  def update
    # check if user trying to add multiple bank_infos without role
    unless User.current.allowed_to?(:add_multiple_bank_infos,@project)
      if params[:company][:bank_infos_attributes] and 
        params[:company][:bank_infos_attributes].reject {|i,b| b["_destroy"] == "1" }.size > 1
        redirect_to project_add_bank_info_path(@project), :alert => "You are not allowed to add multiple bank accounts"
        return
      end
    end
    if @company.update_attributes(params[:company])
      unless @company.taxes.collect {|t| t unless t.marked_for_destruction? }.compact.any?
        @company.taxes = []
        @company.taxes = default_taxes_for(@company.country)
      end
      if params[:attachments]
        #TODO: validate content-type ?
        @company.attachments.each {|a| a.destroy }
        attachments = Attachment.attach_files(@company, params[:attachments])
        attachments[:files].each do |attachment|
          if attachment.content_type =~ /^image/
            begin
              require 'RMagick'
              image = Magick::Image.read("#{attachment.diskfile}").first
              image.change_geometry!('350x130>') {|cols,rows,img| img.resize!(cols, rows)}
              image.write("#{attachment.diskfile}")
            rescue LoadError
            end
          else
            flash[:warning] = l(:logo_not_image)
            attachment.destroy
          end
        end
        render_attachment_warning_if_needed(@company)
      end
      flash[:notice] = l(:notice_successful_update) 
      redirect_to :action => 'my_company', :project_id => @project
    else
      render :action => 'edit'
    end
  end

  def logo
    a = @project.company.attachments.first
    send_file a.diskfile, :filename => filename_for_content_disposition(a.filename),
      :type => detect_content_type(a),
      :disposition => (a.image? ? 'inline' : 'attachment')
  rescue
    send_file Rails.root.join("public/plugin_assets/haltr/img/transparent.gif"),
      :type => 'image/gif',
      :disposition => 'inline'
  end

  def logo_by_taxcode
    @project = Company.find_by_taxcode(params[:taxcode]).project
  rescue
  ensure
    logo
  end

  def add_bank_info
    #dummy action to allow check if user is authorized
    redirect_to project_my_company_path(@project)
  end

  def check_iban
    @iban_ok = true
    iban = params[:iban]
    unless iban.blank?
      @iban_ok = IBANTools::IBAN.valid?(iban)
    end
    render :partial => 'iban_ok'
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
