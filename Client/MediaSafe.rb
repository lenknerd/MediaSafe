#!/usr/bin/ruby -w
# MediaSafeClient.rb
# Client-side utility to examine directory contents, query backup server,
# parse results on whether files are already backed up, and scp them over
# Basically all the meat of the client is here
#
# David Lenkner, 2017

require 'slop'


# Here are available command-line option
def cli_ops
	cli_ops = Slop::Options.new
	cli_ops.banner = 'Usage: MediaSafe.rb [options]'
	cli_ops.separator ""
	cli_ops.separator "Options:"
	cli_ops.string "-s","-status", "File or directory to get status on"
	cli_ops.string "-o","-output", "Where to save status (_MediaSafeStat.tsv)"
	cli_ops.string "-r","-run", "MediaSafe status file to execute"

	cli_ops
end

# Parse ARGV for those flags
parser = Slop::Parser.new cli_ops
begin
	cli_args = parser.parse(ARGV).to_hash
rescue Slop::UnknownOption
	# Parsing hit unknown thing
	puts 'Unknown argument to MediaSafe.rb!'
	puts cli_ops
	exit
end

# Now take actions based on arguments
if(cli_args[:status] != nil)	
	getAndRecordStatus(cli_args)
elsif(cli_args[:run] != nil)
	puts "Running actions defined in #{cli_args[:run]}"
else
	puts 'No action requested (use either -s or -r option, e.g.,'
	puts '> ./MediaSafe.rb -s ./DirectoryToSee/IfBackedup/'
	puts ''
	puts cli_ops
end

# Function to get status of file/folder passed into -status option
def getAndRecordStatus(opts)
	if(opts[:output] == nil)
		outputFileName = "_MediaSafeStat.tsv"
	else
		outputFileName = opts[:output]
	end
	puts "Getting status of: #{opts[:status]}"
	puts "Writing to #{outputFileName}"
end

# Function to execute actions defined in status file


