require 'cinch'

require_relative '../lib/tricky_http'

module TrickBot
  class PageTitles
    include Cinch::Plugin

    listen_to :connect, method: :on_connect

    match /(https?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([+?#&!$;=\[\]~|%{}\/\w_\.-]*)*\/?)/, use_prefix: false, method: :scrape_page_title

    def initialize(*args)
      super

      @logger = Logger.new('./log/page_titles.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
      @logger.info('PageTitles plugin starting up')

      @tricky = TrickyHTTP.new
    end

    def on_connect(c)
      @channel_whitelist = config[:channel_whitelist] || raise("Missing required argument: :channel_whitelist")
    end

    def scrape_page_title(m, url)
      if @channel_whitelist.include? m.channel
        @logger.debug("#{m.user.nick} posted link in #{m.channel} to #{url}")
        title = @tricky.page_title(url)
        if !title.nil?
          # compress whitespace down
          title = title.gsub(/\s+/, ' ')

          @logger.debug("#{m.user.nick}'s link: #{title}")
          m.reply("#{m.user.nick}'s link: #{title}")
        end
      end
    end
  end
end
