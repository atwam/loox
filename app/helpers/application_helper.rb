module ApplicationHelper
  #
  # Returns _params_ hash without the _symbol_ pair.
  # It's only a copy, _params_ remains unchanged
  def params_remove(params, symbol)
    url_hash = params.dup
    url_hash.delete(symbol)
    url_hash
  end
end
