#
# Worker to be run on the file_change queue.
# Will run all parsers subclasses of Parser::FileChangeParser
module Worker
  class FileChange < ParseQueue
    @queue = :file_change
    def self.parser_class
      Parser::FileChangeParser
    end
  end
end
