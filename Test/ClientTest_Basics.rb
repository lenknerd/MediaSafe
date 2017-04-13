#!/usr/bin/env ruby

# ClientTest_Basics.rb
# Tests pertaining to modules in MediaSafeClient.rb
#
# David Lenkner, 2017

require '../Client/MediaSafeClient.rb'

puts 'Trying checksum on this rb file.'
thisfile = './' + File.basename(__FILE__)
md5s1 = MediaSafe.getMD5(thisfile)
puts 'Got result;'
puts md5s1

puts 'Lets try getting info on "./" path;'
res1 = MediaSafe.getFileInfo('./')
print res1
puts "\n"


puts 'Now trying to get info on whole directory.'
res2 = MediaSafe.getFileInfo(`pwd`.strip)
print res2
puts "\n"
