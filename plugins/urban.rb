require 'cinch'

require_relative '../lib/urban_dictionary'

module TrickBot
  class Urban
    include Cinch::Plugin

    listen_to :connect, method: :on_connect

    match /urban (.+)$/, method: :lookup

    def initialize(*args)
      super

      @logger = Logger.new('./log/urban_dictionary.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
      @logger.info('Urban plugin starting up')

      # pass in our logger to TrickyWiki
      @ud = UrbanDictionary.new(@logger)
    end

    def on_connect(c)
      @channel_whitelist = config[:channel_whitelist] || raise("Missing required argument: :channel_whitelist")
    end

    def lookup(m, words)
      if @channel_whitelist.include? m.channel
        @logger.debug("#{m.user.nick} in #{m.channel} searched urban dictionary for #{words}")
        result = @wiki.lookup(words)
        if result
          m.reply("#{result}")
        end
      end
    end
  end
end
