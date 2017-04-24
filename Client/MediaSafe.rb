#!/usr/bin/ruby -w
# MediaSafeClient.rb
# Client-side utility to examine directory contents, query backup server,
# parse results on whether files are already backed up, and scp them over
# Basically all the meat of the client is here
#
# David Lenkner, 2017

require 'slop'
require 'rest-client'
require 'json'

# Work out relative path better here...
require './Shared/MediaSafeTools.rb'

# Client session class - does everything when .run called
class MediaSafeClientSession
	attr_accessor :cli_args, :server_url


	# Set up
	def initialize(app_argv)
		@cli_args = {}

		# Parse flags from argv, store in cli_args member
		parser = Slop::Parser.new cli_ops
		begin
			@cli_args = parser.parse(app_argv).to_hash
		rescue Slop::UnknownOption
			# Parsing hit unknown thing
			puts 'Unknown argument to MediaSafe.rb!'
			puts cli_ops()
			exit
		end
	end

	# Here are available command-line option
	def cli_ops
		cli_ops = Slop::Options.new
		cli_ops.banner = 'Usage: MediaSafe.rb [options]'
		cli_ops.separator ""
		cli_ops.separator "Options:"
		cli_ops.string "-s","-status", "File or directory to get status on"
		cli_ops.string "-o","-output", "Where to save status (_MediaSafeStat.tsv)"
		cli_ops.string "-r","-run", "MediaSafe status file to execute"
		cli_ops.string "-u","-url", "Address of MediaSafe server"

		cli_ops
	end

	# The main run function
	def run()
		# Take actions based on command-line arguments
		if(@cli_args[:status] != nil)	
			getAndRecordStatus()
		elsif(@cli_args[:run] != nil)
			takeActionsIn()
		else
			puts 'No action requested (use either -s or -r option, e.g.,'
			puts '> ./MediaSafe.rb -s ./DirectoryToSee/IfBackedup/'
			puts ''
			puts cli_ops()
		end
	end

	# Function to get status of file/folder passed into -status option
	def getAndRecordStatus()
		if(@cli_args[:output] == nil)
			outputFileName = "_MediaSafeStat.tsv"
		else
			outputFileName = @cli_args[:output]
		end
		puts "Getting status of: #{@cli_args[:status]}"
		# See what files we're trying to back up and md5sum etc
		mb = MediaBackup.new({:generate => @cli_args[:status]})

		# Send that info to the server and parse response
		if(@cli_args[:url] == nil)
			@server_url = 'www.lenknerd.com:4567'
		else
			@server_url = @cli_args[:url]
		end
		response = RestClient.post 'http://localhost:4567/query',
			mb.to_json(),
			:content_type => :json,
			:accept => :json
		mb_serv = MediaBackup.new()
		mb_serv.from_json(response.body)

		puts "Writing to #{outputFileName}"
		mb_serv.saveToTSV(outputFileName)
	end

	# Function to execute actions defined in file
	def takeActionsIn()
		# Read in the file
		inFileName = @cli_args[:run]
		puts "Running actions defined in #{inFileName}"
		mb = MediaBackup.new({:saved => inFileName})
	
		# Execute actions via scp

	end

end

# Instantiate app and run it
app = MediaSafeClientSession.new(ARGV)
app.run()
puts 'Done executing MediaSafe run.'
