#!/usr/bin/env ruby

require 'json'
require 'rubygems'
require 'chatterbot/dsl'

# Enabling **debug_mode** prevents the bot from actually sending
# tweets. Keep this active while you are developing your bot. Once you
# are ready to send out tweets, you can remove this line.
# debug_mode

# Chatterbot will keep track of the most recent tweets your bot has
# handled so you don't need to worry about that yourself. While
# testing, you can use the **no_update** directive to prevent
# chatterbot from updating those values. This directive can also be
# handy if you are doing something advanced where you want to track
# which tweet you saw last on your own.
no_update

# remove this to get less output when running your bot
verbose

# # # # # # # #
# SCRIPT VARS #
# # # # # # # #

# the data to use for tweet creation
@data = {}

# the notation for string expansion or pruning
# \w indicates any char, num, or _
# TODO allow escaping '<', '>', and '#' chars
@expand_notation = /#(\w*?)#/
@prune_notation  = /<(.*?)>/

@tweet_max_len = 140

# TODO how likely something extra will be pruned
# @prune_chance = 0.1 # 10%

# # # # # #
# METHODS #
# # # # # #

#
# Determine if the bot should run, then run
#
def start
  case Time.now.hour
  when 8..10  # 8am-10am
    @data = JSON.parse( IO.read 'arrival.json' )
  when 10..20 # 10am-8pm
    @data = JSON.parse( IO.read 'visitor.json' )
  when 20..22 # 8pm-10pm
    @data = JSON.parse( IO.read 'departure.json' )
  else
    snooze = true
  end
  # @data = JSON.parse( IO.read 'arrival.json' )
  # @data = JSON.parse( IO.read 'visitor.json' )
  # @data = JSON.parse( IO.read 'departure.json' )

  if !snooze then tweet generate end
  # (1..10).each do tweet generate; puts "\n\n" end
end


#
# Generate a tweet
#
def generate
  # pick a root
  root = @data["roots"].sample

  # expand the root
  expanded = expand root, @data

  # the naive 'final' string
  fin = expanded.delete('<>')

  # prune the pre-naive-final string
  fin = prune expanded, @tweet_max_len

  # if pruning was ineffective, regenerate
  if fin.size > @tweet_max_len
    fin = arrival
  end

  fin
end

#
# Expand a template string from provided date
#
def expand( str, data )

  out = str.dup

  # if the string provided has anything to expand...
  if out.match? @expand_notation

    # iterating on the original string (so we do not modify the string while
    # reading it), for each of the expansion variables......
    str.scan( @expand_notation ) do |match|
      match = match[0] # v is returned as an array of one element

      # replace expansion notations with a random
      # element from that notation's attribute
      out.sub! "##{match}#", data["#{match}"].sample # TODO account for non-existent symbols
    end

    # recurse on the expanded string for further expansion
    # (this will return the same thing if nothing is to be done)
    out = expand out, data

  end

  out

end

#
# Prune a string down to specified length using pruning notation
#
def prune( str, max )
  out = str.dup

  # keep pruning so long as the string is prunable and the length is over maximum
  while out.match? @prune_notation and out.delete( '<>' ).size > max
    # what parts of the string can be pruned?
    matches = out.scan( @prune_notation ).map { |match| match[0] }
    # pick a random nth one of these
    idx = rand( matches.size )
    # init at -1 so we can increment at the beginning of the iteration
    i = -1
    # iterate over each match, but only delete the nth match
    out.gsub!( @prune_notation ) do |match|
      i += 1
      if i != idx then match else '' end
    end
  end

  out.delete( '<>' )
end

# # # # #
# START #
# # # # #

start

# # # #
# END #
# # # #

#############################
# TODO For future reference #
#############################

# Here's a list of words to exclude from searches. Use this list to
# add words which your bot should ignore for whatever reason.
# exclude "hi", "spammer", "junk" # TODO

# Exclude a list of offensive, vulgar, 'bad' words. This list is
# populated from Darius Kazemi's wordfilter module
# @see https://github.com/dariusk/wordfilter
# exclude bad_words # TODO

# This will restrict your bot to tweets that come from accounts that
# are following your bot. A tweet from an account that isn't following
# will be rejected
# only_interact_with_followers # TODO

#
# interesting methods that could be used for interactions?
#

#search "chatterbot" do |tweet|
#  # here's the content of a tweet
#  puts tweets.text
#end

#
# this block responds to mentions of your bot
#
#replies do |tweet|
#  # Any time you put the #USER# token in a tweet, Chatterbot will
#  # replace it with the handle of the user you are interacting with
#  reply "Yes #USER#, you are very kind to say that!", tweet
#end

#
# this block handles incoming Direct Messages. if you want to do
# something with DMs, go for it!
#
# direct_messages do |dm|
#  puts "DM received: #{dm.text}"
#  direct_message "HELLO, I GOT YOUR MESSAGE", dm.sender
# end
