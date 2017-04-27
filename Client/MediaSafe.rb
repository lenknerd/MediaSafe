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

# NET::SFTP causes some annoying warnings in new ruby versions...
# should fix or just chuck it for better module, but for now hush it
$old_verbos = $VERBOSE
module Kernel
	def suppress_warnings
		$VERBOSE = nil
	end

	def allow_warnings
		$VERBOSE = $old_verbos
	end
end

Kernel.suppress_warnings
require 'net/sftp'
Kernel.allow_warnings

# Might want to reconsider how to find this later...
require File.dirname(__FILE__) + '/../Shared/MediaSafeTools.rb'

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
		cli_ops.string "-l","-url", "Location of MediaSafe server"
		cli_ops.string "-u","-username", "Username of server user for scp"
		cli_ops.string "-p","-password", "Password of server user for scp (note, better to leave off, will ask for entry)"

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
			@server_url = 'lenknerd.com:5673'
		else
			@server_url = @cli_args[:url]
		end
		response = RestClient.post @server_url + '/query',
			mb.to_json(),
			:content_type => :json,
			:accept => :json
		mb_serv = MediaBackup.new()
		mb_serv.from_json(response.body)

		# Decide on actions; later could involve user interaction
		mb_serv.infoList.map! { |f|
			if(f[:status] == MFileStatus::SAFE ||
				f[:status] == MFileStatus::CONFLICT)
				f[:action] = MFileAction::SKIP_KEPT
			elsif(f[:status] == MFileStatus::NOT_PRESENT)
				f[:action] = MFileAction::SENT_KEPT
			else
				f[:action] = MFileAction::UNDECIDED
			end
			f
		}

		puts "Writing to #{outputFileName}"
		mb_serv.saveToTSV(outputFileName)
	end

	# Strip off folder names down to some level
	def stripFolder(path_str, nd)
		output = path_str + ''
		0.upto(nd) { |i|
			output = File.dirname(output)
		}
		return output
	end

	# Function to execute actions defined in file
	def takeActionsIn()
		# Check the username supplied
		if(@cli_args[:username] == nil)
			puts '-u  <username> argument required.'
			exit
		end

		# Ask for password entry in secure way
		if(@cli_args[:password] == nil)
			@cli_args[:password] = '' # SFTP will ask for pw if not right
		end

		# Set server url of where to copy to
		if(@cli_args[:url] == nil)
			@server_url = 'www.lenknerd.com'
		else
			@server_url = @cli_args[:url]
		end

		# Read in the file
		inFileName = @cli_args[:run]
		puts "Running actions defined in #{inFileName}"
		mb = MediaBackup.new({:saved => inFileName})


		# Connect to server for SCP's
		Kernel.suppress_warnings
		Net::SFTP.start(@server_url, @cli_args[:username],
					   :password => @cli_args[:password]) do |sftp1|

			# Go through each file in the list
			mb.infoList.each { |f1|
				# Later also check for SENT_DELD - for now never deleting
				if(f1[:action] == MFileAction::SENT_KEPT)
					src_str = Dir.pwd + '/' + f1[:path] + f1[:filename]
					dest_str = mb.basePath + '/' + f1[:path] + f1[:filename]

					# Make the directory if not there, up to 4 levels
					4.downto(0) { |i|
						fold = stripFolder(dest_str, i)
						begin
							sftp1.mkdir!(fold)
						rescue Net::SFTP::StatusException	
							# No problem, folder probably wasn't already there
						end
					}

					# This does the transfer and outputs progress on it (nice for big files)
					puts "Transferring #{src_str} to #{dest_str}"
					sftp1.upload!(src_str, dest_str)

				else
					puts 'Skipping...'
				end
			}
		end
		Kernel.allow_warnings
	end

end

# Instantiate app and run it
app = MediaSafeClientSession.new(ARGV)
app.run()
puts 'Done executing MediaSafe run.'
