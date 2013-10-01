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

    WIDTH = window.innerWidth || 2;
    HEIGHT = window.innerHeight || ( 2 + 2 * MARGIN );

    MARGIN = 0
    SCREEN_WIDTH = WIDTH
    SCREEN_HEIGHT = HEIGHT - 2 * MARGIN

    FAR = 10000

    @camera = new THREE.PerspectiveCamera(35, SCREEN_WIDTH / SCREEN_HEIGHT, 2, FAR)
    @camera.position.set(140,85,150)
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

    # @scene.fog = new THREE.FogExp2 0xcccccc, 0.001103

    # geometry = new THREE.CubeGeometry( 1, 1, 1 )
    # material = new THREE.MeshLambertMaterial( { color: 0xFF0000 } )
    # mesh = new THREE.Mesh( geometry, material )
    # @scene.add( mesh )

    # light = new THREE.PointLight( 0xFFFFFF )
    # light.position.set( 0, 0, 40 )
    # @scene.add( light )

    @scene.add( new THREE.AmbientLight( 0x808080 ) )

    light = new THREE.SpotLight( 0xffffff, 1.5 )
    light.position.set( 50, 150, 0 )
    light.castShadow = true

    light.shadowCameraNear = 100
    light.shadowCameraFar = @camera.far
    light.shadowCameraFov = 100

    light.shadowBias = -0.00122
    light.shadowDarkness = 0.3

    light.shadowMapWidth = 4096
    light.shadowMapHeight = 4096
    @scene.add(light)



    light = new THREE.SpotLight( 0xffffff, 0.7 )
    light.position.set( 50, 150, 100 )
    light.castShadow = false

    light.shadowCameraNear = 100
    light.shadowCameraFar = @camera.far
    light.shadowCameraFov = 100

    light.shadowBias = -0.00122
    light.shadowDarkness = 0.3

    light.shadowMapWidth = 4096
    light.shadowMapHeight = 4096
    @scene.add(light)


    @renderer = new THREE.WebGLRenderer({ antialias: true})
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.setClearColor(new THREE.Color(0xD0D0D8))

    @renderer.shadowMapEnabled = true;
    @renderer.shadowMapType = THREE.PCFShadowMap;
    @renderer.sortObjects = false;
    
    # @renderer.autoClear = false;

    # renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false }
    # @renderTarget = new THREE.WebGLRenderTarget( SCREEN_WIDTH, SCREEN_HEIGHT, renderTargetParameters )

    # effectFXAA = new THREE.ShaderPass( THREE.FXAAShader )
    # effectVignette = new THREE.ShaderPass( THREE.VignetteShader )

    # hblur = new THREE.ShaderPass( THREE.HorizontalTiltShiftShader )
    # vblur = new THREE.ShaderPass( THREE.VerticalTiltShiftShader )

    # bluriness = 4

    # hblur.uniforms[ 'h' ].value = bluriness / SCREEN_WIDTH
    # vblur.uniforms[ 'v' ].value = bluriness / SCREEN_HEIGHT

    # hblur.uniforms[ 'r' ].value = vblur.uniforms[ 'r' ].value = 0.5

    # effectFXAA.uniforms[ 'resolution' ].value.set( 1 / SCREEN_WIDTH, 1 / SCREEN_HEIGHT )

    # composer = new THREE.EffectComposer( @renderer, renderTarget )

    # renderModel = new THREE.RenderPass( @scene, @camera )

    # effectVignette.renderToScreen = true
    # vblur.renderToScreen = true
    # effectFXAA.renderToScreen = true

    # composer = new THREE.EffectComposer( @renderer, @renderTarget )

    # composer.addPass( renderModel )

    # composer.addPass( effectFXAA )

    # composer.addPass( hblur );
    # composer.addPass( vblur );
    # composer.addPass( effectVignette );



    container = document.createElement('div')
    document.body.appendChild(container)
    container.appendChild(@renderer.domElement)

    if SHOW_STATS
      @stats = new Stats()
      @stats.domElement.style.position = 'absolute'
      @stats.domElement.style.top = '0px'
      @stats.domElement.style.left = '0px'
      container.appendChild(@stats.domElement)        

    @mouse = new THREE.Vector2()
    @projector = new THREE.Projector()
    @animate()

    document.onclick = @click

  click:(event) =>

    @mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1
    @mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1

    vector = new THREE.Vector3(@mouse.x, @mouse.y, 0.5)
    @projector.unprojectVector(vector, @camera)
    ray = new THREE.Ray(@camera.position, vector.sub(@camera.position ).normalize())

    console.info("hello")


  animate: ->
    @render()
    @stats.update() if SHOW_STATS
    requestAnimationFrame(=> @animate()) unless @stopped
    @controls.update();

  render: ->

    @renderer.render(@scene, @camera)

module.exports = new SceneKeeper
