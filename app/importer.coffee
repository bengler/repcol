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


  constructor: ->
    @data =
      artistsKeyed: {}

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
          else
            missing += 1

        console.info("Missing artists for #{missing} works")

        @data.works = rows
        console.info(@data.artists[1])

        @dataLoaded.resolve(@data)

    @dataLoaded = $.Deferred()

module.exports = new Importer
