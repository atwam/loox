#
# Tries to guess various data/links for a file/directory.
# Main class will call sub parsers (guessers),
# store their data and push data with heighest relevance
# to the main meta field.
#
# Fields :
# meta/* : informations from the best guess
# meta/guesses/[guesser_name]/* : infos for each guesser
# meta/guesses/[guesser_name]/relevance : assumed score for this guesser
#                                         between 0 and 1
class Parser::Meta::MetaParser < Parser::FileChangeParser
  include Parser::Meta::Guesser

  def parse(element)
    path = element.full_path
  end

end
