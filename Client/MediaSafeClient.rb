# MediaSafeClient.rb
# The client-side script to examine directory contents, query backup server,
# Parse results on whether files are already backed up, and scp them over if approparite
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

# Main utilities for my MediaSafe module
module MediaSafe

	# This function gets md5sum on a file (uses different command-line calls depending on OS)
	# Uses md5 checksum algorith
	def getMD5(fPath)
		if(OS.windows?)
			certUtilOutput = `certUtil -hashfile #{fPath} MD5`
			# Output has for such as follows; need to split out just 2nd line, no spaces
			# > MD5 hash of file ./InstallerTest_TestApp1-Installer_build.log:
			# > 08 da 29 da 6c 92 c2 88 7d 02 5c 55 fc af 69 21
			# > CertUtil: -hashfile command completed successfully.
			return certUtilOutput.split("\n")[1].gsub(/\s+/, "")
		else if(OS.linux?)
			md5Output = `md5sum #{fPath}`
			# Output has this form (see below); need to just parse out first part, data
			# > 08da29da6c92c2887d025c55fcaf6921  ./InstallerTest_TestApp1-Installer_build.log
			return md5Output.split(' ')[0].gsub(/\s+/, "")
		else
			puts 'Mac OS not supported yet.'
			return '' # Rethink error handling here later
		end
	end

end
