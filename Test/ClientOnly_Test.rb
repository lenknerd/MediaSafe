# ClientOnly_Test.rb
# Minitest tests pertaining to modules in MediaSafeClient.rb and a few shared ones
#
# David Lenkner, 2017

require 'minitest/autorun'


class TestMFileAction < Minitest::Test
	def test_strs
		vals = [
			MFileAction.str('UNDECIDED'),
			MFileAction.str('SENT_KEPT'),
			MFileAction.str('SENT_DELD'),
			MFileAction.str('SKIP_KEPT'),
			MFileAction.str('SKIP_DELD'),
			MFileAction.str('akjkj2b4tjjbetk')
		]
		assert_equal vals, [0,1,2,3,4,5]
	end
end






puts 'Lets try getting info on "./Test/TestDataFolder" path;'
res1 = MediaSafe.getFileInfo('./Test/TestDataFolder')
print res1
puts "\n"

puts 'Now test my MFile Status enum class...'

