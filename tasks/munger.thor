class Munger < Thor

  desc "munge", "Grab CSVs and output sane data while logging verbosely"
  def munge
    require './tasks/wrangler.rb'
    Wrangler.new()
  end

  desc "countImages", "Extract image counts"
  def countImages
    require 'csv'

    CSV.open("tasks/sourceData/works_image_count.csv", 'w') do |csv|
      csv << ['id', 'imageCount']

      CSV.parse(File.read("app/assets/data/works.csv"), :headers => true, :col_sep => ",").each do |row|
        l = Dir.glob("public/data/images/#{row[0]}*.JPG").length
        csv << [row[0], l]
        print "."
      end
    end
  end


  desc "findPhotographers", "Find photographers"
  def findPhotographers
    require 'csv'

    photographers = {}
    works = {}

    CSV.parse(File.read("app/assets/data/works.csv"), :headers => true, :col_sep => ",").each do |row|
      id = row[0]
      files = Dir.glob("public/data/images/#{id}*.JPG")
      local_photogs = {}
      files.each do |f|
        # puts f
        begin
        res = `exiftags -c "#{f}" 2>/dev/null`
        rescue
          puts "No exif data"
        end
        # puts res.inspect
        match = res.match(/(Photographer: )(.*)/)
        credit = nil
        credit = match[2] unless match.nil?
        unless credit.nil?
          local_photogs[credit] = 0
          photographers[credit] ||= []
          photographers[credit] << id
        end

        if local_photogs.length > 1
          puts local_photogs
        end

      end

      # csv << [row[0], l]
      print "."
    end
  end


  desc "addImages", "Add image count to works"
  def addImages
    require 'csv'

    workCounts = {}

    CSV.parse(File.read("tasks/sourceData/works_image_count.csv"), :headers => true, :col_sep => ",").each do |row|
      workCounts[row[0]] = row[1]
    end

    CSV.open("app/assets/data/works_images.csv", 'w') do |csv|
      csv << ['id', 'artistId', 'produced', 'acquired', 'kind', 'imageCount']

      CSV.parse(File.read("app/assets/data/works.csv"), :headers => true, :col_sep => ",").each do |row|
        # l = Dir.glob("public/data/images/#{row[0]}*.JPG").length
        csv << (row << workCounts[row[0]])
      end
    end
  end

end