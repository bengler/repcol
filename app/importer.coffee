class Importer

  constructor: ->
    @data =
      artistsKeyed: {}
      works: []

  # Loads relations between educations and occupations. 
  # Returns a promise which is resolved upon completion.

  load: () ->
    artistsLoaded = $.Deferred()

    d3.csv "data/artists.csv", (err, rows) =>
      rows.forEach (row) =>
        row.works = []
        row.id = +row.id
        row.gender = +row.gender
        row.dob = +row.dob
        row.dod = +row.dod
        @data.artistsKeyed[row.id] = row

        # Erronous death dates – lifespan == 0
        row.dod += 1 if (row.dob == row.dod)

      @data.artists = rows

      artistsLoaded.resolve()

    artistsLoaded.then ()=> 
      d3.csv "data/works.csv", (err, rows)=>
        missing = 0
        rows.forEach (row) =>
          row.artistId = +row.artistId
          row.produced = +row.produced
          row.acquired = +row.acquired
          row.invalid = (row.produced == 0 or row.acquired == 0)

          # Need this for GL
          row.acquired += 1 if (row.produced == row.acquired)

          value = @data.artistsKeyed[row["artistId"]]

          if value?
            @data.artistsKeyed[row["artistId"]].works.push(row)
            @data.works.push(row)
          else
            missing += 1
            console.info row

        console.info("Missing artists for #{missing} works!")

        # Clean and sort
        @data.artists = _.sortBy @data.artists, (artist)->
          artist.dob

        @data.artists.forEach (artist)->
          artist.works = _.sortBy artist.works, (work)-> 
            work.produced

        @dataLoaded.resolve(@data)

    @dataLoaded = $.Deferred()

module.exports = new Importer
