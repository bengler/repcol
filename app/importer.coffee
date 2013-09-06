class Importer

  # Todo:

  # Trenger tall på:
  #   Hvor mange av verkene trenger og har fått prod dato og ervervelses dato 
  #   Hvor mange av verkene/kunstnerne vi kaster fordi vi ikke har gode data på de (og på grunn av hvilke data)

  # Finner:
  #   Beskrivende datering: "-1957" <- gotte be wrong

  # Vi har 7820 verk uten kunstnere?

  #   This:
  #     if (!record.readColumn("Avledet datering")) return false;
  #   needs to read something like:
  #     if (!record.readColumn("Avledet datering") || !record.readColumn("Produsert fra dato") || !!record.readColumn("Produsert til dato")) return false;
  #   or perhaps collapse ranges and values and mark source in data.

  # Missing artists for 8117 works app.js:115
  # Object
  #  app.js:117
  # Done loading. Firing scene. app.js:168
  # Tally app.js:638
  # Number of artists: 2681 app.js:639
  # Number of works: 29991 app.js:640
  # THREE.WebGLRenderer 59dev 

  # Kjønn?
  # Rejecter vi de uten dødsdato? Huh?

  constructor: ->
    @data =
      artistsKeyed: {}
      works: []

  # Loads relations between educations and occupations. 
  # Returns a promise which is resolved upon completion.

  load: () ->
    artistsLoaded = $.Deferred()

    d3.csv "data/filtered_artists.csv", (err, rows) =>
      rows.forEach (row) =>
        row.works = []
        @data.artistsKeyed[row["KunstnerNøkkel"]] = row

      @data.artists = rows

      artistsLoaded.resolve()

    artistsLoaded.then ()=> 
      d3.csv "data/filtered_artwork.csv", (err, rows)=>
        missing = 0
        rows.forEach (row) =>
          value = @data.artistsKeyed[row["KunstnerNøkkel"]]
          if value?
            @data.artistsKeyed[row["KunstnerNøkkel"]].works.push(row)
            @data.works.push(row)
          else
            missing += 1

        console.info("Missing artists for #{missing} works!")

        # Checking for artists without works
        artists_before_filtering = @data.artists.length
        @data.artists = @data.artists.filter (artist)=>
          filter = artist.works.length != 0
          if !filter
            delete @data.artistsKeyed[artist["KunstnerNøkkel"]];
          filter

        console.info("Removed #{artists_before_filtering - @data.artists.length} out of #{artists_before_filtering} of artists as they didn't have works")

        @data.artists = _.sortBy @data.artists, (artist)->
          artist["FØDT"]

        @data.artists.forEach (artist)->
          _.sortBy artist.works, (work)-> 
            work["Avledet datering"]

        console.info(@data.artists[1])
        console.info(@data.works[1])

        @dataLoaded.resolve(@data)

    @dataLoaded = $.Deferred()

module.exports = new Importer
