class CompaniesController < ApplicationController

  layout 'haltr'
  helper :haltr

  helper :sort
  include SortHelper
  include Haltr::TaxHelper

  before_filter :find_project_by_project_id,
    only: [:my_company,:bank_info,:connections,:customization,:logo,
           :add_bank_info,:check_iban]
  before_filter :find_company, :only => [:update]
  before_filter :authorize, :except => [:logo,:logo_by_taxcode]
  skip_before_filter :check_if_login_required, :only => [:logo,:logo_by_taxcode]
  before_filter :check_for_company,
    only: [:my_company,:bank_info,:connections,:customization]

  accept_api_auth :my_company

  def check_for_company
    if @project.company.nil?
      user_mail = User.find_by_project_id(@project.id).mail rescue ""
      if ExportChannels.available? Setting.plugin_haltr['default_invoice_format']
        default_invoice_format = Setting.plugin_haltr['default_invoice_format']
      else
        default_invoice_format = 'paper'
      end
      # company should be already created by lib/company_filter
      @company = Company.new(project:        @project,
                             name:           @project.name,
                             email:          user_mail,
                             invoice_format: default_invoice_format,
                             public:         'private')
      @company.save(:validate=>false)
    else
      @company = @project.company
    end
  end

  def my_company
    @company.bank_infos.build if @company.bank_infos.empty?
    respond_to do |format|
      format.html do
        render :action => 'edit'
      end
      format.api do
        params[:format] ||= 'json'
        render action: :my_company
      end
    end
  end

  def update
    # check if user trying to add multiple bank_infos without role
    unless User.current.allowed_to?(:add_multiple_bank_infos, @project)
      if params[:company][:bank_infos_attributes] and 
        params[:company][:bank_infos_attributes].reject {|i,b| b["_destroy"] == "1" }.size > 1
        redirect_to project_add_bank_info_path(@project), :alert => "You are not allowed to add multiple bank accounts"
        return
      end
    end
    # check if user trying to customize emails without role
    unless User.current.admin? or User.current.allowed_to?(:email_customization, @project)
      # keys come with lang (_ca,_en..) so remove last 3 chars
      if (params[:company].keys.collect {|k| k[0...-3]} & %w(invoice_mail_subject invoice_mail_body quote_mail_subject quote_mail_body)).any? or
          # normal keys, without lang
          (params[:company].keys & %w(email_customization pdf_template
           issued_invoice_notifications received_invoice_notifications
           received_order_notifications sii_imported_notifications
           sii_sent_notifications sii_state_changes_notifications)).any?
        render_403
        return
      end
    end
    # check if user trying to add company infos without role
    unless User.current.admin? or User.current.allowed_to?(:use_company_offices, @project)
      if params[:company][:company_offices_attributes]
        render_403
        return
      end
    end
    unless User.current.admin?
      # allow to modify own taxcode only if current is invalid #6279
      if @company.valid? or !@company.errors.messages.keys.include?(:taxcode)
        new_taxcode = params[:company][:taxcode]
        if new_taxcode.present? and new_taxcode != @company.taxcode
          flash[:warning] = I18n.t(:cant_modify_taxcode, suport_link: view_context.link_to(I18n.t(:suport_link), project_new_support_path(@company.project))).html_safe
          params[:company].delete(:taxcode)
        end
      end
    end
    if @company.update_attributes(params[:company].to_hash)
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
              flash[:warning] = $!.message
            rescue Magick::ImageMagickError
              flash[:warning] = l(:logo_not_image)
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
      @company.bank_infos.build if @company.bank_infos.empty?
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
    iban = params[:iban].try(:gsub,/\p{^Alnum}/, '')
    unless iban.blank?
      @iban_ok = IBANTools::IBAN.valid?(iban)
    end
    response.headers["IbanOk"] = @iban_ok.to_s
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

end
