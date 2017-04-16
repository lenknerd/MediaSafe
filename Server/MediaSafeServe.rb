# MediaSafeServe.rb
# Server that accepts requests and reports backed-up status of files
#
# David Lenkner, 2017

require 'sinatra'
require 'json'


# Note testing flag for whether this server instance is real or for
# testing.  If defined and true, then test mode.  Undefined means
# production mode.
# $server_test_mode = true

# Base directory where backups should occur
basedir = '/NOSUCHPATH/' # REPLACE LATER

# Testing backup directory
if(defined? $server_test_mode && $server_test_mode)
	# Note test path here is relative to Rakefile
	basedir = './Test/TestServerFolder/'
end

# Get status of client file on server given server info list
def getServerStatus(clientFileInfo, serverInfoList)
	# First see if filename exists on server and same md5sum
	serverInfoList.each { |si|
		if(si[:filename] == clientFileInfo[:filename]
		   && si[:checksum] == clientFileInfo[:checksum])
			return MFileStatus::SAFE
		end
	}
	# If got here, then it's not backed up same sum/filename...
	# So check for same path/filename conflict against overwrite
	serverInfoList.each { |si|
		if(si[:filename] == clientFileInfo[:filename]
		   && si[:path] == clientFileInfo[:path])
			return MFileStatus::CONFLICT
		end
	}
	# If neither of those, then it's just not backed up period
	return MFileStatus::NOT_PRESENT
end

# The core request route - client asks for status of some files
post '/query' do
	# Okay, let's not get too fancy here, don't need to lock for
	# concurrent use... just get contents, modify user's object,
	# send it back as JSON response with object statuses.
	
	# First get the MediaBackup object for our storage folder
	mb_serv = MediaBackup.new({:generate => basedir})

	# Now parse out the one sent from our client
	mb_clie = MediaBackup.new()
	mb_clie.from_json(request.body.read)

	# Now, compare the two for various status possibilities
	mb_clie.infoList.map! { |client_finfo|
		client_finfo[:status] = getServerStatus(client_finfo,
												server.infoList)
		client_finfo
	}
	
	# Lastly put in the server's MediaBackup start path for response,
	# client will SCP the appropriate stuff in
	mb_clie.basePathFYI = mv_serv.basePathFYI

	return mb_clie.to_json
end
