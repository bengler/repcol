class SceneKeeper
  visualStructure = require './visualStructure'
  geometryBuilder = require './geometryBuilder'

  SHOW_STATS = true

  constructor: ->
    # if not Detector.webgl
    #   $("#error").show()
    #   $("#main").hide()

  init:(data) ->
    @data = visualStructure.init(data)
    @initScene()
    geometryBuilder.build(@scene, @data)

  initScene: ->

    @scene = new THREE.Scene

    @camera = new THREE.PerspectiveCamera(35, window.innerWidth / window.innerHeight, 0.1, 10000)
    @camera.position.set(0,0,-90)
    @camera.lookAt(@scene.position);

    @controls = new THREE.TrackballControls(@camera)
    @controls.rotateSpeed = 1.0
    @controls.zoomSpeed = 1.2
    @controls.panSpeed = 0.8
    @controls.noZoom = false
    @controls.noPan = false
    @controls.staticMoving = true
    @controls.dynamicDampingFactor = 0.3
    @controls.keys = [ 65, 83, 68 ]

    @scene.fog = new THREE.FogExp2 0xcccccc, 0.001103

    geometry = new THREE.CubeGeometry( 1, 1, 1 )
    material = new THREE.MeshLambertMaterial( { color: 0xFF0000 } )
    mesh = new THREE.Mesh( geometry, material )
    @scene.add( mesh )

    light = new THREE.PointLight( 0xFFFF00 )
    light.position.set( 10, 6, 15 )
    @scene.add( light )

    @renderer = new THREE.WebGLRenderer({ antialias: true})
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(new THREE.Color(0xFFFFFF))
    container = document.createElement('div')
    document.body.appendChild(container)
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
    @controls.update();

  render: ->

    @renderer.render(@scene, @camera)

module.exports = new SceneKeeper
