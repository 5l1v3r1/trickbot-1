#!/usr/bin/env ruby

require 'logger'
require 'uri'
require 'net/http'
require 'net/https'
require 'socksify/http'
require 'mime/types'
require 'nokogiri'
require 'RMagick'

class TrickyHTTP
  # these hosts are either handled by a different
  # HTTP based plugin or are simply removed due to
  # service provider or developer discretion
  BLACKLIST_HOSTS = [
    #'www.google.com',   # google doesn't like web-scrapers
    #'google.com',       # and they provide an API for that stuff
    'www.youtube.com',
    'youtube.com',
    'youtu.be',
    #'www.amazon.com',   # amazon doesn't like web-scrapers
    #'amazon.com',
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
    'application/xhtml+xml',
    'text/x-web-markdown',
  ]

  # misc MIME typtes
  MIME_TYPES_IMAGE = [
    'image/xpm',
    'image/x-xpixmap',
    'image/bmp',
    'image/x-bitmap',
    'image/x-portable-bitmap',
    'image/x-windows-bmp',
    'image/jpeg',
    'image/pjpeg',
    'image/png',
    'image/tiff',
    'image/x-tiff',
  ]

  # misc MIME typtes
  MIME_TYPES_MISC = [
  ]

  # generate supported MIME types by concatenating all supported
  # groups of MIME types
  MIME_TYPES_SUPPORTED = []
  MIME_TYPES_SUPPORTED.concat(MIME_TYPES_HTML)
  MIME_TYPES_SUPPORTED.concat(MIME_TYPES_IMAGE)
  MIME_TYPES_SUPPORTED.concat(MIME_TYPES_MISC)

  def initialize(http_opts = {})
    defaults = {
      :max_redirects => 3,
      :proxy_enabled => false,
      :proxy_host => 'proxy.example.com',
      :proxy_port => 3128,
      :proxy_socks => false,
      :proxy_auth_enabled => false,
      :proxy_auth_user => '',
      :proxy_auth_pass => '',
    }
    @http_opts = defaults.merge(http_opts)

    # setup a logger
    @logger = Logger.new('./log/tricky_http.log', 'monthly', 12)
    @logger.level = Logger::DEBUG
    @logger.info('TrickyHTTP library starting up')
  end

  def parse_html(html)
    # parse the body of the HTML response
    begin
      body = Nokogiri::HTML(html)
      return "Could not parse HTML title element" unless body.at_css("title")
      title = body.at_css("title").content
      @logger.debug("title: #{title}")
      return title
    rescue Exception => e
      @logger.debug("not HTML: #{e}")
      return "not HTML: #{e}"
    end
  end

  def page_title(url, num_redirects = 0)
    if num_redirects >= @http_opts[:max_redirects]
      return "Error, too many redirects."
    end

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

    # TODO fix this fugly shit, seriously

    # are we using a proxy?
    if @http_opts[:proxy_enabled]
      if @http_opts[:proxy_socks]
        # setup a socks proxy

        # should we set authentication?
        if @http_opts[:proxy_auth_enabled]
          TCPSocket.socks_username = @http_opts[:proxy_auth_user]
          TCPSocket.socks_password = @http_opts[:proxy_auth_pass]
        end

        # setup our proxy
        proxy = Net::HTTP::SOCKSProxy(@http_opts[:proxy_host],
                                      @http_opts[:proxy_port])
        http = proxy.start(uri.host, uri.port,
                           :use_ssl => 'https'.eql?(uri.scheme),
                           :verify_mode => OpenSSL::SSL::VERIFY_NONE)
      else
        # setup a regular http proxy

        # sould we set authentication?
        if @http_opts[:proxy_auth_enabled]
          proxy = Net::HTTP::Proxy(@http_opts[:proxy_host],
                                   @http_opts[:proxy_port],
                                   @http_opts[:proxy_auth_user],
                                   @http_opts[:proxy_auth_pass])
        else
          proxy = Net::HTTP::Proxy(@http_opts[:proxy_host],
                                   @http_opts[:proxy_port])
        end
        http = proxy.start(uri.host, uri.port,
                           :use_ssl => 'https'.eql?(uri.scheme),
                           :verify_mode => OpenSSL::SSL::VERIFY_NONE)
      end
    else
      # setup the HTTP object
      http = Net::HTTP.new(uri.hostname, uri.port)
      if 'https'.eql? uri.scheme
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    # make a HEAD request to the server
    @logger.info("requesting HEAD: #{uri}")
    req_head = Net::HTTP::Head.new(uri)
    req_head['Accept'] = '*/*'

    # select and set a user agent for this transaction
    user_agent = USER_AGENTS.sample
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
      req = Net::HTTP::Get.new(uri)
      req['Accept'] = '*/*'
      req['User-Agent'] = user_agent

      @logger.info("GETting body: #{uri}")
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

        if MIME_TYPES_HTML.include? res_type.first
          # parse the body of the HTML response
          return parse_html(res.body)
        elsif MIME_TYPES_IMAGE.include? res_type.first
          begin
            img = Magick::Image.from_blob(res.body).first
            columns = img.columns
            rows = img.rows
            return "#{res_type.first} - #{columns} x #{rows}"
          rescue
            return "#{res_type.first} - INVALID IMAGE?"
          end
        else
          # misc. types, just return the content MIME type
          return "content-type #{res_type.first}"
        end
      elsif [ 301, 302, 303, 307, 308 ].include?(res.code.to_i)
        # handle redirect from the GET response headers
        @logger.debug("GET response #{res.code} redirect to #{res_head['Location']}")
        if res['Location'] == url
          @logger.debug("Error, redirects to same URL.")
          return "Error, redirects to same URL."
        end

        return page_title(res['Location'], num_redirects + 1)
      end
    elsif [ 301, 302, 303, 307, 308 ].include?(res_head.code.to_i)
      if res_head['Location'] == url
        @logger.debug("Error, redirects to same URL.")
        return "Error, redirects to same URL."
      end

      # handle redirect from the HEAD response headers
      @logger.debug("HEAD response #{res_head.code} redirect to #{res_head['Location']}")
      return page_title(res_head['Location'], num_redirects + 1)
    else
      return nil
    end
  end
end

if __FILE__ == $0
  if ARGV.empty?
    STDERR.puts "ERROR: No URL provided"
    STDERR.puts "Usage: #{$0} URL"
  end

  tricky = TrickyHTTP.new
  puts tricky.page_title(ARGV[0])
end
