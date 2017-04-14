# SharedOnly_Test.rb
# Test functions for shared utilities on both client and server
# Does not require either of those to be running, only this
#
# David Lenkner, 2017

require 'minitest/autorun'


# Just tests the enum for various backed-up-ness statuses possible
class TestMFileStatus < Minitest::Test
	def setup
		@strvals = [
			'UNKNOWN',
			'NOT_PRESENT',
			'CONFLICT',
			'SAFE',
			' 2oi3tygod$$ fhgb'
		]
		@intvals = [0,1,2,3,4]
	end

	def test_strs
		int_vals_calculated = @strvals.map { |x| MFileStatus.fr_str(x) }
		assert_equal int_vals_calculated, @intvals
	end

	def test_ints
		str_vals_calculated = @intvals.map { |x| MFileStatus.to_str(x) }
		assert_equal str_vals_calculated, @strvals[0..-2] + ['UNDEFINED']
	end

end

# Bulk of testing here - all the shared utilities
class TestMediaSafeSharedUtils < Minitest::Test
	def test_md5sum
		filesToCheck = [
		   './Test/TestDataFolder/TestFile.txt',
		   './Test/TestDataFolder/AnotherTestFile.xyz'
		]
		knownSums = [
			'17467d85d61f5d4523fd1785680f32ef',
			'47ba5e3bc41c710bd25fc01be1a18e21'
		]
		sumsFound = filesToCheck.map { |f|
			MediaSafe.getMD5(f)
		}
		assert_equal knownSums, sumsFound
	end

end 
