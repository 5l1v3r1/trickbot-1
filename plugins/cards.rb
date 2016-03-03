require 'cinch'
require 'httparty'

module TrickBot
  class Cards
    include Cinch::Plugin

    CARDS_URL = 'http://www.cardsagainsthumanity.com/wcards.txt'

    match /(([^_]*_+[^_]*)+)/, method: :lets_play

    def initialize(*args)
      super

      shuffle
    end

    def shuffle
      if @cards.nil?
        # download our cards from http://www.cardsagainsthumanity.com/wcards.txt
        response = HTTParty.get(CARDS_URL)
        if response.code == 200
          # comes in the format 'cards=This is an answer.<>This is another...'
          deck = response.body.gsub(/^cards=/, '').strip
          @cards = deck.split('<>')

          # strip punctuation from the end of the answer since
          # the black card is usually punctuated already
          @cards.collect! do |card|
            card.gsub(/[.?!]$/, '')
          end
        end
      end
    end

    def lets_play(m, black_card)
      shuffle

      # now for that feel good deep in your heart magic feeling
      answer = black_card.gsub(/_+/) { @cards.sample }

      m.reply("#{m.user.nick}: #{answer}")
    end
  end
end
