# Rakefile for executing common tasks in MedaSafe project.
# Mainly unit test execution, but can also start up server
#
# David Lenkner, 2017


# Run all tests - shared tools, server calls
task :default => [:sharedonly_tests, :test_server_calls]

# Runs test on just the shared utils, doesn't require server running
task :sharedonly_tests => [:load_shared, :test_utils] do
	require './Test/SharedOnly_Test.rb'
end

# Loads shared utilities
task :load_shared do
	require './Shared/MediaSafeTools.rb'
end

# Load server utilities
task :load_server do
	require './Server/MediaSafeServe.rb'
end

# Test client accessing the test server
task :test_server_calls => [:load_shared, :load_server, :test_utils] do
	require './Test/ServerCalls_Test.rb'
end

# Basic test settings
task :test_utils do
	ENV['RACK_ENV'] = 'test'
	require 'minitest/autorun'
	require 'rack/test'
end

# Run the server
task :run_server => [:load_shared, :load_server] do
	puts 'Running the server...'

	# Change this if you want to server from different folder
	backupDir = '/media/david/BUNSEN/mesa'

	MediaSafeSinatra.basedir = backupDir
	MediaSafeSinatra.setProductionMode()
	MediaSafeSinatra.run!
end
