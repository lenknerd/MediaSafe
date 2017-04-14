# Rakefile for executing common tasks in MedaSafe project.
# Right now just does test execution, maybe later deploy server here?
#
# David Lenkner, 2017


task :default => [:clientonly_tests, :sharedonly_tests]

# Runs tests on just the client utils, doesn't require server running
task :clientonly_tests => [:load_client] do
	require './Test/ClientOnly_Test.rb'
end

# Runs test on just the shared utils, doesn't require server running
task :sharedonly_tests => [:load_shared] do
	require './Test/SharedOnly_Test.rb'
end

# Loads the client-side utility
task :load_client => [:load_shared] do
	require './Client/MediaSafeClient.rb'
end

# Loads shared utilities
task :load_shared do
	require './Shared/MediaSafeTools.rb'
end
