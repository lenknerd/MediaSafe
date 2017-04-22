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


end
