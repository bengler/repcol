class GeometryBuilder

  build:(scene, data) ->
    @scene = scene
    @data = data

    scaleX = 100
    scaleY = 40

    # Undef, Men, Women
    @collatedArtistGeometries = [new THREE.Geometry(), new THREE.Geometry(), new THREE.Geometry()]
    @collatedWorkGeometry = new THREE.Geometry()

    artistGeometry = new THREE.CubeGeometry( 1, 1, 1)
    workGeometry = new THREE.PlaneGeometry( 1, 40)

    @data.artists.forEach (artist)=>

      mesh = new THREE.Mesh(artistGeometry)
      mesh.position.set(artist._x * scaleX, artist._y * scaleY, 0)
      mesh.scale.x = artist._width * scaleX
      mesh.scale.y = artist._height * scaleY
      mesh.scale.z = 1 + artist._height * scaleY * 10

      #@scene.add(mesh)
      THREE.GeometryUtils.merge(@collatedArtistGeometries[artist.gender], mesh)

      artist.works.forEach (work)=>
        if !work.invalid
          workMesh = new THREE.Mesh(workGeometry)
          workMesh.position.set(work._x * scaleX, work._y * scaleY, (mesh.scale.z / 2) + 0.1 )
          workMesh.scale.x = work._width * scaleX
          workMesh.scale.y = work._height * scaleY/10
          THREE.GeometryUtils.merge(@collatedWorkGeometry, workMesh)

    materialProperties = 
      depthTest: true
      wireframe: false
      # emissive: "#eee"

    for geometry, gender in @collatedArtistGeometries
      switch gender
        # when 0 then materialProperties.color = "#999"
        # when 1 then materialProperties.color = "#0000a0"
        # when 2 then materialProperties.color = "#a00000"
        when 0 then materialProperties.color = "#999"
        when 1 then materialProperties.color = "#6060a0"
        when 2 then materialProperties.color = "#a06060"


      mesh = new THREE.Mesh( geometry, new THREE.MeshLambertMaterial(materialProperties) );
      mesh.material.ambient = mesh.material.color
      mesh.material.shinyness = 1

      mesh.castShadow = true;
      mesh.receiveShadow = true;
      
      @scene.add(mesh);

    workMaterial = new THREE.MeshLambertMaterial({
      depthTest: true
      opacity: 0.80
      emissive: "#fff"
      wireframe: false
      transparent:true
    })

    mesh = new THREE.Mesh(@collatedWorkGeometry, workMaterial);
    @scene.add(mesh)


  yearToFloat:(year) ->
    (year - @startYear)/@endYear

module.exports = new GeometryBuilder
