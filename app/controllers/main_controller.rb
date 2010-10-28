class MainController < ApplicationController
  def index
  end

  def search
    @query = params[:q]
    @search = Sunspot.search(Element) do
      keywords params[:q] do
        highlight
      end
    end
    render :layout=>false
  end
end
