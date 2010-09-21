module Worker
  class FileChange < ParseQueue
    @queue = :file_change
    def self.parser_class
      Parser::FileChangeParser
    end
  end
end
