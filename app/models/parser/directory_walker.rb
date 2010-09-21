#
# DirectoryWalker : Just enqueue children for parsing, used to recurse directories
#
class Parser::DirectoryWalker < Parser
  def parse(element)
    path = element.full_path
    
    if File.directory?(path)
      Dir.foreach(path) do |filename|
        if filename != "." && filename != ".."
          collection_path = File.join(element.path, filename)
          logger.info("Queuing #{collection_path} for analysis")
          Resque.enqueue(Worker::AnalyzePath, element.collection_id, element.id, collection_path)
        end
      end
    end
  end
end
