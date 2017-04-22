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


## Installation

Both client and server rely on Ruby.

### Client


