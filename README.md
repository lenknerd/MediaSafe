# MediaSafe

A simple Ruby-based remote backup utility for pictures, videos or other large non-editable files.
Non-editable just means not the sort of thing you'd be versioning usually.
So could be media files, could be used in conjunction with Plex or other media server.

Also personal practice writing and testing web API's in Ruby with Sinatra.

## Modules

Thanks to the creators of these packages I use here;

* [Sinatra](http://www.sinatrarb.com/) for the simple web API
* [Minitest](http://www.rubydoc.info/gems/minitest/) and [Rack](http://rack.github.io/) for testing
* [Rake](http://rake.rubyforge.org/)
* Client side requests are done using [rest-client](https://github.com/rest-client/rest-client)
* [Slop](https://github.com/leejarvis/slop) for command-line argument parsing in client script
* [rest-client](https://github.com/rest-client/rest-client) for querying server from client


## Features

The actual transfer is done by a simple scp.
But before transferring, it md5sums the files and sends the filename and checksum information across to the server.
Then the server responds to say which files are already there and whether modifications exist.

Sure, this sort of thing is already available with rsync or other tools like that, but I want to check if the picture/video is **anywhere** in the backup area, not just in the one place.
I want to respond in one of the following ways;

1. Filename already exists on server and has same md5sum as client version.
Here, you don't want to copy it.

1. Filename exists at same path and filename but different md5sum.
In this case you seem to have a conflict, don't copy.
Not trying to version things here.

1. Either filename doesn't exist at all, or same name but different path and md5sum
Transfer it across, treat it as new.

## Running

For a simple local run test, go to the base directory of this repository, and run

	rake run_server

to start the server, then

	./Client/MediaSafe.rb -s ./Test/TestDataFolder/ -l localhost:4567 -o statuses.tsv

to query that server and get the status of the ./Test/TestDataFolder.
That stores the results in statuses.tsv.
Then do the actions summarized in that file via

	./Client/MediaSafe.rb -r ./statuses.tsv -l localhost -u <username> -p <password>

## To Do

* Finish up client side

* Add instructions on usage or installation to this readme

## Installation Note on NET-SCP Gem

I was getting a warning from net-scp upon usage about a shadowed variable 'ch'.

	david@alfred:~/SFiles/Projects/MediaSafe/Repo/Client$ ./MediaSafe.rb -r ./st -u a -p a -l localhost
	/var/lib/gems/2.3.0/gems/net-scp-1.2.1/lib/net/scp.rb:365: warning: shadowing outer local variable - ch
	/var/lib/gems/2.3.0/gems/net-scp-1.2.1/lib/net/scp.rb:366: warning: shadowing outer local variable - ch
	/var/lib/gems/2.3.0/gems/net-scp-1.2.1/lib/net/scp.rb:367: warning: shadowing outer local variable - ch
	/var/lib/gems/2.3.0/gems/net-scp-1.2.1/lib/net/scp.rb:368: warning: shadowing outer local variable - ch

Couldn't find this variable anywhere in my code, grep'd for ch.  Must be conflict with other module...
anyway I just changed ch to ch1 in that file location.

Ah, never mind, sftp needed anywhere to mkdir... see [this](https://linuxconfig.org/how-to-setup-and-use-ftp-server-in-ubuntu-linux) for install.
