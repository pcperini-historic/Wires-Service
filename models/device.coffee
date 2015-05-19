# Imports
sheets = require "google-spreadsheet"

class Device
    # Class Properties
    @options =
        sheet:
            username: process.env.GOOGLE_USERNAME
            password: process.env.GOOGLE_PASSWORD
        
    @sheet = new sheets process.env.GOOGLE_SHEET_KEY

    # Class Accessors
    @all: (callback) ->
        @authSheet () ->
            Device.sheet.getRows 1, (error, rows) ->
                callback((new Device row.title for row in rows))
                
    @authSheet: (callback) ->
        @sheet.setAuth @options.sheet.username, @options.sheet.password, () ->
            callback()

    # Constructors
    constructor: (@token) ->
        # apply properties
    
    # Mutators
    save: () ->
        self = this
        Device.all (devices) -> # check for existance
            unless self.token in (device.token for device in devices)
                Device.authSheet () -> # otherwise, add new
                    Device.sheet.addRow 1, {token: self.token}
                    
    delete: () ->
        self = this
        Device.authSheet () ->
            Device.sheet.getRows 1, (error, rows) ->
                equalRows = (row for row in rows when row.title == self.token) # filter by equality
                for row in equalRows
                    row.del() # delete
        
module.exports = Device