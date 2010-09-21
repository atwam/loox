module Worker
  #
  # Launch parsers for a specific type (defined by @@parser_class) on an element.
  # Used as base worker for all parsing queues except base one
  #
  class ParseQueue < BaseWorker
    # @collection_id : the collection node. Used to get absolute path
    # @parent_id : parent element id or nil
    # @path : path relative to collection root
    def self.perform(element_id)
      element = Element.find(element_id)
      if element
        if File.exists?(element.full_path)
          logger.info("Starting parsing of element #{element_id} (#{element.full_path}) on parser class #{parser_class}")
          
          parsers = parser_class.all_for_mime_type(element[:mime_type]).asc(:priority)
          parsers.each do |parser|
            begin
              parser.parse(element)
            rescue e
              logger.error("Parser #{parser} throwed an exception on #{element.full_path} (#{element.id})")
              logger.error(e)
            end
          end

          element.save if element.changed?
        else
          logger.error("Unable to find file #{element.full_path} for element #{element_id}")
        end
      else
        logger.error("Unable to find element #{element_id}")
      end
    end

  end
end
