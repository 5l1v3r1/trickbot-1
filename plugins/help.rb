require 'cinch'

module TrickBot
  class Help
    include Cinch::Plugin

    match /help/i

    def execute(m)
      m.user.notice "Hello, #{m.user.nick}. I'm #{m.bot.config.nick}.  I do the following:"
      m.user.notice "- respond to people that say hello, e.g. \"trickbot: hello\""
      m.user.notice "- resolve titles for URLs posted to channels that point to an HTML document."
      m.user.notice "- resolve titles for YouTube URLs posted to channels."
      m.user.notice "- search wikipedia for you, e.g. \"trickbot: wiki IRC Bot\""
      m.user.notice "- search urban dictionary for you, e.g. \"trickbot: urban urban dictionary\""
      m.user.notice "- generate a BOFH excuse, e.g. \"trickbot: bofh\" or \"trickbot: excuse\""
      m.user.notice "INSTALLED PLUGINS: #{m.bot.config.plugins.plugins.join(", ")}"
    end
  end
end
