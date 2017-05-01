# MediaSafeServe.rb
# Server that accepts requests and reports backed-up status of files
#
# David Lenkner, 2017

require 'sinatra/base'
require 'webrick'
require 'json'
require 'logger'


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

# Class for the Sinatra server of MediaSafe
class MediaSafeSinatra < Sinatra::Base


	# Enable logging to a access log and error log one dir up from here in log folder
	::Logger.class_eval { alias :write :'<<' }
	access_log = ::File.join(::File.dirname(::File.expand_path(__FILE__)),'..','log','access.log')
	access_logger = ::Logger.new(access_log)
	error_logger = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'..','log','error.log'),"a+")
	error_logger.sync = true	 
	configure do
		use ::Rack::CommonLogger, access_logger
	end	   
	before {
		env["rack.errors"] =  error_logger
	}


	@@basedir = '/SERVER_BASEDIR_NOT_SET/'

	set :port, 5673 # My router doesn't allow default 4567 fwd.. just picked unused nearby

	# http://stackoverflow.com/questions/16832472/
	# ruby-sinatra-webservice-running-on-localhost4567-but-not-on-ip
	# Note, replace this with IP of machine or automatically get it...
	set :bind, '192.168.1.6' # This seems to be required to run from outside

	# Write accessor for class variable basedir
	def self.basedir=(bd)
		@@basedir = bd
	end

	# Read accessor for class variable basedir
	def self.basedir()
		return @@basedir
	end

	# Set production mode
	def self.setProductionMode()
		set :environment, :production
	end

	# The core request route - client asks for status of some files
	post '/query' do
		# Okay, let's not get too fancy here, don't need to lock for
		# concurrent use... just get contents, modify user's object,
		# send it back as JSON response with object statuses.
		
		# First get the MediaBackup object for our storage folder
		mb_serv = MediaBackup.new({:generate => @@basedir, :bp => @@basedir})

		# Now parse out the one sent from our client
		mb_clie = MediaBackup.new()
		mb_clie.from_json(request.body.read)

		# Now, compare the two for various status possibilities
		mb_clie.infoList.map! { |client_finfo|
			client_finfo[:status] = getServerStatus(client_finfo,
												mb_serv.infoList)
			client_finfo
		}
		
		# Lastly put in the server's MediaBackup start path for response,
		# client will SCP the appropriate stuff in
		mb_clie.basePath = mb_serv.basePath

		return mb_clie.to_json()
	end

	# Simple get that we can call as basic test.
	get '/' do
		# Note, don't change the text here w/o changing unit test...
		'Test call succeeded, media safe is running! Hooray!'
	end

end
