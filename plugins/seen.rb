require 'cinch'

module TrickBot
  class Seen
    class SeenStruct < Struct.new(:who, :where, :what, :time)
      def to_s
        "[#{time.asctime}] #{who} was seen in #{where} saying #{what}"
      end
    end

    include Cinch::Plugin

    listen_to :channel

    match /seen (.+)/, method: :seen
    match /^(l[ou]l)?wh?[au]t/i, use_prefix: false, method: :what

    def initialize(*args)
      super
      @users = {}
      @last = "huh?"
    end

    def listen(m)
      return if m.message =~ /^(l[ou]l)?wh?[au]t/i
      @users[m.user.nick] = SeenStruct.new(m.user, m.channel, m.message, Time.now)
      @last = m.message
    end

    def seen(m, nick)
      if nick == @bot.nick
        m.reply "That's me!"
      elsif nick == m.user.nick
        m.reply "That's you!"
      elsif @users.key?(nick)
        m.reply @users[nick].to_s
      else
        m.reply "I haven't seen #{nick}"
      end
    end

    def what(m, nick)
      m.reply @last.upcase
      @last = m.message
    end
  end
end
