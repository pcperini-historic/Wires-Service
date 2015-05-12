# Imports
Device = require "./models/device"
Headline = require "./models/headline"
PushService = require "./models/pushService"
express = require "express"
bodyParser = require "body-parser"

# Setup
app = new express
app.set "port", (process.env.PORT || 5000)
app.use bodyParser.json()
app.use bodyParser.urlencoded({extended: true})
app.use express.static "./views/resources"

app.lastHeadline = null

# Routes
app.get "/", (req, resp) ->
    resp.sendfile "./views/beta.html"
    
app.post "/", (req, resp) ->
    # {"token": "8badf00d"}
    if !PushService.validToken(req.body.token)
        resp.send 401
        return

    dev = new Device req.body.token
    dev.save()
    
    resp.send "Token received"
    
app.get "/headline", (req, resp) ->
    resp.send JSON.stringify(app.lastHeadline)
    
app.post "/headline", (req, resp) ->
    # {"key": "keeey", "headline": {"text": "BREAKING: News", "sourceURL": "http://google.com"}}
    if req.body.key != process.env.INT_KEY
        resp.send 401
        return
        
    app.lastHeadline = new Headline req.body.headline.text, req.body.headline.sourceURL
    resp.send "Headline received"

# Main
app.listen app.get("port"), () ->
    console.log "Wires is running at localhost: " + app.get "port"