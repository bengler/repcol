class GeometryBuilder

  build:(scene, data) ->
    @scene = scene
    @data = data

    scaleX = 60
    scaleY = 20

    geometry = new THREE.CubeGeometry( 1, 1, 1)
    material = new THREE.MeshLambertMaterial( { color: 0xFF0000 } )

    @data.artists.forEach (artist)=>

      material = new THREE.MeshLambertMaterial()
        material.color.setRGB(Math.random(), 0, 0)

      mesh = new THREE.Mesh( geometry, material )
      mesh.position.set(artist._x * scaleX, artist._y * scaleY, 0)
      mesh.scale.x = artist._width * scaleX
      mesh.scale.y = artist._height * scaleY
      @scene.add( mesh )


  yearToFloat:(year) ->
    (year - @startYear)/@endYear

module.exports = new GeometryBuilder
