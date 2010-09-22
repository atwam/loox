# 
# Module for a guesser class
#
module Parser::Meta::Guesser
  def self.included(base)
    base.extend AddGuessMethod
  end

  module AddGuessMethod
    def guess(name, &block)
      @@guessers ||= {}
      @@guessers[name] = block
    end
  end
end

