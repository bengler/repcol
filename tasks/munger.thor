#encoding: UTF-8

class Munger < Thor

  desc "munge", "Grab CSVs and output sane data while logging verbosely"
  def munge
    require './tasks/wrangler.rb'
    Wrangler.new()
  end

  desc "countImages", "Extract image counts"
  def countImages
    require 'csv'

    CSV.open("tasks/sourceData/intermediate/works_image_count.csv", 'w') do |csv|
      csv << ['id', 'imageCount']

      CSV.parse(File.read("tasks/sourceData/intermediate/works.csv"), :headers => true, :col_sep => ",").each do |row|
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

    Dir.glob("public/data/images/*").each do |file|
      m = File.basename(file).match(/(.*)_.*/)
      if m
        archive_id = m[1]
        res = `exiftags -c "#{file}" 2>/dev/null`
        match = res.match(/(Photographer: )(.*)/)
        credit = nil
        credit = match[2] unless match.nil?
        unless credit.nil?
          photographers[credit] ||= {}
          photographers[credit][:works] ||= [] 
          photographers[credit][:works] << archive_id
          print "."
        else
          print "0"
        end
      else
        print "*"
      end
    end

    i = 0
    works = {}

    photographers.each do |name, values|
      values[:id] = i
      i = i + 1

      values[:works].each do |archive_id|
        works[archive_id] = values[:id]
      end
    end

    CSV.open("app/assets/data/photographers.csv", 'w') do |csv|
      csv << ['id', 'photographer_name']
      photographers.each_pair do |k,v|
        csv << [v[:id], k]
      end
    end

    CSV.open("tasks/sourceData/intermediate/works_photographers.csv", 'w') do |csv|
      csv << ['id', 'photographer_id']
      works.each_pair do |k,v|
        csv << [k, v]
      end
    end
  end


  desc "addMetadata", "Add image count to works"
  def addMetadata
    require 'csv'

    workCounts = {}
    photographer_ids = {}

    puts "Reading image counts"

    CSV.parse(File.read("tasks/sourceData/intermediate/works_image_count.csv"), :headers => true, :col_sep => ",").each do |row|
      workCounts[row[0]] = row[1]
    end

    puts "Reading photographers"

    CSV.parse(File.read("tasks/sourceData/intermediate/works_photographers.csv"), :headers => true, :col_sep => ",").each do |row|
      photographer_ids[row[0]] = row[1]
    end

    puts "Writing!"

    CSV.open("app/assets/data/works_coded.csv", 'w') do |csv|
      csv << ['id', 'artistId', 'produced', 'acquired', 'kind', 'imageCount', 'photographer_id']

      CSV.parse(File.read("tasks/sourceData/intermediate/works.csv"), :headers => true, :col_sep => ",").each do |row|
        id = row[0]
        workCount = workCounts[id]
        photographer = photographer_ids[id] || -1
        row << workCount 
        row << photographer
        csv << row
        print "."
      end
    end
    puts "Done"
  end

end