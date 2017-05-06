# MediaSafeTools.rb
# Tools used both on client and server of MediaSafe ruby-based backup module
#
# David Lenkner, 2017


# Checksums are used to determine file version, but to run, we need OS...
# Different checksum tools are available on Windows vs. Linux
module OS
	def OS.windows?
		(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	end

	def OS.mac?
		(/darwin/ =~ RUBY_PLATFORM) != nil
	end

	def OS.unix?
		!OS.windows?
	end

	def OS.linux?
		OS.unix? and not OS.mac?
	end
end

# An enum for file status on server
module MFileStatus
	UNKNOWN = 0 # Have not checked server for it yet
	NOT_PRESENT = 1 # No file with that name
	CONFLICT = 2 # Filename exists at same path, filename but diff md5sum
	SAFE = 3 # Same filename and md5sum already on srvr (note diff path is ok)
	UNDEFINED = 4 # Error! If converting string to this enum, bad string
	
	STRLIST = ['UNKNOWN', 'NOT_PRESENT', 'CONFLICT', 'SAFE']

	# Convert from string to MFileStatus enum
	def MFileStatus.fr_str(arg)
		result = MFileStatus::STRLIST.index(arg)
		if result == nil
			# Didn't find in possible array of things
			return MFileStatus::UNDEFINED
		else
			return result
		end
	end

	# Convert from MFileStatus enum to string
	def MFileStatus.to_str(arg)
		result = MFileStatus::STRLIST[arg]
		if result == nil
			# Bad number passed in, out of range
			return 'UNDEFINED'
		else
			return result
		end
	end
end


# Main utilities for my MediaSafe module
module MediaSafe

	# This function gets md5sum on a file (uses command-line call dep on OS)
	# Uses md5 checksum algorith
	def MediaSafe.getMD5(fPath)
		if(OS.windows?)
			certUtilOutput = `certUtil -hashfile "#{fPath}" MD5`
			# Output such as follows; split out just 2nd line, no spaces
			# > MD5 hash of file ./InstallerTest_TestApp1-Installer_build.log:
			# > 08 da 29 da 6c 92 c2 88 7d 02 5c 55 fc af 69 21
			# > CertUtil: -hashfile command completed successfully.
			return certUtilOutput.split("\n")[1].gsub(/\s+/, "")
		elsif(OS.linux?)
			md5Output = `md5sum "#{fPath}"`
			# Output in linux; need to just parse out first part, data
			# > 08da29da6c92c2887d025c55fcaf6921  ./InstallerTest_build.log
			return md5Output.split(' ')[0].gsub(/\s+/, "")
		else
			return '' # Rethink error handling here later
		end
	end

	# Info on a particular file in standard hash, f being file and folder path
	# in format ./SomePathWhere/WillBeBackedup/Filename.txt
	# Note... f and baseD are expected to be fully expanded to avoid ., ~, etc
	def MediaSafe.getInfoListItemFromF(f, baseD)
		# Need to figure out path just from baseD up to file
		# Also note we cut off the first element after subbing out baseD
		# in order to not include the separator at the start /subfolder/f.abc
		relPathAndFile = f.gsub(baseD,'')[1..-1]
		
		# Then split that into the filename and relative path without filename
		fname = File.basename(relPathAndFile)
		relPath = relPathAndFile.gsub(fname,'')

		return {
			:filename => fname,
			:path => relPath,
			:size => File.size(f),
			:checksum => MediaSafe.getMD5(f)
		}
	end

	# Create a hash of info from a single file to be backed up.  Info includes
	#  :filename - just the filename, no path, no './'
	#  :rel_path - relative path from baseD to file
	#  :checksum - md5 checksum result, as string (no whitespace)
	def MediaSafe.getFileInfo(fileOrDir, baseD)
		# Fully expand both baseD and fPath before using above (standardize
		# to avoid ./ or ~/, also avoid double // and things)
		fileOrDirStd = File.expand_path(fileOrDir)
		baseStd = File.expand_path(baseD)

		# If fPath is a file, that constitutes our list
		if(File.file?(fileOrDirStd))
			fList = [fileOrDirStd]
		else
			# Otherwise it's a folder, list all files recursively inside it
			# puts ' listing ' + fPathStd + '/**/*'
			fList = Dir.glob(fileOrDirStd + '/**/*').map { |el|
				File.expand_path(el)
			}
			# Remove anything that is itself a folder
			fList.reject! { |x| File.directory?(x) }
		end

		# For each file, get its info (md5sum, etc)
		infoList = fList.map { |f|
			getInfoListItemFromF(f, baseD)
		}
		
		# Don't allow empty files - you not have to back these up,
		# also doesn't play nice with the Windows certUtil md5sum
		infoList.reject! { |el|
			el[:size] == 0
		}

		return infoList
	end

end # End MediaSafe module


# An enum for what has happened to a file
module MFileAction
	UNDECIDED = 0 # Didn't get to it yet
	SENT_KEPT = 1 # Sent to server and kept here too
	SENT_DELD = 2 # Sent to server then deleted
	SKIP_KEPT = 3 # Skipped (presumably already on server) but kept here too
	SKIP_DELD = 4 # Skipped (presumably already on server) and deleted here
	UNDEFINED = 5 # Error! If converting string to this enum, bad string

	STRLIST = [
		'UNDECIDED',
		'SENT_KEPT',
		'SENT_DELD',
		'SKIP_KEPT',
		'SKIP_DELD'
	]

	# Convert from string to MFileAction enum
	def MFileAction.fr_str(arg)
		result = MFileAction::STRLIST.index(arg)
		if result == nil
			# Didn't find in possible array of things
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
		:basePath # Just in case you need it, the abs path from which gen'd

	# Three possible construction tracks;
	# - give it path ot a saved tsv from which to be loaded from (:saved =>)
	# - give it :generate = > from file/folder and :basedir => base
	# - give it nothing, can use this during testing, set members later
	def initialize(args = nil)
		@infoList = []
		if(args == nil)
			# Creating a total
		elsif(args.key?(:saved))
			# Load from the saved TSV
			loadFromTSV(args[:saved])
		elsif(args.key?(:generate))
			if(args[:bp] == nil)
				puts 'ERROR! Base path now required for generation of backup.'
				exit
			end
			@basePath = args[:bp]
			# Generate from directory argument
			@infoList = MediaSafe.getFileInfo(args[:generate], @basePath)
			@infoList.map! { |x| MediaBackup.addStatusAction(x) }
		else
			puts 'ERROR! Something totally unexpected in MediaBackup.new args.'
			exit
		end
	end

	# Save a MediaBackup session status to tsv table for load later, or view
	def saveToTSV(tsvPath)
		open(tsvPath, 'w') { |f|
			f.puts @basePath
			@infoList.each { |el|
				f.puts infoListItemLine(el)
			}
		}
	end

	# Get one line for one element of the file info list to the tsv file
	def infoListItemLine(el)
		return [
			MFileStatus.to_str(el[:status]),
			MFileAction.to_str(el[:action]),
			el[:filename],
			el[:path],
			el[:size].to_s,
			el[:checksum]
		].join("\t")
	end

	# Comparator - mainly for testing
	def ==(other_mb)
		# Check that all base elements equal... first basePathFyi
		if(@basePath != other_mb.basePath)
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

	# Convert to a plain ol' hash then make to JSON
	def to_json()
		# Note, the to_json handles turning ":path =>" to string key 'path'
		return {
			'basePath' => @basePath,
			'infoList' => @infoList
		}.to_json
	end

	# Convert from JSON data into one of these objects
	def from_json(json_data)
		h_temp = JSON.parse(json_data)
		@basePath = h_temp['basePath']
		@infoList = h_temp['infoList'].map { |fi|
			{
				:status => fi['status'],
				:action => fi['action'],
				:filename => fi['filename'],
				:path => fi['path'],
				:size => fi['size'],
				:checksum => fi['checksum']
			}
		}
	end

	# Load a MediaBackup session status from saved tsv
	# Note you can run this after already init'd, will just append
	# more items on
	def loadFromTSV(tsvPath)
		File.open(tsvPath, "r") do |f|
			# First line is where we ran this from, don't really need...
			@basePath = f.readline.strip
			# Rest of lines are info list
			while(line = f.gets) != nil
				lineEls = line.strip.split("\t")
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

	private

		# Set up a new FileList item with unknown status, undecided action
		def self.addStatusAction(fileInfo)
			fileInfo[:status] = MFileStatus::UNKNOWN
			fileInfo[:action] = MFileAction::UNDECIDED
			return fileInfo	
		end

	# End private section of class
end

