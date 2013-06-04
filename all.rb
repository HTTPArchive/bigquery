
dates = %w[
Nov_15_2010
Nov_29_2010
Dec_16_2010
Dec_28_2010
Jan_20_2011
Jan_31_2011
Feb_11_2011
Feb_26_2011
Mar_15_2011
Mar_29_2011
Apr_15_2011
Apr_30_2011
]

mob = %w[
May_16_2011
Jun_1_2011
Jun_15_2011
Jul_1_2011
Jul_15_2011
Aug_1_2011
Aug_15_2011
Sep_1_2011
Sep_15_2011
Oct_1_2011
Oct_15_2011
Nov_1_2011
Nov_15_2011
Dec_1_2011
Dec_15_2011

Jan_1_2012
Jan_15_2012
Feb_1_2012
Feb_15_2012
Mar_1_2012
Mar_15_2012
Apr_1_2012
Apr_15_2012
May_1_2012
May_15_2012
Jun_1_2012
Jun_15_2012
Jul_1_2012
Jul_15_2012
Aug_1_2012
Aug_15_2012
Sep_1_2012
Sep_15_2012
Oct_1_2012
Oct_15_2012
Nov_1_2012
Nov_15_2012
Dec_1_2012
Dec_15_2012

Jan_1_2013
Jan_15_2013
Feb_1_2013
Feb_15_2013
Mar_1_2013
Mar_15_2013
Apr_1_2013
Apr_15_2013
May_1_2013
May_15_2013
]

require 'pp'

def run(f)
  system("sh sync.sh #{f}")
  puts "-"*50
end

dates.each do |d|
  run(d)
end

mob.each do |d|
  run(d)
  run("mobile_#{d}")
end

puts "Finished"
