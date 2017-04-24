# SharedOnly_Test.rb
# Test functions for shared utilities on both client and server
# Does not require either of those to be running, only this
#
# David Lenkner, 2017


# Just tests the enum for various backed-up-ness statuses possible
class TestMFileStatus < MiniTest::Test
	def setup
		puts 'Running setup...'
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
class TestMediaSafeSharedUtils < MiniTest::Test
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


# Just tests for the File Action Taken enum
class TestMFileAction < MiniTest::Test
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
class TestMediaBackup < MiniTest::Test
	def setup
		@listing = MediaBackup.new({:generate => './Test/TestDataFolder'})

		fullPathToServDir = Dir.pwd + '/Test/TestDataFolder'
		@listing_wbase = MediaBackup.new({:generate => './Test/TestDataFolder',
									:bp => fullPathToServDir})

		@expec_listing = MediaBackup.new()
		@expec_listing.basePath = '/home/david/SFiles/Projects/MediaSafe/Repo'
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

		@expec_listing_wbase = MediaBackup.new()
		@expec_listing_wbase.basePath = '/home/david/SFiles/Projects/MediaSafe/Repo/Test/TestDataFolder'
		@expec_listing_wbase.infoList = [
			{
				:filename=>"AnotherTestFile.xyz",
				:path=>"",
				:size=>53,
				:checksum=>"47ba5e3bc41c710bd25fc01be1a18e21",
				:status=>0,
				:action=>0
			},
			{
				:filename=>"TestFile.txt",
				:path=>"",
				:size=>80,
				:checksum=>"17467d85d61f5d4523fd1785680f32ef",
				:status=>0,
				:action=>0
			},
			{
				:filename=>"TestFile.txt",
				:path=>"TestSubFolder1/",
				:size=>110,
				:checksum=>"c8ea95565095d0453665eb6aecd152e2",
				:status=>0,
				:action=>0
			}
		]

	end

	# The two created in the setup should be equal
	def test_list1
		assert_equal @listing, @expec_listing
	end

	# Test the two created with base path specified
	def test_list2
		assert_equal @listing_wbase, @expec_listing_wbase
	end

	# Try writing to tsv and reading from that, check that equal
	def test_writeRead
		temp_f = './Test/Temporary_Saved_MediaBackupForTest.tsv'
		@listing.saveToTSV(temp_f)

		readback_list = MediaBackup.new({:saved => temp_f})

		assert_equal @listing, readback_list

		File.delete(temp_f)
	end
end

