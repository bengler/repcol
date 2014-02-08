class Importer

  constructor: ->
    @data =
      artistsKeyed: {}
      works: []



  # Loads relations between educations and occupations. 
  # Returns a promise which is resolved upon completion.

  load: () ->

    artistsLoaded = $.Deferred()
    photographers = ["Morten Thorkildsen","Børre Høstland","Jeanette Veiby","Frode Larsen","Anne Hansteen Jarre","Dag A. Ivarsøy","Therese Husby","Dag Andre Ivarsøy","Jacques Lathion","Børre Høstland","Andreas Harvik","Ukjent","Stein Jorgensen","Øyvind Andersen","Jaques Lathion","Ole Henrik Storeheier","Dag A, Ivarsøy","Anne Hansteen","Ukjent","Scanned by Dag A. Ivarsøy","Børre Høstland/ Andreas Harvik","Annar Bjørgli","Angela Musil-Jantjes","Ukjent","Stein Jørgensen","Knut Øystein Nerdrum","Børre Høstland", "Knut Øystein Nerdrum"]

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
      d3.csv "data/works_coded.csv", (err, rows)=>
        rows.forEach (row) =>
          row.artistId = +row.artistId
          row.produced = +row.produced
          row.acquired = +row.acquired
          row.invalid = (row.produced == 0 or row.acquired == 0)

          if row.photographer_id != "-1"
            row.photographer = photographers[row.photographer_id] + " / Nasjonalmuseet"
          else
            row.photographer = "Nasjonalmuseet"

          # Need this for GLagered == row.acquired)

          value = @data.artistsKeyed[row["artistId"]]

          if value?
            @data.artistsKeyed[row["artistId"]].works.push(row)
            @data.works.push(row)

        # Clean and sort
        @data.artists = _.sortBy @data.artists, (artist)->
          artist.dob

        @data.artists.forEach (artist, i) =>
          artist.index = i

        @data.artists.forEach (artist)->
          artist.works = _.sortBy artist.works, (work)-> 
            work.produced

        @dataLoaded.resolve(@data)

    @dataLoaded = $.Deferred()

module.exports = new Importer
