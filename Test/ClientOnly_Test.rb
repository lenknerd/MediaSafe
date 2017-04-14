# ClientOnly_Test.rb
# Minitest tests pertaining to modules in MediaSafeClient.rb and a few shared ones
#
# David Lenkner, 2017

require 'minitest/autorun'



puts 'Trying checksum on a test file.'
md5s1 = MediaSafe.getMD5('./Test/TestDataFolder/TestFile.txt')
puts 'Got result;'
puts md5s1

puts 'Lets try getting info on "./Test/TestDataFolder" path;'
res1 = MediaSafe.getFileInfo('./Test/TestDataFolder')
print res1
puts "\n"

puts 'Now test my MFile Status enum class...'
a1 = MFileStatus.str('UNKNOWN')
puts a1
a2 = MFileStatus.str('CONFLICT')
puts a2
