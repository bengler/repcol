class GeometryBuilder

  build:(scene, data) ->
    @scene = scene
    @data = data

    scaleX = 60
    scaleY = 40

    geometry = new THREE.CubeGeometry( 1, 1, 0.5)
    workGeometry = new THREE.CubeGeometry( 1, 1, 4)

    # properties = 
    #   depthTest: true
    #   color: #ff0000
    #   opacity: 0.35
    #   wireframe: false
    #   blending: THREE.AdditiveAlphaBlending
    #   transparent:true

    properties = {}

    workMaterial = new THREE.MeshLambertMaterial()
    undefMaterial = new THREE.MeshLambertMaterial(properties.color)
    manMaterial = new THREE.MeshLambertMaterial(properties)
    womanMaterial = new THREE.MeshLambertMaterial(properties)


    WorkMaterial = new THREE.MeshLambertMaterial({
      side: THREE.DoubleSide,
      transparent: true,
    })

    material = undefined

    @data.artists.forEach (artist)=>

      # Men
      if artist.gender == 1
        material = undefMaterial
      # Women 
      else if artist.gender == 2
        material = womanMaterial
      # Undef
      else if artist.gender == 0
        material = manMaterial

      mesh = new THREE.Mesh( geometry, material )
      mesh.position.set(artist._x * scaleX, artist._y * scaleY, 0)
      mesh.scale.x = artist._width * scaleX
      mesh.scale.y = artist._height * scaleY
      @scene.add( mesh )

      artist.works.forEach (work)=>
        if !work.invalid
          mesh = new THREE.Mesh( workGeometry, workMaterial )
          mesh.position.set(work._x * scaleX, work._y * scaleY, 0)
          mesh.scale.x = work._width * scaleX
          mesh.scale.y = work._height * scaleY
          @scene.add( mesh )

    @data.artists = @data.artists[0..20]


  yearToFloat:(year) ->
    (year - @startYear)/@endYear

module.exports = new GeometryBuilder
