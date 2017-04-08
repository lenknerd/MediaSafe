# MediaSafe

A simple Ruby-based remote backup utility for pictures, videos or other large non-editable files.
Also personal practice writing web API's in Ruby.
Client and server are in Ruby, and the client may be on a Windows or Linux OS.

Non-editable just means this isn't meant for files which are being updated or worked on - this is **not** source code control or revision tracking, just simple copy over and back up, with a few additional features.

The core example here (in fact the main reason for this project) is simply dumping picture files off of my phone from its camera.
I like to copy things off, but in order to keep them in the gallery, I don't always delete them from the phone afterwards because there are some I like to keep and show.
So next time I run a backup, I just want to check which are already backed up before remotely scp'ing them across.
There are a few more bells and whistles related to md5sums, but otherwise that's about it.

## Features

The actual transfer is done by a simple scp.  But before transferring, it md5sums the files and sends the filename and checksum information across to the server.
Then the server responds to say which files are already there and whether modifications exist.
Files may be in one of five states;

1. Filename and path already exists on server and has same md5sum as client version.
In this case, do nothing with it.
2. Filename exists at different path but same md5sum on server.
Here also do nothing, you already backed it up but put it at a different relative path.
3. Filename exists at same path and filename but different md5sum.
In this case you seem to have a new version of the file.
Notify client of such files, ask whether want to overwrite or skip.
4. Filename exists at different path but with different md5sum.
Transfer it across, treat it as new.
5. Filename does not exist.
Transfer across, treat as new.

