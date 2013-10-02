class SceneKeeper
  visualStructure = require './visualStructure'
  geometryBuilder = require './geometryBuilder'

  SHOW_STATS = true

  constructor: ->
    # if not Detector.webgl
    #   $("#error").show()
    #   $("#main").hide()

  init:(data) ->
    @data = data
    visualStructure.init(data)
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

    @camera = new THREE.PerspectiveCamera(35, SCREEN_WIDTH / SCREEN_HEIGHT, 0.1, FAR)
    @camera.position.set(140,85,150)
    @camera.lookAt(@scene.position);

    @controls = new THREE.TrackballControls(@camera)
    @controls.rotateSpeed = 1.0
    @controls.zoomSpeed = 1.2
    @controls.panSpeed = 0.8
    @controls.noZoom = false
    @controls.noPan = false
    @controls.staticMoving = false
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

    light = new THREE.SpotLight( 0xffffff, 1.0 )
    light.position.set( 50, 150, 0 )
    light.castShadow = true

    light.shadowCameraNear = 100
    light.shadowCameraFar = @camera.far
    light.shadowCameraFov = 100

    light.shadowBias = -0.00122
    light.shadowDarkness = 0.1

    light.shadowMapWidth = 4096
    light.shadowMapHeight = 4096
    @scene.add(light)


    light = new THREE.SpotLight( 0xffffff, 0.6 )
    light.position.set( 50, 150, 100 )
    # light.castShadow = false

    # light.shadowCameraNear = 100
    # light.shadowCameraFar = @camera.far
    # light.shadowCameraFov = 100

    # light.shadowBias = -0.00122
    # light.shadowDarkness = 0.8

    # light.shadowMapWidth = 4096
    # light.shadowMapHeight = 4096
    @scene.add(light)

    @renderer = new THREE.WebGLRenderer({ antialias: true})
    @renderer.setSize(SCREEN_WIDTH, SCREEN_HEIGHT)
    @renderer.setClearColor(new THREE.Color(0xD0D0D8))

    @renderer.shadowMapEnabled = true;
    @renderer.shadowMapType = THREE.PCFShadowMap;
    @renderer.sortObjects = false;
    
    # Composer

    # @renderer.autoClear = false;

    renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false }
    @renderTarget = new THREE.WebGLRenderTarget( SCREEN_WIDTH * 2, SCREEN_HEIGHT * 2, renderTargetParameters )

    # effectFXAA = new THREE.ShaderPass( THREE.FXAAShader )
    # effectFXAA.uniforms[ 'resolution' ].value.set( 1 / SCREEN_WIDTH / 2, 1 / SCREEN_HEIGHT / 2 )

    effectVignette = new THREE.ShaderPass( THREE.VignetteShader )
    effectVignette.uniforms[ 'darkness' ].value = 0.4

    hblur = new THREE.ShaderPass( THREE.HorizontalTiltShiftShader )
    vblur = new THREE.ShaderPass( THREE.VerticalTiltShiftShader )
    bluriness = 2
    hblur.uniforms[ 'h' ].value = bluriness / SCREEN_WIDTH
    vblur.uniforms[ 'v' ].value = bluriness / SCREEN_HEIGHT
    hblur.uniforms[ 'r' ].value = vblur.uniforms[ 'r' ].value = 0.5

    @composer = new THREE.EffectComposer( @renderer, @renderTarget )
    renderModel = new THREE.RenderPass( @scene, @camera )

    @composer.addPass(renderModel)
    @composer.addPass(effectVignette);
    @composer.addPass(hblur);
    @composer.addPass(vblur);
    # @composer.addPass(effectFXAA)
    vblur.renderToScreen = true;

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

    #window.addEventListener( 'resize', @resize, false );
    window.addEventListener( 'dblclick', @click, false );
    window.addEventListener( 'mousemove', @mousemove, false );

    @currentArtist = undefined

  click:(event) =>
    res = @findArtist(event)

    if ! res?
      if @currentArtist
        @currentArtist = undefined
        $(".container h2").removeClass("selected")
  
        vec = new THREE.Vector3();
        vec.subVectors( @camera.position, @controls.target);
        vec.setLength(vec.length() * 1.5);
        @camera.position.addVectors(vec,@controls.target);
        @camera.updateProjectionMatrix();

    else
      $(".container h2").addClass("selected")
      @currentArtist = res.artist
      @updateArtistName(@currentArtist)
      COG = res.artist.focusFace.centroid
      v = new THREE.Vector3();
      v.subVectors(COG,@controls.target);
      @controls.target.set(COG.x,COG.y,COG.z);  

      sphereSize = 1 + res.artist._height * 160
      distToCenter = sphereSize/Math.sin( Math.PI / 180.0 * @camera.fov * 0.5);
      target = @controls.target
      vec = new THREE.Vector3();
      vec.subVectors( @camera.position, target );
      vec.setLength( distToCenter );
      @camera.position.addVectors(  vec , target );
      @camera.updateProjectionMatrix();

  findArtist:(event) ->
    @mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1
    @mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1
    vector = new THREE.Vector3(@mouse.x, @mouse.y, 0.5)
    @projector.unprojectVector(vector, @camera)
    ray = new THREE.Raycaster(@camera.position, vector.sub(@camera.position ).normalize())
    intersects = ray.intersectObjects(@scene.children)

    if intersects.length > 0
      face = intersects[0].face
      artist = @data.artistsKeyed[face.color.r]
      res =
        object: intersects[0]
        artist: artist
        face:   face 
      return res
    return undefined

  mousemove:(event) =>
    return if @currentArtist?
    res = @findArtist(event)
    return unless res?
    @updateArtistName(res.artist)

  updateArtistName:(artist) =>
    $('.container h2').text(artist.firstname + " " + artist.lastname)
    dod = if artist.dod == 2013 then "" else artist.dod
    $('.container p').text(artist.dob + " - " + dod)


  animate: ->
    @render()
    @stats.update() if SHOW_STATS
    requestAnimationFrame(=> @animate()) unless @stopped
    @controls.update();

  render: ->

    @composer.render()

module.exports = new SceneKeeper
