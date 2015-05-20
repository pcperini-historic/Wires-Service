# Imports
htmlEntities = require("html-entities").AllHtmlEntities
htmlCoder = new htmlEntities()
Twitter = require "twitter"
natural = require "natural"
tokenizer = new natural.WordTokenizer()

class Tweet
    # Class Properties
    @client = new Twitter
        consumer_key: process.env.TWITTER_CONSUMER_KEY
        consumer_secret: process.env.TWITTER_CONSUMER_SECRET
        access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY
        access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
        
    # Class Accessors
    @stream: (filterData, handler) ->
        Tweet.client.stream "statuses/filter", filterData, (stream) ->
            stream.on "data", (tweetData) ->
                handler(new Tweet tweetData)

    # Constructors
    constructor: (tweetData) ->
        # {"user": {"id_str": "12345", "name": "User Name"}, "text": "BREAKING: News", "entities": {"urls": [{"expanded_url": "http://google.com"}]}}
        @user =
            id: tweetData?.user?.id_str
            name: htmlCoder.decode(tweetData?.user?.name)
        
        @text = htmlCoder.decode(tweetData?.text)
        @sourceURL = tweetData?.entities?.urls?[-1..]?[0]?.expanded_url
        
    # Accessors
    distanceFromTweet: (comparisonTweet) ->
        unless comparisonTweet?
            return 0.0
        
        similarWords = []
        for word in tokenizer.tokenize @text
            for comparisonWord in tokenizer.tokenize comparisonTweet.text
                if natural.JaroWinklerDistance(word, comparisonWord) > 0.80 # "same" word
                    similarWords.push word
        
        return (similarWords.length / (tokenizer.tokenize @text).length)
    
    isValid: () ->
        tweetValid = @text?.length > 0
        if @user.id in process.env.TWITTER_GENERAL_ACCOUNTS.split(",") # tweet is from general account
            tweetValid = @text.toLowerCase().lastIndexOf("breaking") == 0 # and therefore must start with "BREAKING"
        
        tweetValid &= (@user.id in process.env.TWITTER_GENERAL_ACCOUNTS.split(",")) || (@user.id in process.env.TWITTER_BREAKING_ACCOUNTS.split(","))
        tweetValid &= @text.lastIndexOf("@") != 0 # doesn't start with @
        tweetValid &= @text.lastIndexOf("RT") != 0 # doesn't start with RT

        return tweetValid
    
    description: () ->
        return @user.name + " — " + (if @text.length >= 512 then @text.substring(0, 509) + "..." else @text)
        
module.exports = Tweet