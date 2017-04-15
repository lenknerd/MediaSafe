# ClientOnly_Test.rb
# Minitest tests pertaining to modules in MediaSafeClient.rb and a few shared ones
#
# David Lenkner, 2017

require 'minitest/autorun'


# Just tests for the File Action Taken enum
class TestMFileAction < Minitest::Test
	def setup
		@strvals = [
			'UNDECIDED',
			'SENT_KEPT',
			'SENT_DELD',
			'SKIP_KEPT',
			'SKIP_DELD',
			'akjkj2b4tjjbetk'
		]
		@intvals = [0,1,2,3,4,5]
	end

	def test_strs
		int_vals_calculated = @strvals.map { |x| MFileAction.fr_str(x) }
		assert_equal int_vals_calculated, @intvals
	end

	def test_ints
		str_vals_calculated = @intvals.map { |x| MFileAction.to_str(x) }
		assert_equal str_vals_calculated, @strvals[0..-2] + ['UNDEFINED']
	end
end

# Tests for the bulk of the client module
class TestMediaBackup < Minitest::Test
	def setup
		@listing = MediaBackup.new({:generate => './Test/TestDataFolder'})

		@expec_listing = MediaBackup.new()
		@expec_listing.basePathFYI = '/home/david/SFiles/Projects/MediaSafe/Repo'
		@expec_listing.infoList = [
			{
				:filename=>"AnotherTestFile.xyz",
				:path=>"Test/TestDataFolder/",
				:size=>53,
				:checksum=>"47ba5e3bc41c710bd25fc01be1a18e21",
				:status=>0,
				:action=>0
			},
			{
				:filename=>"TestFile.txt",
				:path=>"Test/TestDataFolder/",
				:size=>80,
				:checksum=>"17467d85d61f5d4523fd1785680f32ef",
				:status=>0,
				:action=>0
			},
			{
				:filename=>"TestFile.txt",
				:path=>"Test/TestDataFolder/TestSubFolder1/",
				:size=>110,
				:checksum=>"c8ea95565095d0453665eb6aecd152e2",
				:status=>0,
				:action=>0
			}
		]
	end

	def test_list1
		assert_equal @listing, @expec_listing
	end
end

