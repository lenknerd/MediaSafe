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

	# Test checking status
	def test_post1()
		# Create a MediaBackup to send over
		b = MediaBackup.new({:generate => './Test/TestDataFolder'})
		
		post '/query', b.to_json()

		assert last_response.ok?

		# Okay it should have responded with JSON for the server statuses
		server_b = MediaBackup.new()
		server_b.from_json(last_response.body)
		
		server_b.infoList.each { |finfo|
			assert_equal finfo[:status], MFileStatus::SAFE
		}
		assert_equal server_b.basePath, Dir.pwd
	end


end
