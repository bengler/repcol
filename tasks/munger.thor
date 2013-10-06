class Munger < Thor

  desc "munge", "Grab CSVs and output sane data while logging verbosely"
  def munge
    require './tasks/wrangler.rb'
    Wrangler.new()
  end

  desc "addImages", "Add image count to works"
  def addImages
    require 'csv'

    CSV.open("app/assets/data/works_images.csv", 'w') do |csv|
      csv << ['id', 'artistId', 'produced', 'acquired', 'kind', 'imageCount']

      CSV.parse(File.read("app/assets/data/works.csv"), :headers => true, :col_sep => ",").each do |row|
        l = Dir.glob("public/data/images/#{row[0]}*.JPG").length
        csv << (row << l)
        puts (row)
      end
    end
  end

end