class Munger < Thor

  desc "munge", "Grab CSVs and output sane data while logging verbosely"
  def munge
    require './tasks/wrangler.rb'
    Wrangler.new()
  end


end