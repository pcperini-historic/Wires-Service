# Imports
Device = require "./models/device"
Headline = require "./models/headline"
Twitter = require "twitter"
throng = require "throng"
htmlEntities = require("html-entities").AllHtmlEntities

# Setup
htmlCoder = new htmlEntities()
client = new Twitter
    consumer_key: process.env.consumerKey
    consumer_secret: process.env.consumerSecret
    access_token_key: process.env.accessTokenKey
    access_token_secret: process.env.accessTokenSecret
    
# Main
start = () ->
    client.stream "statuses/filter", {follow: process.env.breakingAccounts + "," + process.env.generalAccounts}, (stream) ->
        stream.on "data", (tweet) ->
            sendTweet(tweet)

throng start,
    workers: 1
    lifetime: Infinity
    
# Tweet Handlers
sendTweet = (tweet) ->
    validTweet = true
    if tweet.user.id_str in process.env.generalAccounts.split(",") # tweet is from general account
        validTweet = tweet.text.toLowerCase().startsWith("breaking") # and therefore must start with "BREAKING"

    if validTweet
        text = tweet.user.name + " — " + (if tweet.text.length >= 64 then tweet.text.substring(0, 61) + "..." else tweet.text)
        text = htmlCoder.decode(text)
        sourceURL = tweet.entities.urls[0]?.expanded_url
    
        headline = new Headline text, sourceURL
        console.log "Sending " + headline.text
        
        Device.all (devices) ->
            for device in devices
                device.push Headline.notificationType, headline.text, headline.sourceURL