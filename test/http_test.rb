#!/usr/bin/env ruby

require 'uri'
require 'net/http'
require 'net/https'
require 'mime/types'
require 'nokogiri'

# check input
if ARGV.length < 1
  puts "Please specify a URI"
  exit -1
end

# these hosts are either handled by a different
# HTTP based plugin or are simply removed due to
# developer discretion
BLACKLIST_HOSTS = [
  'www.youtube.com',
  'youtube.com',
  'youtu.be',
  #'www.amazon.com',
  #'amazon.com',
]

# supported MIME content types for HTML title parsing
SUPPORTED_TYPES = [
  'text/html',
  'application/xhtml+xml'
]

USER_AGENTS = [
]

# get our URI
URI_INPUT = ARGV[0]

# validate the URI via regex
#unless /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/.match(URI_INPUT)
  #puts "#{URI_INPUT} doesn't match URI regex"
  #exit -1
#end

# validate the URI via ruby
uri = nil
begin
  uri = URI.parse(URI_INPUT)
  if !uri.kind_of?(URI::HTTP)
    puts "non HTTP(S) URI: #{URI_INPUT}"
    exit -1
  end
rescue
  puts "invalid URI: #{URI_INPUT}"
  exit -1
end

# check for blacklist hosts
if BLACKLIST_HOSTS.include? uri.hostname
  puts "#{uri.hostname} is on the hosts blacklist"
  exit -1
end

# setup the HTTP object
http = Net::HTTP.new(uri.hostname, uri.port)
if 'https'.eql? uri.scheme
  puts "HTTPS required"
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

# make a HEAD request to the server
puts "requesting HEAD of: #{uri}"
req_head = Net::HTTP::Head.new(uri)
req_head['Accept'] = '*/*'
req_head['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
res_head = http.request(req_head)

# request info
req_head.each_header do |header, value|
  puts "\t\t#{header}: #{value}"
end
puts "\n\n"

# HEADers response info
puts "\tCode: #{res_head.code} (#{res_head.message})"
puts "\tHeaders:"
res_head.each_header do |header, value|
  puts "\t\t#{header}: #{value}"
end
puts "\n\n"

# check response's Content-Type header for supported HTML mime types
res_type = MIME::Types[res_head['Content-Type']]
if (200 == res_head.code.to_i and SUPPORTED_TYPES.include? res_type.first) or
    405 == res_head.code.to_i
  # GET the rest of the URIs body
  puts "GETting body of \"#{uri}\":"
  req = Net::HTTP::Get.new(uri)
  req['Accept'] = '*/*'
  req['User-Agent'] = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
  res = http.request(req)

  puts "\tHeaders:"
  req.each_header do |header, value|
    puts "\t\t#{header}: #{value}"
  end
  puts "\n\n"

  puts "\tCode: #{res.code} (#{res.message})"
  res.each_header do |header, value|
    puts "\t\t#{header}: #{value}"
  end

  if SUPPORTED_TYPES.include? MIME::Types[res['Content-Type']].first
    begin
      # parse the body of the HTML response
      body = Nokogiri::HTML(res.body)
      puts "\tHTML:"
      puts "\t\tTitle: #{body.css("title")[0].text}"
    rescue Exception => e
      return "not HTML: #{e}"
    end
  end
end
