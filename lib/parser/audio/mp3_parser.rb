#
# Tries to parse more info about a mp3 file.
#
# Fields :
# media/length : length in seconds
#
require 'mp3info'
class Parser::Audio::Mp3Parser < Parser::FileChangeParser
  field :mime_types, :type => Array, :default => [ "audio/mpeg"]

  def parse(element)
    path = element.full_path

    if File.file?(path)
      begin
        mp3info = Mp3Info.open(path)
      rescue Exception=>exception
        logger.error("Error while trying to read #{path}", exception)
        return
      end

      element["file/media/length"] = mp3info.length
      element["file/audio/samplerate"] = mp3info.samplerate
      element["file/audio/mpeg/version"] = mp3info.mpeg_version
      element["file/audio/mpeg/layer"] = mp3info.layer
      element["file/audio/mpeg/vbr"] = mp3info.vbr

      if mp3info.hastag?
        %w{title artist album year tracknum genre genre_s}.each do |key|
          value = mp3info.tag[key]
          element["file/audio/#{key}"] = value
        end
        element.add_indexed_field %w{ file/audio/title file/audio/artist file/audio/album}
      end
    end
  end
end
