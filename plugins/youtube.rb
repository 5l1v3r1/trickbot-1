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
      @google = Google.new

      # setup a logger
      @logger = Logger.new('./log/youtube.log', 12, 'monthly')
      @logger.level = Logger::DEBUG
      @logger.info('YouTube plugin starting up')
    end

    def on_connect(c)
      @channel_whitelist = config[:channel_whitelist] || raise("Missing required argument: :channel_whitelist")
    end

    def show_title(m, url, vid_id)
      if @channel_whitelist.include? m.channel
        m.reply("#{m.user.nick}'s YouTube: #{@Google.youtube_video_title(vid_id)}")
      end
    end
  end
end
