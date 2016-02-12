#!/usr/bin/env ruby

require 'cinch'

# pull in our plugins
require_relative 'plugins/hello'
require_relative 'plugins/help'
require_relative 'plugins/youtube'
require_relative 'plugins/page_titles'
require_relative 'plugins/wiki'

# get that sucker up and online
trickbot = Cinch::Bot.new do
  configure do |c|
    # we're connecting through the chuckinator bouncer
    c.server = 'chat.freenode.net'
    c.user = 'trickbot'

    # nick & channels
    c.nick = 'trickbot'
    c.channels = [
      '#freenode',
    ]

    # plugin config
    c.plugins.prefix = /^trickbot: /
    c.plugins.plugins = [
      TrickBot::Help,
      TrickBot::Hello,
      TrickBot::YouTube,
      TrickBot::PageTitles,
      TrickBot::Wiki,
    ]
    c.plugins.options[TrickBot::PageTitles] = { :channel_whitelist => c.channels.to_a }
    c.plugins.options[TrickBot::YouTube] = { :channel_whitelist => c.channels.to_a,
                                             :api_key => nil, # TODO replace with your developer API key
                                           }
    c.plugins.options[TrickBot::Wiki] = { :channel_whitelist => c.channels.to_a }
  end
end

# setup the loggers
#trickbot.loggers << Cinch::Logger::FormattedLogger.new(File.open('./log/trickbot.log', 'a'))
#trickbot.loggers.level = :debug
#trickbot.loggers.first.level = :debug

# define SIGINT handler
Signal.trap('INT') do
  # cinch has a synchronize call in :quit but we can't make use of that inside
  # a trap context.  Spin up a thread to provide that and then immediately :join it
  Thread.new { trickbot.quit }.join
end

# define SIGTERM handler
Signal.trap('TERM') do
  # cinch has a synchronize call in :quit but we can't make use of that inside
  # a trap context.  Spin up a thread to provide that and then immediately :join it
  Thread.new { trickbot.quit }.join
end

# get lifting, bro
trickbot.start
