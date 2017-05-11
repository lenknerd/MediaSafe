# Rakefile for executing common tasks in MedaSafe project.
# Mainly unit test execution, but can also start up server
#
# David Lenkner, 2017


# Run all tests is the default task
task :default => [:unit_tests]

# Loads shared utilities
task :load_shared do
	require './Shared/MediaSafeTools.rb'
end

# Load server utilities
task :load_server do
	require './Server/MediaSafeServe.rb'
end


# ----- TASKS FOR TESTING ----- #

# Runs test on just the shared utils, doesn't require server running
task :unit_tests => [:load_shared, :load_server, :test_utils] do
	require './Test/UnitTests.rb'
end

# Basic testing setup stuff
task :test_utils => [:load_server, :load_shared] do
	ENV['RACK_ENV'] = 'test'
	require 'minitest/autorun'
	require 'rack/test'
	MediaSafeSinatra.archTSV = 'Test_Archive.tsv'

	# Set up the initial archive of the server repository (so not to
	# re-run all first call) for test repo, if not there already
	# Required for rack calls to sinatra server
	if(!File.exists?(MediaSafeSinatra.archTSV))
		mb = MediaBackup.new({
			:generate => Dir.pwd + '/Test/TestServerFolder/',
			:bp => Dir.pwd
		})
		mb.saveToTSV(MediaSafeSinatra.archTSV)
	end
end



# ----- TASKS FOR PRODUCTION SERVER USAGE ----- #

# Run the server
task :run_server => [:load_shared, :load_server] do
	puts 'Running the server in production mode.'
	MediaSafeSinatra.basedir = backupDir
	MediaSafeSinatra.setProductionMode()
	MediaSafeSinatra.run!
end

# Set up the initial archive of the server repository (so not to
# re-run all the md5summing of everything when called)
task :init_archive => [:load_shared, :load_server] do
	mb = MediaBackup.new({:generate => backupDir, :bp => backupDir})
	mb.saveToTSV(MediaSafeSinatra.archTSV)
end
