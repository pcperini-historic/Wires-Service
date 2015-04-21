apns = require "apns"
sheets = require "google-spreadsheet"

class Device
    # Class Properties
    @options =
        dev:
            keyFile: "keys/dev_key.pem"
            certFile: "keys/dev_cert.pem"
            gateway: "gateway.sandbox.push.apple.com"
            debug: true
            
        prod:
            keyFile: "keys/prod_key.pem"
            certFile: "keys/prod_cert.pem"
            gateway: "gateway.push.apple.com"
            debug: false
        
        inDev: true
        
        sheet:
            username: "pcperini@gmail.com"
            password: "tweph^erd(ugs?urc;ek&an?bond:at/lod@hal(ni)wu=twoj"
        
    @sheet = new sheets "1rYe1gD2L8nWxr5wU0MVWZs2ZBq6cCU4bIciMMhQY0rY"

    # Class Accessors
    @all: (callback) ->
        @authSheet () ->
            Device.sheet.getRows 1, (error, rows) ->
                callback((new Device row.title for row in rows))
                
    @authSheet: (callback) ->
        @sheet.setAuth @options.sheet.username, @options.sheet.password, () ->
            callback()
            
    @validToken: (token) ->
        return token.match(/^[A-Fa-f0-9]{64}$/)?

    # Constructors
    constructor: (@token) ->
    
    # Mutators
    save: () ->
        self = this
        Device.all (devices) -> # check for existance
            unless self.token in (device.token for device in devices)
                Device.authSheet () -> # otherwise, add new
                    Device.sheet.addRow 1, {token: self.token}
    
    # Push Handlers
    push: (type, text, sourceURL) ->
        notification = new apns.Notification
        notification.device = new apns.Device(@token)
        
        notification.alert = text
        notification.payload =
            notificationType: type
            sourceURL: sourceURL
            
        options = if Device.options.inDev then Device.options.dev else Device.options.prod
        options.errorCallback = @pushError
        
        connection = connection = new apns.Connection(options)
        connection.sendNotification(notification)
        
    pushError: (errNum, notification) ->
        console.log "error: " + errNum
        
module.exports = Device