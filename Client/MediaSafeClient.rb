# MediaSafeClient.rb
# Client-side utility to examine directory contents, query backup server,
# Parse results on whether files are already backed up, and scp them over if nec
# Basically all the meat of the client is here except the actual run-it call
#
# David Lenkner, 2017


# An enum for what has happened to a file
module MFileAction
	UNDECIDED = 0 # Didn't get to it yet
	SENT_KEPT = 1 # Sent to server and kept here too
	SENT_DELD = 2 # Sent to server then deleted
	SKIP_KEPT = 3 # Skipped (presumably already on server) but kept here too
	SKIP_DELD = 4 # Skipped (presumably already on server) and deleted here
	UNDEFINED = 5 # Error! If converting string to this enum, bad string

	STRLIST = ['UNDECIDED', 'SENT_KEPT', 'SENT_DELD', 'SKIP_KEPT', 'SKIP_DELD']

	# Convert from string to MFileAction enum
	def MFileAction.str(arg)
		result = MFileAction::STRLIST.index(arg)
		if result == nil
			# Didn't find in possible array of things
			puts 'Error! Unexpected string for MFileAction!'
			return MFileAction::UNDEFINED
		else
			return result
		end
	end
end


# A class for a media backup task. Can be initialized with a directory or file
# to back up, or from a previous backup info table (tab-separated for easy
# human-readability). Then can do the actual transfer via calls to server
class MediaBackup
	attr_reader :infoList, :unspokenBasePath

	def init(args)
		@infoList = []
		if(args.key?(:saved))
			# Load from the saved CSV
		elsif(args.key(:path))
			# Generate from directory argument
		else
			# Rethink error handling later?
			puts 'Unexpected arguments to MediaBackup creator.'
		end
	end

	private

		# Load a MediaBackup session status from saved tsv
		def loadFromTSV(tsvPath)
			File.open(tsvPath, "r") do |f|
				# First line in unspoken base path
				@unspokenBasePath = f.readline
				# Rest of lines are info list
				while(line = f.gets) != nil
					lineEls = line.split("\t")
					@infoList.push({
						:status => MFileStatus.str(lineEls[0]),
						:action => MFileAction.str(lineEls[1]),
						:filename => lineEls[2],
						:path => lineEls[3],
						:size => lineEls[4].to_i,
						:checksum => lineEls[5]
					})
				end
			end
		end

	# End private section of class
end

