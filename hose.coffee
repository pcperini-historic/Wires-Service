# Imports
Device = require "./models/device"
Headline = require "./models/headline"
PushService = require "./models/pushService"
Twitter = require "twitter"
throng = require "throng"
htmlEntities = require("html-entities").AllHtmlEntities
request = require "request"

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
    unless tweet?.user?.id_str?
        return false

    tweetValid = true
    if tweet.user.id_str in process.env.TWITTER_GENERAL_ACCOUNTS.split(",") # tweet is from general account
        tweetValid = tweet.text.toLowerCase().lastIndexOf("breaking") == 0 # and therefore must start with "BREAKING"
    
    tweetValid &= (tweet.user.id_str in process.env.TWITTER_GENERAL_ACCOUNTS.split(",")) || (tweet.user.id_str in process.env.TWITTER_BREAKING_ACCOUNTS.split(","))
    tweetValid &= tweet.text.lastIndexOf("@") != 0 # doesn't start with @
    
    return tweetValid

sendTweet = (tweet) ->
    if validTweet(tweet)
        text = tweet.user.name + " — " + (if tweet.text.length >= 100 then tweet.text.substring(0, 97) + "..." else tweet.text)
        text = htmlCoder.decode(text)
        sourceURL = tweet.entities.urls[-1..]?.expanded_url
    
        headline = new Headline text, sourceURL
        console.log "Sending " + headline.text
        
        # send to app
        request.post process.env.INT_URL + "/headline", {form: {
            key: process.env.INT_KEY,
            headline: {
                text: headline.text,
                sourceURL: headline.sourceURL
            }
        }}
        
        # push to clients
        Device.all (devices) ->
            PushService.push Headline.notificationType, headline.text, headline.sourceURL, devices
