# ServerCalls_Test.rb
# Test client access calls to server running in test mode
#
# David Lenkner, 2017

require 'rest-client'

class TestMFileStatus < Minitest::Test

	def setup()
		@test_port = 5678
		# Start up a server in a separate thread
		# Use different port (not default 4567) for test
		MediaSafeSinatra.basedir = Dir.pwd
		MediaSafeSinatra.run_in_bgthread(:port => @test_port, :server => 'webrick')
	end

	# Test that we say we're running
	def test_assertRunning()
		assert MediaSafeSinatra.am_i_running_bgthread()
	end

	# Test that I can do a simple get to '/'
	def test_basicGet()
		addr = 'localhost:' + @test_port.to_s + '/'
		curl_output = `curl #{addr}`
		assert output.include? 'Hooray' # Expected get response...
	end

	def teardown()
		# Abort the parallel thread running the server
		MediaSafeSinatra.stop_running_bgthread()
	end
end
