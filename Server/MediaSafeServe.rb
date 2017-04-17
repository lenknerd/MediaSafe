# MediaSafeServe.rb
# Server that accepts requests and reports backed-up status of files
#
# David Lenkner, 2017

require 'sinatra/base'
require 'json'
require 'thread'


# Note testing flag for whether this server instance is real or for
# testing.  If defined and true, then test mode.  Undefined means
# production mode.  Note, this is in Rakefile before including this.
# $server_test_mode = true


# Get status of client file on server given server info list
def getServerStatus(clientFileInfo, serverInfoList)
	# First see if filename exists on server and same md5sum
	serverInfoList.each { |si|
		if(si[:filename] == clientFileInfo[:filename] &&
		   si[:checksum] == clientFileInfo[:checksum])
			return MFileStatus::SAFE
		end
	}
	# If got here, then it's not backed up same sum/filename...
	# So check for same path/filename conflict against overwrite
	serverInfoList.each { |si|
		if(si[:filename] == clientFileInfo[:filename] &&
		   si[:path] == clientFileInfo[:path])
			return MFileStatus::CONFLICT
		end
	}
	# If neither of those, then it's just not backed up period
	return MFileStatus::NOT_PRESENT
end

class MediaSafeSinatra < Sinatra::Base

	@@basedir = '/SERVER_BASEDIR_NOT_SET/'
	@@running_thread = nil

	# The core request route - client asks for status of some files
	post '/query' do
		# Okay, let's not get too fancy here, don't need to lock for
		# concurrent use... just get contents, modify user's object,
		# send it back as JSON response with object statuses.
		
		# First get the MediaBackup object for our storage folder
		mb_serv = MediaBackup.new({:generate => @basedir})

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

	# Simple get that we can call as basic test.
	get '/' do
		# Note, don't change the text here w/o changing unit test...
		'Test call succeeded, media safe is running! Hooray!'
	end

	# Start the server in a parallel thread.
	# Note, thanks to "Prikso NAI"'s answer in this thread;
	# http://stackoverflow.com/questions/2589356/
	# execute-code-once-sinatra-server-is-running
	def self.run_in_bgthread(opts)
		if(@@running_thread != nil)
			puts 'Error!  Tried to start server while already running.'
			return
		end
		# Start up the application in a separate thread
		@@running_thread = Thread.new do
			q = Queue.new
			self.run!(opts) do |server|
				# This is the callback function for when has started
				q.push("server-started")
			end
			q.pop # This blocks until the run! callback runs
		end
	end

	# Check if I am running
	def self.am_i_running_bgthread()
		return @@running_thread != nil
	end

	# Stop me if I am running
	def self.stop_running_bgthread()
		if(@@running_thread == nil)
			puts 'Error!  Tried to stop server when not running anyway.'
			return
		end
		@@running_thread.exit
		@@running_thread = nil
	end
end
