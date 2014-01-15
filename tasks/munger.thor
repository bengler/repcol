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