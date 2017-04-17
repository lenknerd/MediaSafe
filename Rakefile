# Rakefile for executing common tasks in MedaSafe project.
# Mainly unit test execution
#
# David Lenkner, 2017


task :default => [:sharedonly_tests, :test_server_calls]

# Runs tests on just the client utils, doesn't require server running
# task :clientonly_tests => [:load_client] do
# 	require './Test/ClientOnly_Test.rb'
# end

# Runs test on just the shared utils, doesn't require server running
task :sharedonly_tests => [:load_shared] do
	require './Test/SharedOnly_Test.rb'
end

# Loads the client-side utility
# task :load_client => [:load_shared] do
# 	require './Client/MediaSafeClient.rb'
# end

# Loads shared utilities
task :load_shared do
	require './Shared/MediaSafeTools.rb'
end

# Load server utilities
task :load_server do
	require './Server/MediaSafeServe.rb'
end

# Test client accessing the test server
multitask :test_server_calls => [:load_shared, :load_server] do
	require './Test/ServerCalls_Test.rb'
end

