class VisualStructure

  # Assumes artists and works arrive sorted by DOB and year of creation

  # Remember – use "antall verk correct missing works – show uncertainty"

  init:(data) ->
    @data = data
    @tracks = []

    console.info("Tally")

    console.info("Number of artists: " + @data.artists.length)
    console.info("Number of works: " + @data.works.length)

    @startYear = @data.artists[0].dob
    @endYear = new Date().getFullYear()
    console.info("Normalizing against: #{@startYear} - #{@endYear}")

    @numberOfWorks = @data.works.length

    console.info("Allocating artist space")

    # Todo: calc 1/@numberOfWorks once!

    workHeight = 1/@numberOfWorks
    workIndex = -0.5
    @data.artists.forEach (artist)=>
      height = artist.works.length/@numberOfWorks
      x = @yearToFloat(artist.dob)
      width = @yearToFloat(artist.dod) - x 

      artist._x = x - 0.5 + (width / 2)
      artist._y = workIndex + height/2
      artist._height = height 
      artist._width = width

      artist.works.forEach (work, i)=>
        if !work.invalid
          wHeight = workHeight
          wX = @yearToFloat(work.produced)
          wWidth = @yearToFloat(work.acquired) - wX
          wY = workIndex + ((workHeight) * i)

          work._x = wX - 0.5 + (wWidth / 2)
          work._y = wY + wHeight/2
          work._height = wHeight 
          work._width = wWidth

      workIndex += height + workHeight * 30

    console.info("Done")

    @data

  yearToFloat:(year) ->
    (year - @startYear)/(@endYear - @startYear)

module.exports = new VisualStructure
