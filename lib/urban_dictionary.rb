#!/usr/bin/env ruby

require 'logger'
require 'rest-client'
require 'json'

class UrbanDictionary
  API_URL = 'http://api.urbandictionary.com/v0/define'

  def initialize(logger = nil)
    if !logger
      @logger = Logger.new('./log/urban_dictionary.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
    else
      @logger = logger
    end
  end

  def lookup(search)
    @logger.info("Requesting definition for #{search}")
    response = RestClient.get(API_URL, { :params => { :term => search, } })
    if response.code != 200
      @logger.info("HTTP Error!  Is urban dictionary down?")
      return "HTTP Error!  Is urban dictionary down?"
    end

    # wikipedia knows about it, parse the extract
    batch = JSON.parse(response)
    if !batch['list'].empty?
      return batch['list'].first['definition']
    else
      return "no results for #{search}"
    end
  end
end

if __FILE__ == $0
  if ARGV.empty?
    STDERR.puts "ERROR: No words provided to lookup"
    STDERR.puts "Usage: #{$0} WORDS ..."
  end

  ud = UrbanDictionary.new
  puts ud.lookup(ARGV.join(' '))
end
