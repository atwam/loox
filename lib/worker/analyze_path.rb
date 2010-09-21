module Worker
  class AnalyzePath
    @queue = :analyze

    #
    # @collection_id : the collection node. Used to get absolute path
    # @parent_id : parent element id or nil
    # @path : path relative to collection root
    def self.perform(collection_id, parent_id, path)
      element = Element.find_by_path(path)
      unless element
        element = Element.new(:path=>path, :collection_id=>collection_id)
        element.parent_id = parent_id if parent_id
        element.save
      end

      if File.exists?(element.full_path)
        parsers = Parser.all_for_mime_type(element[:mime_type]).asc(:priority)
        parsers.each do |parser|
          begin
            parser.parse(element)
          rescue e
            logger.error("Parser #{parser} throwed an exception on #{element.full_path} (#{element.id})")
            logger.error(e)
          end
        end

        if element.changed?
          element.save
        end
      end
    end
  end

  def logger
    @@logger ||= Logger.new("#{RAILS_ROOT}/log/worker_analyze_path.log")
  end
end
