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
	def MFileAction.fr_str(arg)
		result = MFileAction::STRLIST.index(arg)
		if result == nil
			# Didn't find in possible array of things
			puts 'Error! Unexpected string for MFileAction!'
			return MFileAction::UNDEFINED
		else
			return result
		end
	end

	# Convert from MFileAction enum to string
	def MFileAction.to_str(arg)
		result = MFileAction::STRLIST[arg]
		if result == nil
			# Bad number passed in, out of range
			puts 'Error! Unexpected value ' + arg.to_s + ' to MFileAction.to_str.'
			return 'UNDEFINED'
		else
			return result
		end
	end
end


# A class for a media backup task. Can be initialized with a directory or file
# to back up, or from a previous backup info table (tab-separated for easy
# human-readability). Then can do the actual transfer via calls to server
class MediaBackup
	attr_accessor :infoList, # The real info on all the files
		:basePathFYI # Just in case you need it, the abs path from which gen'd

	def initialize(args = nil)
		@infoList = []
		if(args == nil)
			# Rethink warning handling later? For now let create empty			
		elsif(args.key?(:saved))
			# Load from the saved TSV
			loadFromTSV(args[:saved])
		elsif(args.key?(:generate))
			# Generate from directory argument
			@infoList = MediaSafe.getFileInfo(args[:generate])
			@infoList.map! { |x| MediaBackup.addStatusAction(x) }
			@basePathFYI = Dir.pwd
		else
			puts 'Error - something totally unexpected in MediaBackup.new args.'
		end
	end

	# Save a MediaBackup session status to tsv table for load later, or view
	def saveToTSV(tsvPath)
		open(tsvPath, 'w') { |f|
			f.puts @basePathFYI
			@infoList.each { |el|
				f.puts [
					MFileStatus.to_str(el[:status]),
					MFileAction.to_str(el[:action]),
					el[:filename],
					el[:path],
					el[:size].to_s,
					el[:checksum]
				].join("\t")
			}
		}
	end

	# Comparator - mainly for testing
	def ==(other_mb)
		# Check that all base elements equal... first basePathFyi
		if(@basePathFYI != other_mb.basePathFYI)
			return false
		end
		# Then for this array, first ensure same size, then comp el-el
		if(other_mb.infoList.length != @infoList.length)
			return false
		end
		0.upto(@infoList.length-1) { |i|
			if(@infoList[i][:status] != other_mb.infoList[i][:status])
				return false
			elsif(@infoList[i][:action] != other_mb.infoList[i][:action])
				return false
			elsif(@infoList[i][:filename] != other_mb.infoList[i][:filename])
				return false
			elsif(@infoList[i][:path] != other_mb.infoList[i][:path])
				return false
			elsif(@infoList[i][:size] != other_mb.infoList[i][:size])
				return false
			elsif(@infoList[i][:checksum] != other_mb.infoList[i][:checksum])
				return false
			end
		}
		return true
	end

	private

		# Load a MediaBackup session status from saved tsv
		def loadFromTSV(tsvPath)
			File.open(tsvPath, "r") do |f|
				# First line is where we ran this from, don't really need...
				@basePathFYI = f.readline
				# Rest of lines are info list
				while(line = f.gets) != nil
					lineEls = line.split("\t")
					@infoList.push({
						:status => MFileStatus.fr_str(lineEls[0]),
						:action => MFileAction.fr_str(lineEls[1]),
						:filename => lineEls[2],
						:path => lineEls[3],
						:size => lineEls[4].to_i,
						:checksum => lineEls[5]
					})
				end
			end
		end

		# Set up a new FileList item with unknown status, undecided action
		def self.addStatusAction(fileInfo)
			fileInfo[:status] = MFileStatus::UNKNOWN
			fileInfo[:action] = MFileAction::UNDECIDED
			return fileInfo	
		end

	# End private section of class
end

