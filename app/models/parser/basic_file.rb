# 
# Gets basic file info (name etc).
#
# Define fields :
#   size : integer, size of the field in bytes
#   mime_type : string, magic-guessed mime_type
#
#
require 'digest/sha1'
class Parser::BasicFile < Parser
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

      begin
        digest = Digest::SHA1.new(File.read(path, 50*1024))
        digest.update(size.to_s)
        element[:hash] = digest.to_s
      rescue # Pokemon error handling, in case we can't read the file
      end
    end
  end   
end
