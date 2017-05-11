# UnitTests.rb
# Test functions for shared utilities on both client and server
# Does not require server to be running, uses rack
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

# Bulk of testing here - all the shared utilities and server
# Test the MD5Sum utility
class TestMD5Sum < MiniTest::Test 

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


# Tests for the bulk of the code
class TestMediaSafe < MiniTest::Test

	include Rack::Test::Methods

	def app
		MediaSafeSinatra
	end

	# Test everything... break up later as per order not mattering
	def test_mb
		@listing = MediaBackup.new({
			:generate => './Test/TestDataFolder',
			:bp => Dir.pwd
		})

		@expec_listing = MediaBackup.new()
		@expec_listing.basePath = Dir.pwd
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

		assert_equal(@listing, @expec_listing, 'First listing in mbtest')


		# Here is another test for if the generate path = base path
		# as would be on server when backing up
		fullPathToServDir = Dir.pwd + '/Test/TestDataFolder'
		@listing_wbase = MediaBackup.new({
			:generate => fullPathToServDir,
			:bp => fullPathToServDir
		})

		@expec_listing_wbase = MediaBackup.new()
		@expec_listing_wbase.basePath = fullPathToServDir
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

		assert_equal(@listing_wbase, @expec_listing_wbase, 'Listing w base')

		temp_f = './Test/Temporary_Saved_MediaBackupForTest.tsv'
		@listing.saveToTSV(temp_f)

		readback_list = MediaBackup.new({:saved => temp_f})

		assert_equal @listing, readback_list

		File.delete(temp_f)

		# Try some calls to MediaSafeServer
	
		# Test that I can do a simple get to '/'
		get '/'
		assert last_response.ok?
		assert(last_response.body.include?('Hooray'), 'Basic get test')

		# Create a MediaBackup to send over
		b = MediaBackup.new({
			:generate => './Test/TestDataFolder',
			:bp => Dir.pwd
		})
		
		post '/query', b.to_json()

		assert last_response.ok?

		# Okay it should have responded with JSON for the server statuses
		server_b = MediaBackup.new()
		server_b.from_json(last_response.body)
		
		server_b.infoList.each { |finfo|
			assert_equal MFileStatus::SAFE, finfo[:status]
		}
		assert_equal Dir.pwd, server_b.basePath

		# Now test checking status when some things are NOT yet backed up
		# Add a file temporarily in the test data dir
		newfilename = 'newfile.txt'
		backupfolder = './Test/TestDataFolder/'
		sleep 1
		fnew = File.new(backupfolder + newfilename,'w')
		fnew.puts 'This file is new and not yet be backed up.'
		fnew.close
		sleep 1

		# Now create the "client" MediaBackup object
		b = MediaBackup.new({
			:generate => backupfolder,
			:bp => Dir.pwd
		})

		# Now remove the file so the server won't see it
		File.delete(backupfolder + newfilename)
		sleep 0.1

		# And ask the server status on files
		post '/query', b.to_json()

		assert last_response.ok?
		server_b = MediaBackup.new()
		server_b.from_json(last_response.body)

		# So, status-wise, all should be safe except the one not present	
		server_b.infoList.each { |finfo|
			if(finfo[:filename] == newfilename)
				assert_equal MFileStatus::NOT_PRESENT, finfo[:status]
			else
				assert_equal MFileStatus::SAFE, finfo[:status]
			end
		}

		# Test telling it hey we backed something up
		post '/log_safe', b.to_json()

		# Later, put in check on response
		assert(last_response.ok?, 'Response received from log_safe.')
		assert(last_response.body.include?('ROGER'))
	end

end

