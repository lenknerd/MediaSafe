# Rakefile for executing common tasks in MedaSafe project.
# Mainly unit test execution
#
# David Lenkner, 2017

ENV['RACK_ENV'] = 'test'
# require 'rake'
# require 'rake/testtask'
require 'minitest/autorun'
require 'rack/test'



# Note, not including autorun purposefully - sinatra 
# fork causes issues with it, some things run in other proc

task :default => [:sharedonly_tests, :test_server_calls]

# Runs test on just the shared utils, doesn't require server running
task :sharedonly_tests => [:load_shared] do
	require './Test/SharedOnly_Test.rb'
	# a = TestMFileStatus.new
	# a.run()
	# TestMediaSafeSharedUtils.run(MiniTest::Unit.runner)
	# TestMFileAction.run(MiniTest::Unit.runner)
	# TestMediaBackup.run(MiniTest::Unit.runner)

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
task :test_server_calls => [:load_shared, :load_server] do
	require './Test/ServerCalls_Test.rb'
	# TestServerCalls.run(MiniTest::Unit.runner)
end

