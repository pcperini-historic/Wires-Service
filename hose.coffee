# Imports
Device = require "./models/device"
Headline = require "./models/headline"
PushService = require "./models/pushService"
Tweet = require "./models/tweet"
throng = require "throng"
request = require "request"
    
# Main
start = () ->
    Tweet.stream {follow: process.env.TWITTER_BREAKING_ACCOUNTS + "," + process.env.TWITTER_GENERAL_ACCOUNTS}, (tweet) ->
        sendHeadline(tweet)

throng start,
    workers: 1
    lifetime: Infinity
    
# Headline Handlers
sendHeadline = (tweet) ->
    if tweet.isValid()
        headline = new Headline tweet.text, tweet.sourceURL
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