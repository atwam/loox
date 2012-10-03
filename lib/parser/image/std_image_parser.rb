#
# Tries to parse more info from standard image files.
#
# Fields :
# media/height : height in pixels
# media/width : width in pixels
# file/image/colors : number of colors
# file/image/format : image format
# file/image/depth_per_pixel : bits per pixel
# file/image/resolution/x : x resolution (pixels per inch)
# file/image/resolution/y : y resolution (pixels per inch)
# blob/thumbnail : thumbnail for this image, jpg binary data
require 'RMagick'
class Parser::Image::StdImageParser < Parser::FileChangeParser
  field :mime_types, :type => Array, :default => [ "image/"]

  def parse(element)
    path = element.full_path

    if File.file?(path) && element[:mime_type].start_with?("image/")
      begin
        img = Magick::Image::read(path).first
      rescue Exception=>exception
        logger.error("Error while trying to read #{path}")
        logger.error(exception)
        return
      end
      
      element["media/height"] = img.rows
      element["media/width"] = img.columns
      element["file/image/format"] = img.format
      element["file/image/colors"] = img.number_colors
      element["file/image/depth_per_pixel"] = img.depth
      element["file/image/resolution/x"] = img.x_resolution.to_i
      element["file/image/resolution/y"] = img.y_resolution.to_i
      img.properties.each do |name, value|
        element["file/image/properties/"+name.gsub(':','/')] = value
      end

      # Create the thumbnail if possible
      new_w, new_h = img.rows > img.columns ?
        [90, (90 * img.columns) / img.rows] :
        [(90 * img.rows) / img.columns, 90]

      img.thumbnail!(new_w, new_h)
      img.format = "JPEG"
      element["blob/thumbnail"] = img.to_blob do
        self.quality = 50
        self.format = "JPEG"
      end

    end
  end
end
