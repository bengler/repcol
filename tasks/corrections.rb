# encoding: utf-8

DICT = [
        {:key => {:lastName => "Mansfeld", :dob => 1739, :dod => 1736}, :cor => {:dob => 1738, :dod => 1796}},
        {:key => {:lastName => "Tallberg", :dob => 1960, :dod => 1928}, :cor => {:dob => 1738, :dod => 1796}},
        {:key => {:lastName => "Weirotter", :dob => 1730, :dod => 2017}, :cor => {:dob => 1733, :dod => 1771}},
        {:key => {:firstName => "Carl", :dob => 1803, :dod => 2018}, :cor => {:dob => 1807, :dod => 1843}},
        {:key => {:lastName => "Ehrenreich", :dob => 1739, :dod => 2017}, :cor => {:dod => 1806}},
        {:key => {:lastName => "Rose", :dob => 1936, :dod => 2016}, :cor => {:dod => 2002}}
       ]

def check_untouchables(row)
  UNTOUCHABLES.each do |key|
    match = true
    pattern[:key].each_pair do |k,v|
      match = false if v != row[k]
    end
    return true if match
  end
  return false
end


def correct(row)
  DICT.each do |pattern|
    match = true
      pattern[:key].each_pair do |k,v|
        match = false if v != row[k]
      end
    if match
      # puts "!!! CORRECTED"
      row = row.merge(pattern[:cor])
      # puts row.inspect
      break
    end
  end
  return row
end

# '1779' -> '2018' | 'Carl Heinrich' 'Rahl' 1, Rahl_1779_2018, #3
# '1714' -> '2017' | 'Johann Gottfried' 'Thelott' 1, Thelott_1714_2017, #2
#! '1730' -> '2017' | 'Franz Edmund' 'Weirotter' 1, Weirotter_1730_2017, #34
#! '1803' -> '2018' | 'Carl' 'Küchler' 1, Küchler_1803_2018, #9
# '1751' -> '2018' | 'Gotthelf Wilhelm' 'Weise' 1, Weise_1751_2018, #3
# '1751' -> '2018' | 'Stephan Baron von' 'Stengel' 1, Stengel_1751_2018, #1
# '1635' -> '2016' | 'Aegedius van' 'Schendel' 1, Schendel_1635_2016, #1
# '1788' -> '2018' | 'Carl C. Vogel von' 'Vogelstein' 1, Vogelstein_1788_2018, #1
# '1737' -> '2018' | 'Johann Friedrich' 'Steinkope' 1, Steinkope_1737_2018, #1
#! '1739' -> '2017' | 'Johann Benjamin' 'Ehrenreich' 1, Ehrenreich_1739_2017, #5

# '1750' -> '2017' | 'Cornelis' 'Brouwer' 1, Brouwer_1750_2017, #1
# '1789' -> '2018' | 'Hendrik Josef Franciscus van der' 'Poorten' 1, Poorten_1789_2018, #1
#! '1778' -> '2018' | 'Heinrich Theodor' 'Wehle' 1, Wehle_1778_2018, #2
# '1612' -> '2016' | 'Hendrick' 'Snyers' 1, Snyers_1612_2016, #1
#! '1669' -> '1776' | 'Nicolas Charles de' 'Silvestre' 1, Silvestre_1669_1776, #2
# '1736' -> '1844' | 'Karl Frederik' 'Bendorp' 1, Bendorp_1736_1844, #1
#! '1802' -> '2018' | 'Moritz Edwin' 'Klug' 1, Klug_1802_2018, #2
# '1877' -> '1979' | 'Sigrid' 'Schauman' 2, Schauman_1877_1979, #1
# '1863' -> '1965' | 'Agnes' 'Steineger' 2, Steineger_1863_1965, #1
# '1876' -> '1978' | 'Jacques' 'Loutchansky' 1, Loutchansky_1876_1978, #1
#! '1898' -> '1999' | 'Jean' 'Osouf' 1, Osouf_1898_1999, #4

