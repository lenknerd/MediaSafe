# MediaSafeTools.rb
# Tools used both on client and server of MediaSafe ruby-based backup module
#
# David Lenkner, 2017


# Checksums are used to determine file version, but to run that, we need to know OS...
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
	CONFLICT = 2 # Filename exists at same path, filename but different md5sum
	SAFE = 3 # Same filename and md5sum already on server (note diff path is ok)
	UNDEFINED = 4 # Error! If converting string to this enum, bad string
	
	STRLIST = ['UNKNOWN', 'NOT_PRESENT', 'CONFLICT', 'SAFE']

	# Convert from string to MFileStatus enum
	def MFileStatus.fr_str(arg)
		result = MFileStatus::STRLIST.index(arg)
		if result == nil
			# Didn't find in possible array of things
			puts 'Error! Unexpected string for MFileStatus!'
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
			puts 'Error! Unexpected value ' + arg.to_s + ' to MFileStatus.to_str.'
			return 'UNDEFINED'
		else
			return result
		end
	end
end


# Main utilities for my MediaSafe module
module MediaSafe

	# This function gets md5sum on a file (uses different command-line calls depending on OS)
	# Uses md5 checksum algorith
	def MediaSafe.getMD5(fPath)
		if(OS.windows?)
			certUtilOutput = `certUtil -hashfile #{fPath} MD5`
			# Output has for such as follows; split out just 2nd line, no spaces
			# > MD5 hash of file ./InstallerTest_TestApp1-Installer_build.log:
			# > 08 da 29 da 6c 92 c2 88 7d 02 5c 55 fc af 69 21
			# > CertUtil: -hashfile command completed successfully.
			return certUtilOutput.split("\n")[1].gsub(/\s+/, "")
		elsif(OS.linux?)
			md5Output = `md5sum #{fPath}`
			# Output has this form in linux; need to just parse out first part, data
			# > 08da29da6c92c2887d025c55fcaf6921  ./InstallerTest_build.log
			return md5Output.split(' ')[0].gsub(/\s+/, "")
		else
			puts 'Mac OS not supported yet.'
			return '' # Rethink error handling here later
		end
	end

	# This creates a hash of info from a single file to be backed up.  Info includes
	#  :filename - just the filename, no path, no './'
	#
	#  :rel_path - relative path from place where backup script was run.
	#   also will turn into relative path where stored, in relation to storage root
	#
	#  :checksum - md5 checksum result, as string (no whitespace)
	def MediaSafe.getFileInfo(fPath)
		# Cut off a "./" or "./" if that is at the beginning of the path
		fPathTmp = fPath.gsub(/^\.\//,'').gsub(/^\.\\/,'')
		# And cut off a "\" or "/" if that ends the path
		fPathTmp2 = fPathTmp.gsub(/\\$/,'').gsub(/\/$/,'')
		# And replace any multiple /// or \\ etc.
		fPathStd = fPathTmp2.gsub(/([\\\/])\1+/,"\\1")

		# If fPath is a file, that constitutes our list
		if(File.file?(fPathStd))
			fList = [fPath]
		else
			# Otherwise it's a folder, list all files recursively inside it
			fList = Dir.glob(fPathStd + '/**/*')
			# Remove anything that is itself a folder
			fList.reject! { |x| File.directory?(x) }
		end

		# For each file, get it's size, md5sum, etc.
		infoList = fList.map { |f|
			{
				:filename => File.basename(f),
				:path => f.gsub(File.basename(f),''), # Path not from whole root
				:size => File.size(f),                # but just from start of 'f'
				:checksum => MediaSafe.getMD5(f)
			}
		}

		return infoList
	end

end
