TrickBot - The IRC Informational Butler
=======================================

Description
-----------

TrickBot is an IRC Infobot written using the [Cinch](https://github.com/cinchrb/cinch) IRC bot framework.

Features
--------

TrickBot currently performs the following functions:

* Responds to users saying hello, e.g. "trickbot: hello."
* Resolves titles for HTML URLs posted to channels he lurks.
* Resolves titles for YouTube URLs posted to channels he lurks.

Installation
------------

Installation is simple.  Follow these simple steps:

* Clone this repository
* Install ruby, cinch, nokogiri, and RMagick through your platform's package manager or
through the Ruby gem utility.
* Edit trickbot.rb to adjust the following:
  * Edit your connection info, i.e. server, username, nick, channels
  * Edit your plugin prefix (defaults to /^trickbot: /)
  * Add your Google Developer API Key to the YouTube plugin configuration

Contribute
----------

Do you like TrickBot?  Do you like Ruby?  Do you like to help?  If you think
that TrickBot can be improved and you know how to do it, you can.

Please fork this project, implement the change in its own branch, send a
pull request, and we'll happily review your changes!
