class ElementsController < ApplicationController
  
  # GET /elements/1
  # GET /elements/1.xml
  def show
    @element = Element.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.xml { render :xml => @element }
    end
  end
end
