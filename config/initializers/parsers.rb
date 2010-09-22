# All parser files have to be required here
# If they aren't, these classes won't be defined unless called
# and class hierarchy won't be properly initialized to be
# used by workers looking for parsers to use
#
# We could probably force a worker to load all classes from parsers
# defined in the db to avoid that.
require 'parser/audio/mp3_parser'
require 'parser/image/std_image_parser'
