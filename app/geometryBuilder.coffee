class GeometryBuilder

  constructor: ->
    @artistGeometry = new THREE.CubeGeometry( 1, 1, 1)
    @workGeometry = new THREE.PlaneGeometry( 1, 40)

    @scaleX = 100
    @scaleY = 40

  artistMesh:(artist, texture, multiplier = 1, adder = 0) ->
    mesh = new THREE.Mesh(@artistGeometry, texture)
    mesh.position.set(artist._x * @scaleX, artist._y * @scaleY, 0)
    mesh.scale.x = (artist._width * @scaleX) * multiplier
    mesh.scale.y = (artist._height * @scaleY) * multiplier
    mesh.scale.z = (1 + artist._height * @scaleY * 10) * multiplier

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
          workMesh = new THREE.Mesh(@workGeometry)
          workMesh.position.set(work._x * @scaleX, work._y * @scaleY, (mesh.scale.z / 2) + 0.1 )
          workMesh.scale.x = work._width * @scaleX
          workMesh.scale.y = work._height * @scaleY * 0.1
          THREE.GeometryUtils.merge(@collatedWorkGeometry, workMesh)

    materialProperties = 
      depthTest: true
      wireframe: false
      # emissive: "#eee"

    # HACK: there has got to be a better way of doing this

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
        when 1 then materialProperties.color = "#6068ff"
        when 2 then materialProperties.color = "#ff7060"

      mesh = new THREE.Mesh( geometry, new THREE.MeshLambertMaterial(materialProperties) );
      mesh.material.ambient = mesh.material.color
      mesh.material.shinyness = 1

      mesh.castShadow = true;
      mesh.receiveShadow = true;
      
      @scene.add(mesh);

    workMaterial = new THREE.MeshLambertMaterial({
      depthTest: true
      opacity: 0.30
      emissive: "#eee"
      wireframe: false
      transparent:true
    })

    mesh = new THREE.Mesh(@collatedWorkGeometry, workMaterial);
    @scene.add(mesh)


  yearToFloat:(year) ->
    (year - @startYear)/@endYear

module.exports = new GeometryBuilder
