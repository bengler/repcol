@Hipster ?= {}
Hipster.Routers ?= {}
Hipster.Views ?= {}
Hipster.Models ?= {}
Hipster.Collections ?= {}

$ ->
    # Load App Helpers
    require '../lib/app_helpers'
    importer = require './importer'
    sceneKeeper = require './sceneKeeper'

    # Initialize App
    Hipster.Views.AppView = new AppView = require 'views/app_view'

    # Initialize Backbone History
    Backbone.history.start pushState: yes

    console.info("Importing")

    data = importer.load().then (data)->
      console.info("Done loading. Firing scene.")
      sceneKeeper.init(data)



