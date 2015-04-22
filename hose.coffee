# Imports
Device = require "./models/device"
Headline = require "./models/headline"
Twitter = require "twitter"
throng = require "throng"
htmlEntities = require("html-entities").AllHtmlEntities

# Setup
htmlCoder = new htmlEntities()
client = new Twitter
    consumer_key: process.env.TWITTER_CONSUMER_KEY
    consumer_secret: process.env.TWITTER_CONSUMER_SECRET
    access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY
    access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
    
# Main
start = () ->
    client.stream "statuses/filter", {follow: process.env.TWITTER_BREAKING_ACCOUNTS + "," + process.env.TWITTER_GENERAL_ACCOUNTS}, (stream) ->
        stream.on "data", (tweet) ->
            sendTweet(tweet)

throng start,
    workers: 1
    lifetime: Infinity
    
# Tweet Handlers
validTweet = (tweet) ->
    tweetValid = true
    
    if tweet.user.id_str in process.env.TWITTER_GENERAL_ACCOUNTS.split(",") # tweet is from general account
        tweetValid = tweet.text.toLowerCase().startsWith("breaking") # and therefore must start with "BREAKING"
    else if !tweet.user.id_str in process.env.TWITTER_BREAKING_ACCOUNTS.split(",") # tweet isn't in either accounts list
        tweetValid = false

    return tweetValid

sendTweet = (tweet) ->
    if validTweet(tweet)
        text = tweet.user.name + " — " + (if tweet.text.length >= 64 then tweet.text.substring(0, 61) + "..." else tweet.text)
        text = htmlCoder.decode(text)
        sourceURL = tweet.entities.urls[0]?.expanded_url
    
        headline = new Headline text, sourceURL
        console.log "Sending " + headline.text
        
        Device.all (devices) ->
            for device in devices
                device.push Headline.notificationType, headline.text, headline.sourceURL