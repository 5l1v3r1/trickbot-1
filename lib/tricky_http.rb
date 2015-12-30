#!/usr/bin/env ruby

require 'logger'
require 'uri'
require 'net/http'
require 'net/https'
require 'mime/types'
require 'nokogiri'

class TrickyHTTP
  # these hosts are either handled by a different
  # HTTP based plugin or are simply removed due to
  # service provider or developer discretion
  BLACKLIST_HOSTS = [
    'www.google.com',   # google doesn't like web-scrapers
    'google.com',       # and they provide an API for that stuff
    'www.youtube.com',
    'youtube.com',
    'youtu.be',
    'www.amazon.com',   # amazon doesn't like web-scrapers
    'amazon.com',
    'imgur.com',        # imgur page titles are useless
  ]

  USER_AGENTS = [
    # chrome current stable & beta
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.0 Safari/537.36',

    # firefox current stable and one release back
    'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0',
    'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:43.0) Gecko/20100101 Firefox/42.0',

    # we will not emit Internet Explorer or Spartan/Edge User Agent strings
  ]

  # supported HTML MIME types
  MIME_TYPES_HTML = [
    'text/html',
    'application/xhtml+xml'
  ]

  # generate supported MIME types by concatenating all supported
  # groups of MIME types
  MIME_TYPES_SUPPORTED = []
  MIME_TYPES_SUPPORTED.concat(MIME_TYPES_HTML)

  def initialize
    # setup a logger
    @logger = Logger.new('./log/tricky_http.log', 12, 'monthly')
    @logger.level = Logger::DEBUG
    @logger.info('TrickyHTTP library starting up')
  end

  def parse_html(html)
    # parse the body of the HTML response
    begin
      body = Nokogiri::HTML(html)
      title = body.css("title")[0].text
      @logger.debug("title: #{title}")
      return title
    rescue Exception => e
      @logger.debug("not HTML: #{e}")
      return "not HTML: #{e}"
    end
  end

  def page_title(url)

    @logger.debug("resolving page title: #{url}")

    # validate the input URL via ruby
    uri = nil
    begin
      uri = URI.parse(url)
      if !uri.kind_of?(URI::HTTP)
        @logger.debug("#{url} is not http or https")
        return nil
      end
    rescue
      @logger.debug("invalid URL: #{url}")
      return nil
    end

    # make sure the host isn't blacklisted due to another plugin
    # handling that host or the host is known bad
    if BLACKLIST_HOSTS.include? uri.hostname
      @logger.debug("blacklisted URL: #{url}")
      return nil
    end

    # select a user agent for this transaction
    user_agent = USER_AGENTS.sample

    # setup the HTTP object
    http = Net::HTTP.new(uri.hostname, uri.port)
    if 'https'.eql? uri.scheme
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    # make a HEAD request to the server
    @logger.info("requesting HEAD: #{uri}")
    req_head = Net::HTTP::Head.new(uri)
    req_head['Accept'] = '*/*'
    req_head['User-Agent'] = user_agent

    # request info
    req_head.each_header do |header, value|
      @logger.debug("\t#{header}: #{value}")
    end

    # transmit request
    res_head = http.request(req_head)

    @logger.info("Response Code: #{res_head.code} (#{res_head.message})")
    res_head.each_header do |header, value|
      @logger.debug("\t#{header}: #{value}")
    end

    # ensure one of the following:
    #
    # 1.  The server gave us some headers to parse.  Not all will.
    #     Their admins should be punished severely, but they will likely
    #     never be held to account for this incompetence because history
    #     is full of injustices.
    #
    #   a) ensure response code is 200.  we don't presently follow redirects
    #   b) check response's Content-Type header for supported HTML mime types
    #
    # 2.  The server gave us 405, so we must foolishly attempt to just get the
    #     anyway.
    #
    # 3.  FUTURE - follow redirects, but don't cache permanent ones
    #
    res_head_type = MIME::Types[res_head['Content-Type']]
    if (res_head.code.to_i == 200 and MIME_TYPES_SUPPORTED.include? res_head_type.first) or
        res_head.code.to_i == 405
      # GET the rest of the URIs body
      @logger.info("GETting body: #{uri}")
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = '*/*'
      req['User-Agent'] = user_agent
      res = http.request(req)
      res_type = MIME::Types[res['Content-Type']]

      if (res.code.to_i == 200 and MIME_TYPES_SUPPORTED.include? res_type.first)
        req.each_header do |header, value|
          @logger.debug("\t#{header}: #{value}")
        end

        @logger.info("Response Code: #{res.code} (#{res.message})")
        res.each_header do |header, value|
          @logger.debug("\t#{header}: #{value}")
        end

        # parse the body of the HTML response
        return parse_html(res.body)
      end
    rlse
      return nil
    end
  end
end

#puts TrickyHTTP.page_title('http://code.tutsplus.com/tutorials/8-regular-expressions-you-should-know--net-6149')
