# App Namespace
# Change `Hipster` to your app's name
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
    packHierarchy = require './pack_hierarchy'

    # Initialize App
    Hipster.Views.AppView = new AppView = require 'views/app_view'

    # Initialize Backbone History
    Backbone.history.start pushState: yes

    console.info("Importing")

    data = importer.load().then (data)->
      console.info("Done loading. Firing scene.")
      sceneKeeper.init(data)

      # new packHierarchy(data.nestedJobs, class: "jobs")
      # new packHierarchy(data.nestedEds, offset: 5, class: "eds")


