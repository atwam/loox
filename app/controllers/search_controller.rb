class SearchController < ApplicationController
  def index
    @query = params[:q]

    if @query.blank?
      render :text=>""
      return
    end

    @search = Sunspot.search(Element) do
      keywords params[:q] do
        highlight
      end
      facet :media
      if params[:media]
        with(:media, params[:media])
      end
    end

    if request.xhr?
      render :partial=>'search_results', :locals=>{:search=>@search, :query=>@query}
    end
  end
end
