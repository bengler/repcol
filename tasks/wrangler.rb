# encoding: utf-8

class Wrangler

  # Don't read this code.

  # Drop artists labeled as "unknown"
  # Drop artists without first name or last name
  # Drop artists without date of birth

  # Shaky dating is prefixed with a minus, run an abs on them

  # Assume dod 2013 if dob > 1920
  # row[:dob] = 2013 if row[:dob] > 1920 and row[:dod].nil?

  # Use dod as key
  # Use firstname as key if we don't have dod and have lastname
  # Overwrite nil gender as this occasionally is needed

  # INTVENTARNUMMER,Fornavn kunstner,Etternavn kunstner,FØDT,DØD,FØDESTED,DØDSSTED,Koordinat fødested,Koordinat dødssted,Nasjonalitet kunstner,Kjønn kunstner,Yrke kunstner,Navn produsent,Nasjonalitet produsent,Produsent etablert,Bransje produsent,BETEGNELSE,Presisert betegnelse,EMNEORD,FARGE,Produksjonssted,Koordinat produksjonssted,Produsert fra dato,Produsert til dato,Aksesjon fra dato,Aksesjon til dato
  SOURCE_DATA_FIELDS = [:inventoryNr, :firstName, :lastName, :dob, :dod, :dobPlace, :dodPlace, :dobCoord, :dobCoord, :nationality, :gender, :vocation, :producerName, :producerNationality, :producerEstablished, :producerField, :kind, :preciseKind, :topic, :color, :productionPlace, :productionPlaceCoord, :productionStart, :productionEnd, :acquiredStart, :acquiredEnd]
  INTEGERCONVERT = [:dob, :dod, :productionStart, :productionEnd, :acquiredEnd, :acquiredStart]
  GENDERNAMES = {1 => "male", 2 => "female", 3 => "unknown"}
  require "./tasks/corrections"

  def initialize()
    require 'csv'
    @rows = []
    @works = []
    @artistDict = {}
    @prodYearFromText = {}
    @acquiredYearFromText = {}

    puts "Reading secondary dating files…"
    dateFields = [:inventoryNr,:kind,:descProdDate,:descAcqDate]
    
    def findYears s
      return nil if s.nil?
      nums =  s.scan(/\d{4}/).map(&:to_i)
      return nil if nums.empty?
      nums
    end

    CSV.parse(File.read("tasks/sourceData/dates_as_text_1_&_2.csv"), :col_sep => ",").each do |row|
      row = Hash[*dateFields.zip(row).flatten]
      prodYears = findYears(row[:descProdDate])
      acquisitionYears = findYears(row[:descAcqDate])
      # puts "#{row.inspect}, #{prodYears.inspect}, #{acquisitionYears.inspect}"
      # puts "#{prodYears.inject { |a,b| a + b } / prodYears.length}" unless prodYears.nil?
      @prodYearFromText[row[:inventoryNr]] = prodYears.inject { |a,b| a + b } / prodYears.length unless prodYears.nil?
      @acquiredYearFromText[row[:inventoryNr]] = acquisitionYears.inject { |a,b| a + b } / acquisitionYears.length unless acquisitionYears.nil?
    end
    puts "Found #{@prodYearFromText.length} production years"
    puts "Found #{@acquiredYearFromText.length} acquisition years"

    puts "Done!\n"
    wrangle()
  end

  def wrangle

    puts "Starting"

    firstRow = true

    # CSV.parse(File.read("tasks/sourceData/all_the_things_chopped.csv"), :col_sep => ",").each do |row|
    CSV.parse(File.read("tasks/sourceData/all_the_things.csv"), :col_sep => ",").each do |row|
      if firstRow
        firstRow = false
        next 
      end

      row = Hash[*SOURCE_DATA_FIELDS.zip(row).flatten]
      INTEGERCONVERT.each do |field|
        row[field] = row[field].to_i.abs unless row[field].nil?
      end

      # Some death dates are out of whack by a factor of 10
      row[:dod] = row[:dod] * 10 if !row[:dod].nil? and row[:dod] < 1000

      gender = nil
      gender = 1 if row[:gender] == "Mann"
      gender = 2 if row[:gender] == "Kvinne"
      row[:gender] = gender

      # Everyone missing death years born after 1920 assumed to be living (I know)
      if !row[:dob].nil? and row[:dob] > 1920 and row[:dod].nil?
        row[:dod] = 2013
      end

      row = correct(row)

      row = [] if !row[:dod].nil? and row[:dod] > 2013

      # Throw away unknown artists and artists with future death dates
      @rows << row unless row.empty? or row[:firstName] == "Ukjent kunstner" or row[:firstName] == "Ukjent"
    end

    # Todo – chop first line

    puts "Done reading\n"
    puts "Found works #{@rows.length()}"

    rawArtistStats()
    extractArtists()
    statsArtists()

    puts "\n\n\nStats for works…"

    rawWorkStats()

    puts "\n\n\nExtracting works…"

    extractWorks()

    puts "\nDone\n\n"

    puts "\nDumping…"
    dumpToFile()
  end

  def dumpToFile

    artistsWithoutWorks = 0
    CSV.open("app/assets/data/artists.csv", 'w') do |csv|
      csv << ['id', 'gender', 'dob', 'dod', 'firstname', 'lastname']
      @artistDict.each_pair do |k,v| 
        if v[:works].empty?
          artistsWithoutWorks += 1
        else
          csv << [v[:id], v[:gender],v[:dob],v[:dod],v[:firstName],v[:lastName]]
        end
      end
    end

    puts "Skipped #{artistsWithoutWorks} artists that didn't have works."

    worksWithoutArtists = 0

    CSV.open("app/assets/data/works.csv", 'w') do |csv|
      csv << ['id', 'artistId', 'produced', 'acquired', 'kind']
      @works.each do |v| 
        if @artistDict[v[:artistKey]].nil?
          worksWithoutArtists += 1
        else
          csv << [v[:inventoryNr],v[:artistId],v[:productionYear],v[:acquiredYear],v[:kind]]
        end
      end
    end

    puts "Skipped #{artistsWithoutWorks} works that didn't have artists."

  end

  def extractWorks
    strangeProductionDate = 0

    @rows.each do |row|
      artist = @artistDict[keyFromRow(row)]
      if artist
        work = workFromRow(row)
        work[:artistId] = artist[:id]
        work[:artistKey] = keyFromRow(row)

        if work[:productionYear] && artist[:dob]
          if work[:productionYear] < artist[:dob]
            strangeProductionDate += 1 
          end
        end

        artist[:works] << work
        @works << work

      end
    end
    puts "!!! Found #{strangeProductionDate} works with seemingly invalid production dates"
  end

  def workFromRow(row)

    inventoryNr = row[:inventoryNr]
    
    productionYear = nil
    if row[:productionStart] and row[:productionEnd]
      productionYear = (row[:productionStart] + row[:productionEnd])/2
    end 
    productionYear ||= row[:productionStart] 
    productionYear ||= row[:productionEnd]
    productionYear ||= yearFromInventoryNr(row)
    productionYear ||= @prodYearFromText[inventoryNr]

    acquiredYear = nil
    if row[:acquiredStart] and row[:acquiredEnd]
      acquiredYear = (row[:acquiredStart] + row[:acquiredEnd])/2 
    end
    acquiredYear ||= row[:acquiredStart]
    acquiredYear ||= row[:acquiredEnd]
    acquiredYear ||= @acquiredYearFromText[inventoryNr]
    {
      :inventoryNr => inventoryNr,
      :acquiredYear => acquiredYear,
      :productionYear => productionYear,
      :kind => row[:kind]
    }
  end


  def rawWorkStats

    puts "\n"
    puts "-- Work stats"
    puts "   Number of works: #{total = @rows.length()}"
    puts "\n"

    worksNotAttributedToArtist = 0
    prodStart = 0
    prodEnd = 0
    prodBoth = 0
    acqStart = 0
    acqEnd = 0
    acqBoth = 0
    everything = 0
    savedByTheInventory = 0

    prodFoundAsText = 0
    acquisitionFoundAsText = 0
    productionFoundAsText = 0
    productionFoundAsTextOverlap = 0

    @rows.each do |row|
      inventoryNr = row[:inventoryNr]

      artist = @artistDict[keyFromRow(row)]
      worksNotAttributedToArtist += 1 if artist.nil?

      prodStart += 1 if row[:productionStart].nil?
      prodEnd += 1 if row[:productionEnd].nil?
      prodBoth += 1 if row[:productionStart].nil? and row[:productionEnd].nil?
      acqStart += 1 if row[:acquiredStart].nil?
      acqEnd += 1 if row[:acquiredEnd].nil?
      acqBoth += 1 if row[:acquiredStart].nil? and row[:acquiredEnd].nil?
      everything += 1 if row[:acquiredStart].nil? and row[:acquiredEnd].nil? and row[:productionStart].nil? and row[:productionEnd].nil?

      if row[:productionStart].nil? and row[:productionEnd].nil?
        yearFromArchive = yearFromInventoryNr(row)
        if ! yearFromArchive.nil?
          savedByTheInventory += 1
          # puts "Found year #{yearFromArchive} from #{row[:inventoryNr]}"
        end
        if ! @prodYearFromText[inventoryNr].nil?
            productionFoundAsText += 1
        end
      else
        if ! @prodYearFromText[inventoryNr].nil?
          productionFoundAsTextOverlap += 1
        end
      end

      if row[:acquiredStart].nil? and row[:acquiredEnd].nil?
        if ! @acquiredYearFromText[inventoryNr].nil?
          acquisitionFoundAsText += 1
        end
      end
    end

    puts "---------"
    puts "  Works not attributed to artist: #{worksNotAttributedToArtist}"
    puts "  Missing production start: #{prodStart} and end: #{prodEnd} and both: #{prodBoth}"
    puts "  Missing production date found through inventory: #{savedByTheInventory}"
    puts "  Missing production date through text: #{productionFoundAsText}"
    puts "  Missing production date through text overlap: #{productionFoundAsTextOverlap}"
    puts "  Missing acquisition start: #{acqStart} and end: #{acqEnd} and both: #{acqBoth}"
    puts "  Missing acquisition date found through text: #{acquisitionFoundAsText}"
    puts "  Missing all dates: #{everything}"
    puts "---------"
  end

  def yearFromInventoryNr(row)
    nr = row[:inventoryNr]

    patterns = []
    # Fra og med 1950 er årstall for ervervelse innbakt i inventarnummeret på verk med denne nummerstrukturen: NG K&H.1950.0001
    patterns << (/^NG\.K&H\.(\d{4})\..+?$/)
    # Også inventarnumrene med struktur som denne ”NMK.2003.0001”, har årstall innbakt
    patterns << (/^NMK(?:\.DEP)?\.(\d{4})\..+(?:VERSO|\.\d+)?$/i)
    # Numre med følgende struktur ”MS-02014-1989” har årstallet på slutten
    patterns << (/^MS-\d+-(\d{4})(?:.+)?$/)
    # De aller fleste numrene med bokstavene ”DEP” har også et årstall for når verket ble deponert hos oss i nummeret: Eks DEP00001-1989
    patterns << (/^DEP\d+-(\d{4})$/)

    res = [*patterns].map{ |re| nr.match re }.compact.first
    unless res.nil?
      return res[1].to_i
    else
      return nil
    end
  end

  def extractArtists
    puts "\n -- Extracting artists\n"

    @id = 0
    @workCount = {}
    @artistDict = {}
    discrepencies = {}
    @rows.each do |row|
      key = keyFromRow(row)

      # Only store artists if we have a valid key
      if key
        if @artistDict[key].nil?
          print "*"
          @id += 1
          @artistDict[key] = artistFromRow(row)
          @artistDict[key][:id] = @id
          @workCount[key] = 1
        else
          oldData = @artistDict[key]
          newData = artistFromRow(row)

          @workCount[key] += 1

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

          # Print them as a diagnostic, fingerprint to only print once
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
    return nil if (row[:lastName].nil? and row[:firstName].nil?) or row[:dob].nil? or row[:dod].nil?
    name = row[:lastName] || row[:firstName]
    key = name + "_" + row[:dob].to_s

    # Use dod as key if we have it. Short out.
    if ! row[:dod].nil?
      return (key << "_#{row[:dod]}")
    end

    # Use dod use firstname in addition to lastname if we haven't already used it as key. Short out.
    if ! row[:lastName].nil? and ! row[:firstName].nil?
      return (key << "_#{row[:firstName]}")
    end

    return key
  end

  def artistFromRow(row)
    {
      :gender     => row[:gender],
      :vocation   => row[:vocation],
      :dob        => row[:dob],
      :dod        => row[:dod],
      :firstName  => row[:firstName],
      :lastName   => row[:lastName],
      :works      => []
    }
  end

  def statsArtists()
    puts "\n -- Artist stats"
    puts "   Total: #{@artistDict.length()}"

    noGender = 0
    noDod = 0
    over80 = 0

    ageBuckets = {}
    genderBuckets = {}

    @artistDict.each_pair do |k,v|
      genderVal = v[:gender]
      genderVal ||= 3

      genderBuckets[GENDERNAMES[genderVal]] ||= 0
      genderBuckets[GENDERNAMES[genderVal]] += 1

      noDod += 1 if v[:dod].nil?
      unless v[:dod].nil?
        printArtist(v, k) if (v[:dod]) > 2013
        # printArtist(v, k) if (v[:dod] - v[:dob]) > 100
        ageBuckets[(v[:dod] - v[:dob]) / 10] ||= 0
        ageBuckets[(v[:dod] - v[:dob]) / 10] += 1
      end
    end

    puts "   No gender: #{noGender}"
    puts "-- Gender distribution:"
    genderBuckets.each_pair do |k, v|
      puts "#{k} : #{v}"
    end

    puts "-- Age distribution:"
    puts "   No date of death: #{noDod}\n"
    ageBuckets.keys.sort.each do |year|
      puts "#{year * 10} : #{ageBuckets[year]}"
    end

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

  def printArtist(a, key)
    puts("'#{a[:dob]}' -> '#{a[:dod]}' | '#{a[:firstName]}' '#{a[:lastName]}' #{a[:gender]}, #{key}, ##{@workCount[key]}")
  end

end