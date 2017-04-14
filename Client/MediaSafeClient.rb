# MediaSafeClient.rb
# The client-side script to examine directory contents, query backup server,
# Parse results on whether files are already backed up, and scp them over if nec
# 
# David Lenkner, 2017

require '../Shared/MediaSafeTools.rb'


# An enum for what has happened to a file
module MFileAction
	UNDECIDED = 0 # Didn't get to it yet
	SENT_KEPT = 1 # Sent to server and kept here too
	SENT_DELD = 2 # Sent to server then deleted
	SKIP_KEPT = 3 # Skipped (presumably already on server) but kept here too
	SKIP_DELD = 4 # Skipped (presumably already on server) and deleted here
	UNDEFINED = 5 # Error! If converting string to this enum, bad string

	strList = ['UNDECIDED', 'SENT_KEPT', 'SENT_DELD', 'SKIP_KEPT', 'SKIP_DELD']

	# Convert from string to MFileAction enum
	def MFileAction.str(arg)
		result = MFileAction::strList.index(arg)
		if result.between?(0,4)
			return result
		else
			puts 'Error! Unexpected string for MFileAction!'
			return MFileAction::UNDEFINED
		end
	end
end


# An enum for file status on server
module MFileStatus
	NOT_PRESENT = 0 # No file with that name
	CONFLICT = 1 # Filename exists at same path, filename but different md5sum
	SAFE = 2 # Same filename and md5sum already on server (note diff path is ok)
	UNDEFINED = 3 # Error! If converting string to this enum, bad string

	# Note, there is no option here for "not checked yet", but let's say you only
	# generate this thing after requesting status from server

	strList = ['NOT_PRESENT', 'CONFLICT', 'SAFE']

	# Convert from string to MFileStatus enum
	def MFileStatus.str(arg)
		result = MFileStatus::strList.index(arg)
		if result.between?(0,2)
			return result
		else
			puts 'Error! Unexpected string for MFileStatus!'
			return MFileStatus::UNDEFINED
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
			File.open(tsvPath, "r") do { |f|
				# First line in unspoken base path
				@unspokenBasePath = f.readline
				# Rest of lines are info list
				while(line = f.gets) != nil
					lineEls = line.split("\t")
					@infoList.push({
						:status => 
						:filename => lineEls[2],
						:path => lineEls[3],
						:size => lineEls[4].to_i,
						:checksum => lineEls[5]
					})

 File.basename(f),
				 => f.gsub(File.basename(f),''), # Path not from whole root
				:size => File.size(f),                # but just from start of 'f'
				:checksum => 
				end
			}
		end
end

