# 
# Gets basic file info (name etc).
# Also detects file change and submit to the queue if needed
#
# Define fields :
#   size : integer, size of the field in bytes
#   mime_type : string, magic-guessed mime_type
#
#
require 'digest/sha1'
class Parser::BasicFile < Parser::BaseParser
  def parse(element)
    path = element.full_path

    element.name = File.basename(path)

    mime_type = MIME.check(path) rescue nil
    element[:mime_type] = mime_type.to_s if mime_type

    if File.file?(path)
      stat = File.stat(path)
      size = stat.size
      element[:size] = size
      element[:mtime] = stat.mtime

      digest = Digest::SHA1.new(size.to_s)
      begin
        digest.update(File.read(path, 50*1024))
      rescue # Pokemon error handling, in case we can't read the file
      end

      previous_hash = element[:content_hash]
      new_hash = element[:content_hash] = digest.to_s
      if true || previous_hash != new_hash
        logger.debug("Element #{element.id} (#{path}) has changed, enqueued for FileChange worker")
        Resque.enqueue(Worker::FileChange, element.id)
      end

    end
  end   
end
