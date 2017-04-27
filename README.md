# MediaSafe

A simple Ruby-based remote backup utility for pictures, videos or other large non-editable files.
Non-editable just means not the sort of thing you'd be versioning usually.
So could be media files, could be used in conjunction with Plex or other media server.

Also personal practice writing and testing web API's in Ruby with Sinatra.

## Gems

Thanks to the creators of these;

* [Sinatra](http://www.sinatrarb.com/) for the simple web API
* [Minitest](http://www.rubydoc.info/gems/minitest/) and [Rack](http://rack.github.io/) for testing
* [Rake](http://rake.rubyforge.org/)
* Client side requests are done using [rest-client](https://github.com/rest-client/rest-client)
* [Slop](https://github.com/leejarvis/slop) for command-line argument parsing in client script
* [net-sftp](https://github.com/net-ssh/net-sftp)
* [json](https://rubygems.org/gems/json/versions/1.8.3)


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

### Windows Client

For a Windows system, install Ruby, then install the dev kit (see DevKit-mingw64-64-4.7.2-20130224-1432-sfx.exe dev kit link at http://rubyinstaller.org/downloads/).
Install instructions for the dev kit may be found [here](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit).
This is needed for the `json` gem.

Next install gems `net-sftp`, `json`, `rest-client`, and `slop`, in no particular order.

Then check out this Git repository somewhere on the client machine (could just grab the Shared and Client files, but might as well grab the whole thing and be able to easily pull updates).

Lastly, to be able to run it easily with the "mesa" alias, add these lines to your ruby vars batch file, by default at the end of C:\Ruby22-x64\bin\setrbvars.bat

	doskey mesa=ruby.exe <path-where-you-checked-out-repo>\Client\MediaSafe.rb $*

for example, I have it as

	doskey mesa=ruby.exe C:\Ruby22-x64\Custom\MediaSafe\Client\MediaSafe.rb $*

### Linux Client

As in Windows, install Ruby, then install gems `net-sftp`, `json`, `rest-client`, and `slop`, in no particular order.

If you already have a `.bash_aliases` file in your home directory, add this alias to it, or create that file and add this line;

	alias mesa="~/SFiles/Projects/MediaSafe/Repo/Client/MediaSafe.rb"

### Server

Install ruby, then check out the repository.  Install gems `rake`, `sinatra`, `MiniTest`, and `json`, and the developer kit (see above) if not installed already.

In server and client files, modify the ports and URL's as needed (see where lenknerd.com is specified, and where 5673 is specified as the port).  Change this to your public URL and port forwarded for Sinatra, or else simply change it to localhost.

Also in the Rakefile under the `run_server` task, change the base director where you would like to store all of the backed-up files.  This can be (for example) an external HD.

Install ftp service on the server via

	sudo apt-get install vsftpd

Finally start the server by going to the base directory of the repository and running

	nohup rake run_server &

## Client-Side Usage

To check the status of a particular folder and contents as to whether they are backed up, run

	mesa -s ./FolderToBeChecked/

That will create a status file in tab-separated format which can be viewed to see which items are already backed up.
The default filename is `_MediaSafeStat.tsv`, but the -o option allows a custom name.
To run the actions defined in that file, run

	mesa -r ./_MediaSafeStat.tsv -u <username>

This will then ask for the password for that user to write to the backup destination via sftp.

## Testing

To run the automated test suite via MiniTest, simple go to the base directory of this repository, and run

	rake
