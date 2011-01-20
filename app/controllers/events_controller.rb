class EventsController < ApplicationController
  unloadable

  before_filter :find_invoice

  def create
    @event = Event.new(params[:event])
    respond_to do |format|
      if @event.save
        flash[:notice] = 'Event was successfully created.'
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end


  private

  def find_invoice
    @invoice = InvoiceDocument.find params[:invoice_id]
  end

end
