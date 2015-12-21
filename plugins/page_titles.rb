require 'cinch'

require_relative '../lib/tricky_http'

module TrickBot
  class PageTitles
    include Cinch::Plugin

    listen_to :connect, method: :on_connect

    match /(https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w_\.-]*)*\/?)/, use_prefix: false, method: :scrape_page_title

    def initialize(*args)
      super
      @tricky = TrickyHTTP.new

      # setup a logger
      @logger = Logger.new('./log/page_titles.log', 12, 'monthly')
      @logger.level = Logger::DEBUG
      @logger.info('PageTitles plugin starting up')
    end

    def on_connect(c)
      @channel_whitelist = config[:channel_whitelist] || raise("Missing required argument: :channel_whitelist")
    end

    def scrape_page_title(m, url)
      @logger.debug("#{m.user.nick} posted link in #{m.channel} to #{url}")
      title = @tricky.page_title(url)
      if !title.nil? and @channel_whitelist.include? m.channel
        # compress whitespace down
        title = title.gsub(/\s+/, ' ')

        @logger.debug("#{m.user.nick}'s link: #{title}")
        m.reply("#{m.user.nick}'s link: #{title}")
      end
    end
  end
end
