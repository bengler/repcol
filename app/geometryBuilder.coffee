class GeometryBuilder

  constructor: ->
    @artistGeometry = new THREE.CubeGeometry( 1, 1, 1)
    @workGeometry = new THREE.PlaneGeometry( 1, 40)


    @scaleX = 400
    @scaleY = 40

  selectedArtistMesh:(artist) ->
    selectedArtistMaterial = new THREE.MeshLambertMaterial({
      opacity: 0.70
      wireframe: false
      transparent:true
    })

    @artistMesh(artist, selectedArtistMaterial, 1.50)

  artistMesh:(artist, texture, multiplier = 0) ->
    mesh = new THREE.Mesh(@artistGeometry, texture)
    mesh.position.set(artist._x * @scaleX, artist._y * @scaleY, 0)
    mesh.scale.x = (artist._width * @scaleX) + (artist._height * multiplier)
    mesh.scale.y = (artist._height * @scaleY) + (artist._height * multiplier) 
    mesh.scale.z = (1 + artist._height * @scaleY * 10) + (artist._height * multiplier)

    # mesh.rotation.x = Math.sin(artist._y * 3)
    # mesh.rotation.z = Math.cos(artist._y * 3 )

    mesh

  build:(scene, data) ->
    @scene = scene
    @data = data

    # Undef, Men, Women
    @collatedArtistGeometries = [new THREE.Geometry(), new THREE.Geometry(), new THREE.Geometry()]
    @collatedWorkGeometry = new THREE.Geometry()

    @data.artists.forEach (artist)=>
      mesh = @artistMesh(artist)

      for face in mesh.geometry.faces
        face.color.r = artist.id

      THREE.GeometryUtils.merge(@collatedArtistGeometries[artist.gender], mesh)


      artist.works.forEach (work)=>
        if !work.invalid
          v1 = new THREE.Vector3()
          v1.set((work._x - work._width/2) * @scaleX, work._y * @scaleY, (mesh.scale.z / 2) + 1)
          v2 = new THREE.Vector3()
          v2.set((work._x + work._width/2) * @scaleX, work._y * @scaleY, (mesh.scale.z / 2) + 1)

          @collatedWorkGeometry.vertices.push(v1)
          @collatedWorkGeometry.vertices.push(v2)


    materialProperties = {}

    # Mark focus faces 
    # HACK: there _has got_ to be a better way of doing this
    currentArtist = 0
    offset = 0
    for geometry, gender in @collatedArtistGeometries
      for face in geometry.faces
        artist = face.color.r
        # n+1
        if offset == 0
          @data.artistsKeyed[artist].focusFace = face
        offset += 1
        if currentArtist != artist
          offset = 0
          currentArtist = artist
          @data.artistsKeyed[artist].faces = []

        @data.artistsKeyed[artist].faces.push(face)

    # Color meshes
    for geometry, gender in @collatedArtistGeometries
      switch gender
        when 0 then materialProperties.color = "#346"
        when 1 then materialProperties.color = "#3058c0"
        when 2 then materialProperties.color = "#ff7060"

      mesh = new THREE.Mesh( geometry, new THREE.MeshLambertMaterial(materialProperties) );
      mesh.material.ambient = mesh.material.color
      mesh.material.shinyness = 1

      mesh.castShadow = true;
      mesh.receiveShadow = true;
      
      @scene.add(mesh);

    lineMaterial = new THREE.LineBasicMaterial(
      color: 0xffffff
      opacity: 0.01
      blending: THREE.AdditiveBlending
      linewidth: 0.1
    )

    line = new THREE.Line(@collatedWorkGeometry, lineMaterial, THREE.LinePieces)
    @scene.add(line)


  yearToFloat:(year) ->
    (year - @startYear)/@endYear

module.exports = new GeometryBuilder
