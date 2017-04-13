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



puts 
