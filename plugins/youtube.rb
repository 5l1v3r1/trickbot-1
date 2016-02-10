require 'cinch'

require_relative '../lib/google'

module TrickBot
  class YouTube
    include Cinch::Plugin

    listen_to :connect, method: :on_connect

    match /(https?:\/\/www\.youtube.com\/watch\?v=([^\?&"'>]+))/, use_prefix: false, method: :show_title
    match /(https?:\/\/youtu.be\/([^\?&"'>]+))/, use_prefix: false, method: :show_title

    def initialize(*args)
      super

      # setup a logger
      @logger = Logger.new('./log/youtube.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
      @logger.info('YouTube plugin starting up')
    end

    def on_connect(c)
      @channel_whitelist = config[:channel_whitelist] || raise("Missing required argument: :channel_whitelist")
      api_key = config[:api_key] || raise("Missing required argument: :api_key")
      @google = Google.new(api_key)
    end

    def show_title(m, url, vid_id)
      if @channel_whitelist.include? m.channel
        m.reply("#{m.user.nick}'s YouTube: #{@google.youtube_video_title(vid_id)}")
      end
    end
  end
end
