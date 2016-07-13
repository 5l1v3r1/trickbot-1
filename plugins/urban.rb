require 'cinch'

require_relative '../lib/urban_dictionary'

module TrickBot
  class Urban
    include Cinch::Plugin

    match /urban (.+)$/i, method: :lookup

    def initialize(*args)
      super

      @logger = Logger.new('./log/urban_dictionary.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
      @logger.info('Urban plugin starting up')

      # pass in our logger to TrickyWiki
      @ud = UrbanDictionary.new(@logger)
    end

    def lookup(m, words)
      if @channel_whitelist.include? m.channel
        @logger.debug("#{m.user.nick} in #{m.channel} searched urban dictionary for #{words}")
        result = @ud.lookup(words)
        if result
          m.reply("#{result}")
        end
      end
    end
  end
end
