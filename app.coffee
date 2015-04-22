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

# Routes
app.get "/", (req, resp) ->
    resp.send "Wires is listening for breaking news headlines."
    
app.post "/", (req, resp) ->
    if !PushService.validToken(req.body.token)
        resp.send 401
        return

    dev = new Device req.body.token
    dev.save()
    
    resp.send "Token received"

# Main
app.listen app.get("port"), () ->
    console.log "Wires is running at localhost: " + app.get "port"