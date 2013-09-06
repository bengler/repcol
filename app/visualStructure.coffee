class VisualStructure

  init:(data) ->
    @data = data

    console.info("Tally")
    console.info("Number of artists: " + @data.artists.length)
    console.info("Number of works: " + @data.works.length)


module.exports = new VisualStructure
