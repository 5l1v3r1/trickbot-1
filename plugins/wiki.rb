require 'cinch'

require_relative '../lib/tricky_wiki'

module TrickBot
  class Wiki
    include Cinch::Plugin

    match /wiki (.+)$/i, method: :wiki_lookup

    def initialize(*args)
      super

      @logger = Logger.new('./log/wiki.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
      @logger.info('TrickyWiki plugin starting up')

      # pass in our logger to TrickyWiki
      @wiki = TrickyWiki.new(@logger)
    end

    def wiki_lookup(m, titles)
      if @channel_whitelist.include? m.channel
        @logger.debug("#{m.user.nick} in #{m.channel} searched wikipedia for #{titles}")
        result = @wiki.wiki_search(titles)
        if result
          m.reply("#{result}")
        end
      end
    end
  end
end
