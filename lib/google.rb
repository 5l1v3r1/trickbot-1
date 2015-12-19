#!/usr/bin/env ruby

require 'rest-client'
require 'json'

class Google
  API_HOST = 'https://www.googleapis.com'
  API_KEY = 'GETYOUROWNAPIKEY!'

  YOUTUBE_VIDEOS_URL = 'youtube/v3/videos'

  def initialize
    # setup a logger
    @logger = Logger.new('./log/google.log', 12, 'monthly')
    @logger.level = Logger::DEBUG
    @logger.info('Google library starting up')
  end

  def youtube_video_title(vid_id)
    # see if google knows about the video
    @logger.info("Requesting title for YouTube id #{vid_id}")
    response = RestClient.get("#{API_HOST}/#{YOUTUBE_VIDEOS_URL}",
                              { :params =>
                                { :part => 'snippet',
                                  :id => vid_id,
                                  :key => API_KEY,
                                }
                              }
                            )
    if response.code != 200
      @logger.info('video not found')
      return 'video not found'
    end

    # google knows about it, parse the snippet
    snippet = JSON.parse(response)
    title = snippet['items'][0]['snippet']['title']
    @logger.info("video title: #{title}")
    return title
  end
end

#puts Google.video_title("V9AbeALNVkk")
