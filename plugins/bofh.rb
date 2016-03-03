require 'cinch'
require 'httparty'

module TrickBot
  class BofhExcuse
    include Cinch::Plugin

    BOFH_URI = "http://pages.cs.wisc.edu/~ballard/bofh/excuses"

    BOFH_REGEX = /.*(excuse|bofh).*/

    match BOFH_REGEX, method: :bofh

    def excuses
      return @excuses if @excuses
      response = HTTParty.get BOFH_URI
      excuses_raw = response.parsed_response.split("\n")
      @excuses = Hash[excuses_raw.each_index.zip(excuses_raw)]
    end

    def bofh(m)
      excuse_no = excuses.keys.sample
      m.reply "#{m.user.nick}: BOFH Excuse ##{excuse_no}: #{excuses[excuse_no]}"
    end
  end
end
