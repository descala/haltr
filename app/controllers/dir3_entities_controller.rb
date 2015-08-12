class Dir3EntitiesController < ApplicationController
  unloadable

  layout 'admin'
  menu_item :dir3_entities
  before_filter :authorize_global
  helper :haltr

  include CsvImporter

  def index
    @dir3_entities = Dir3Entity.all(order: :name)
  end

  def new
    @dir3_entity = Dir3Entity.new
  end

  def create
    @dir3_entity = Dir3Entity.new(params[:dir3_entity])
    if @dir3_entity.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action=>'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @dir3_entity = Dir3Entity.find(params[:id])
  end

  def update
    @dir3_entity = Dir3Entity.find(params[:id])
    if @dir3_entity.update_attributes(params[:dir3_entity])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @dir3_entity = Dir3Entity.find(params[:id])
    @dir3_entity.destroy
    redirect_to :action => 'index'
  end

  def csv_import
    file = params[:csv_file]
    if file and file.size > 0
      existing, new, error, error_messages = process_dir3entities(entities: file.path)
      flash[:notice] = "Dir3Entities updated: #{existing}, created: #{new}, errors: #{error}. #{error_messages.join(', ')}"
    else
      flash[:error] = "Select a CSV file to import"
    end
    redirect_to action: 'index'
  end

end
