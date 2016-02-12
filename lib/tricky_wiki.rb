#!/usr/bin/env ruby

require 'logger'
require 'rest-client'
require 'json'

class TrickyWiki
  API_URL = 'https://en.wikipedia.org/w/api.php'

  def initialize(logger = nil)
    if !logger
      @logger = Logger.new('./log/wiki.log', 'monthly', 12)
      @logger.level = Logger::DEBUG
    else
      @logger = logger
    end
  end

  def wiki_search(titles)
    # best results are when searches for all words
    # capitalized.  no capitals will rarely produce
    # good results.
    titles = titles.split(/ |\_/).map(&:capitalize).join(' ')

    @logger.info("Requesting information about #{titles}")
    response = RestClient.get(API_URL,
                              { :params =>
                                { :action => 'query',
                                  :format => 'json',
                                  :prop => 'extracts',
                                  :exintro => nil,
                                  :explaintext => nil,
                                  :exsentences => 2,
                                  :redirects => nil,
                                  :titles => titles,
                                }
                              })
    if response.code != 200
      @logger.info("HTTP Error!  Is wikipedia down?")
      return "HTTP Error!  Is wikipedia down?"
    end

    # wikipedia knows about it, parse the extract
    batch = JSON.parse(response)
    pages = batch['query']['pages']
    if pages.keys[0] == '-1'
      @logger.info("no results for #{titles}")
      return "no results for #{titles}"
    end

    # if the search was too ambiguous, wikipedia will tell us that
    # it may refer to one of many topics.
    extract = pages.values[0]['extract']
    if / may refer to:/ =~ extract
      @logger.info("#{titles} is too ambiguous")
      return "#{titles} is too ambiguous, try something more specific."
    end

    # ok, we've got something worth talking about
    @logger.info("#{extract}")
    return "#{extract}"
  end
end

if __FILE__ == $0
  if ARGV.empty?
    STDERR.puts "ERROR: No wiki titles provided"
    STDERR.puts "Usage: #{$0} WIKI_TITLES ..."
  end

  wiki = TrickyWiki.new
  puts wiki.wiki_search(ARGV.join(' '))
end
