require 'cinch'

module TrickBot
  class Hello
    include Cinch::Plugin

    match /hello/, method: :on_hello
    match /kicks (the bot|trickbot)/, use_prefix: false, react_on: :action, method: :on_kick
    match /p[ea]ts (the bot|trickbot)/, use_prefix: false, react_on: :action, method: :on_pet

    def on_hello(m)
      m.reply "Hello, #{m.user.nick}"
    end

    def on_kick(m)
      m.reply "#{m.user.nick}: Ouch!"
    end

    def on_pet(m)
      responses = [
        "m.action_reply 'wags his tail.'",
        "m.action_reply 'happily pants.'",
        "m.reply '#{m.user.nick}: Woof!'",
      ]
      eval(responses.sample)
    end
  end
end
