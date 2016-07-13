require 'cinch'

module TrickBot
  class Hello
    include Cinch::Plugin

    match /hello|hi|hey/i, method: :on_hello
    match /kicks (the bot|trickbot)/i, use_prefix: false, react_on: :action, method: :on_kick
    match /p[ea]ts (the bot|trickbot)/i, use_prefix: false, react_on: :action, method: :on_pet

    def on_hello(m)
      responses = [
        "m.reply 'BIDI BIDI BIDI'",
        "m.reply 'Hello, #{m.user.nick}'",
        "m.reply 'Hey, #{m.user.nick}'",
        "m.reply 'Howdy, #{m.user.nick}!'",
        "m.action_reply 'nods to #{m.user.nick}'",
        "m.reply 'What do you want?'",
      ]
      eval(responses.sample)
    end

    def on_kick(m)
      responses = [
        "m.reply 'BIDI BIDI BIDI'",
        "m.action_reply 'vents smoke as he whistles and chirps'",
        "m.reply '#{m.user.nick}: Ouch!'",
        "m.action_reply 'runs away wimpering.'",
        "m.action_reply 'cowers with his tail between his legs.'",
      ]
      eval(responses.sample)
    end

    def on_pet(m)
      responses = [
        "m.reply 'BIDI BIDI BIDI'",
        "m.action_reply 'merrily whistles and chirps.'",
        "m.action_reply 'wags his tail.'",
        "m.action_reply 'happily pants.'",
        "m.reply '#{m.user.nick}: Woof!'",
      ]
      eval(responses.sample)
    end
  end
end
