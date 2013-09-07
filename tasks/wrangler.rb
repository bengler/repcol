class Wrangler

  # Don't read this code.

  # Drop artists labeled as "unknown"
  # Drop artists without first name or last name
  # Drop artists without date of birth

  # Assume dod 2013 if dob > 1920
  # row[:dob] = 2013 if row[:dob] > 1920 and row[:dod].nil?

  # Use dod as key
  # Use firstname as key if we don't have dod and have lastname
  # Overwrite nil gender as this occasionally is needed

  # INTVENTARNUMMER,Fornavn kunstner,Etternavn kunstner,FØDT,DØD,FØDESTED,DØDSSTED,Koordinat fødested,Koordinat dødssted,Nasjonalitet kunstner,Kjønn kunstner,Yrke kunstner,Navn produsent,Nasjonalitet produsent,Produsent etablert,Bransje produsent,BETEGNELSE,Presisert betegnelse,EMNEORD,FARGE,Produksjonssted,Koordinat produksjonssted,Produsert fra dato,Produsert til dato,Aksesjon fra dato,Aksesjon til dato
  SOURCE_DATA_FIELDS = [:inventoryNr, :firstName, :lastName, :dob, :dod, :dobPlace, :dodPlace, :dobCoord, :dobCoord, :nationality, :gender, :vocation, :producerName, :producerNationality, :producerEstablished, :producerField, :kind, :preciseKind, :topic, :color, :productionPlace, :productionPlaceCoord, :productionStart, :productionEnd, :acquiredStart, :acquiredEnd]
  INTEGERCONVERT = [:dob, :dod]

  def initialize()
    @rows = []
    wrangle()
  end

  def wrangle
    require 'csv'

    puts "Starting"

#    CSV.parse(File.read("tasks/sourceData/all_the_things_chopped.csv"), :col_sep => ",").each do |row|
    CSV.parse(File.read("tasks/sourceData/all_the_things.csv"), :col_sep => ",").each do |row|
      row = Hash[*SOURCE_DATA_FIELDS.zip(row).flatten]
      INTEGERCONVERT.each do |field|
        row[field] = row[field].to_i unless row[field].nil?
      end
      @rows << row unless row[:firstName] == "Ukjent kunstner" or row[:firstName] == "Ukjent"
    end

    # Todo – chop first line

    puts "Done reading\n"
    puts "Found works #{@rows.length()}"

    rawArtistStats()
    extractArtists()
    statsArtists()

    # artists = extractArtists(rows)

    puts "\nDone\n\n"

  end

  # Use artist
  def extractArtists
    puts "\n -- Extracting artists\n"

    @artistDict = {}
    discrepencies = {}
    @rows.each do |row|
      key = keyFromRow(row)

      # Check stuff that doesn't generate valid keys
      # if key.nil?
      #   puts row.inspect
      # end

      # Only store artists if we have a valid key
      if key
        if @artistDict[key].nil?
          print "*"
          @artistDict[key] = artistFromRow(row)
        else
          oldData = @artistDict[key]
          newData = artistFromRow(row)
          has_discrepencies = false

          # Overwrite nil values for gender in stored data
          if oldData[:gender].nil? and !newData[:gender].nil?
            oldData[:gender] = newData[:gender]
          end

          # Check if we have out of whack values
          newData.each_pair do |k,v|
            if oldData[k] != v
              has_discrepencies = true
            end
          end

          # Print them as a diagnostic, fingerprint only print once
          if has_discrepencies
            s = ""
            newData.each_pair do |k,v|
              if oldData[k] != v
                s << "#{k}: #{oldData[k]} -> #{v}\n"
              else
                s << "#{k}: #{oldData[k]}\n"
              end
            end

            if discrepencies[s].nil?
              discrepencies[s] = true
              puts "\n\nDiscrepency:"
              puts s
            end
            puts "----\n"
          end
        end
      end
    end

  end

  def keyFromRow(row)
    return nil if (row[:lastName].nil? and row[:firstName].nil?) or row[:dob].nil?
    name = row[:lastName] || row[:firstName]
    key = name + "_" + row[:dob].to_s

    # Use dod as key if we have it. Short it.
    if ! row[:dod].nil?
      return (key << "_#{row[:dod]}")
    end 

    # Use dod use firstname in addition to lastname if we haven't already used it as key. Short it.
    if ! row[:lastName].nil? and ! row[:firstName].nil?
      return (key << "_#{row[:firstName]}")
    end

    return key
  end

  def artistFromRow(row)
    gender = nil
    gender = 1 if row[:gender] == "Mann"
    gender = 2 if row[:gender] == "Kvinne"

    # Whatever.
    if row[:dob] > 1920 and row[:dod].nil?
      row[:dod] = 2013
      print "!"
    end

    return {
      :gender     => gender,
      :dob        => row[:dob],
      :dod        => row[:dod],
      :firstName  => row[:firstName],
      :lastName   => row[:lastName]
    }

  end

  def statsArtists()
    puts "\n -- Artist stats"
    puts "#{@artistDict.length()}"
    puts "\n"
  end


  def extractWorks


  end


  def workStats(works)
    puts "\n -- Work stats"
    puts "#{@works.length()}"

    puts "\n"
  end

  def rawArtistStats
    missingOnlyArtistLastName = 0
    missingOnlyArtistDob = 0
    missingBoth = 0
    missingOne = 0
    hasArtistDod = 0
    hasArtistDobbutnotDod = 0
    hasArtistDobbutnotDodTwenty = 0
    hasFirstNameNotLastName = 0

    @rows.each do |row|
      # Missing data sums
      missingOnlyArtistLastName += 1 if row[:lastName].nil? and !row[:dob].nil?
      missingOnlyArtistDob += 1 if row[:dob].nil? and ! row[:lastName].nil?
      missingBoth += 1 if row[:lastName].nil? and row[:dob].nil?
      missingOne += 1 if row[:lastName].nil? or row[:dob].nil?

      # More checks
      hasArtistDod += 1 if row[:dob].nil? and !row[:dod].nil?
      hasArtistDobbutnotDod += 1 if ! row[:dob].nil? and row[:dod].nil?
      hasArtistDobbutnotDodTwenty += 1 if ! row[:dob].nil? and row[:dod].nil? and row[:dob] > 1930
      hasFirstNameNotLastName += 1 if ! row[:firstName].nil? and row[:lastName].nil?

    end

    puts "\n\nSome stats on keys:"
    puts "- Works without artist dob: #{missingOnlyArtistDob}"
    puts "- Works without artist artist lastname: #{missingOnlyArtistLastName}"
    puts "- Works with neither: #{missingBoth}"
    puts "- Works with one: #{missingOne}"

    puts "- Works without with dates of death but birth: #{hasArtistDobbutnotDod}!"
    puts "- Works with with dates of birth but not death born after 1930: #{hasArtistDobbutnotDodTwenty}!"
    puts "- Works with with dates of birth but not death: #{hasArtistDod}!"
    puts "- Works without with lastnames but with firstnames: #{hasFirstNameNotLastName}!"
    puts "\nAh, 'Rembrandt van Rijn'\n"

  end

end