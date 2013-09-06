class VisualStructure

  # Assumes artists and works arrive sorted by DOB and year of creation

  # Remember – use "antall verk correct missing works – show uncertainty"

  init:(data) ->
    @data = data
    @tracks = []

    console.info("Tally")

    console.info("Number of artists: " + @data.artists.length)
    console.info("Number of works: " + @data.works.length)

    @startYear = @data.artists[0]["FØDT"]
    @endYear = new Date().getFullYear()
    console.info("Normalizing against: #{@startYear} - #{@endYear}")

    @numberOfWorks = @data.works.length

    console.info("Allocating artist space")

    workIndex = -0.5
    @data.artists.forEach (artist)=>
      height = artist.works.length/@numberOfWorks
      x = @yearToFloat(artist["FØDT"])
      width = @yearToFloat(artist["DØD"]) - x

      artist._x = x - 0.5 - (width / 2)
      artist._y = workIndex + height/2
      artist._height = height 
      artist._width = @yearToFloat(artist["DØD"]) - x

      workIndex += height

    console.info("Done")

    @data

  yearToFloat:(year) ->
    (year - @startYear)/(@endYear - @startYear)

module.exports = new VisualStructure
