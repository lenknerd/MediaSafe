#!/usr/bin/ruby -w
# MediaSafeClient.rb
# Client-side utility to examine directory contents, query backup server,
# Parse results on whether files are already backed up, and scp them over
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
	cli_ops.string "-r","-run", "MediaSafe status file to execute"

	cli_ops
end

# Parse ARGV for those
parser = Slop::Parser.new cli_ops
begin
	cli_args = parser.parse(ARGV).to_hash
rescue Slop::UnknownOption
	# Parsing hit unknown thing	
	puts cli_ops
	exit
end

# Now take actions based on arguments
if(cli_args[:status] != nil)
	puts "Getting status of: #{cli_args[:status]}"
elsif(cli_args[:run] != nil)
	puts "Running actions defined in #{cli_args[:run]}"
else
	puts 'No action requested (use either -s or -r option, e.g.,'
	puts '> ./MediaSafe.rb -s ./DirectoryToSee/IfBackedup/'
	puts ''
	puts cli_ops
end
