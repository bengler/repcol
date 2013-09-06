class SceneKeeper
  visualStructure = require './visualStructure'

  SHOW_STATS = true

  constructor: ->
    # if not Detector.webgl
    #   $("#error").show()
    #   $("#main").hide()

  init:(data) ->
    visualStructure.init(data)
    @initScene()

  initScene: ->

    container = document.createElement('div')
    document.body.appendChild(container)

    @camera = new THREE.Camera(60, window.innerWidth / window.innerHeight, 2000, 1000000)

    @camera.useTarget = true

    @cameraDistance = 0
    @cameraRotation = 0
    @cameraHeight = 1.0016

    @scene = new THREE.Scene
    # @scene.fog = new THREE.FogExp2 0xcccccc, 0.000003

    # light = new THREE.PointLight(0xffffff, 1, 1000000)
    # light.position = @camera.position
    # @scene.addObject(light)

    @renderer = new THREE.WebGLRenderer()
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(new THREE.Color(0xFFFFFF))
    container.appendChild(@renderer.domElement)

    if SHOW_STATS
      @stats = new Stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '0px'
      @stats.domElement.style.left = '0px'
      container.appendChild(@stats.domElement)        

    @animate()

  animate: ->
    @render()
    @stats.update() if SHOW_STATS
    requestAnimationFrame(=> @animate()) unless @stopped


  render: ->

    @renderer.render(@scene, @camera)



module.exports = new SceneKeeper
