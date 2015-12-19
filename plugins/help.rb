require 'cinch'

module TrickBot
  class Help
    include Cinch::Plugin

    match /help/

    def execute(m)
      m.reply "Hello, #{m.user.nick}. I'm #{m.bot.config.nick}.  I do the following:"
      m.reply "- respond to people that say hello, e.g. \"trickbot: hello\""
      m.reply "- resolve titles for URLs posted to channels that point to an HTML document."
      m.reply "- resolve titles for YouTube URLs posted to channels."
      m.reply "INSTALLED PLUGINS: #{m.bot.config.plugins.plugins.join(", ")}"
    end
  end
end
