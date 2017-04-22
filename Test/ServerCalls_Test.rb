# ServerCalls_Test.rb
# Test client access calls to server running in test mode
#
# David Lenkner, 2017

# require 'rest-client'

class TestServerCalls < MiniTest::Test 

	include Rack::Test::Methods

	def app
		MediaSafeSinatra
	end

	MediaSafeSinatra.basedir = Dir.pwd

	# Test that I can do a simple get to '/'
	def test_get()
		get '/'
		assert last_response.ok?
		assert(last_response.body.include?('Hooray'), 'Basic get test')
	end

	# Test checking status where everything is there
	def test_allBackedUp()
		# Create a MediaBackup to send over
		b = MediaBackup.new({:generate => './Test/TestDataFolder'})
		
		post '/query', b.to_json()

		assert last_response.ok?

		# Okay it should have responded with JSON for the server statuses
		server_b = MediaBackup.new()
		server_b.from_json(last_response.body)
		
		server_b.infoList.each { |finfo|
			assert_equal MFileStatus::SAFE, finfo[:status] 
		}
		assert_equal Dir.pwd, server_b.basePath
	end

	# Test checking status when some things are NOT yet backed up
	def test_oneYetToBackup()
		# Add a file temporarily in the test data dir
		newfilename = 'newfile.txt'
		backupfolder = './Test/TestDataFolder/'
		fnew = File.new(backupfolder + newfilename,'w')
		fnew.puts 'This file is new and not yet be backed up.'
		fnew.close

		# Now create the "client" MediaBackup object
		b = MediaBackup.new({:generate => backupfolder})

		# Now remove the file so the server won't see it
		File.delete(backupfolder + newfilename)

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
	end
end
