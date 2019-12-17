Pug Assistant
============
The mumble bot written in lua-mumble to assist with running pick up games.\
Featuring such features as featured:

Features
--------
Keeps track of who has and hasn't played medic.  \
`!roll` new medics and never get a duplicate.  \
Automatically moves medics to their rooms.  \
`!unlink/!link` game rooms without needing to enter them individually and right click -> unlink all.  \
`!mute` all players who aren't admins or captains, or `!mute all` players who aren't admins.

Installing
==========
The require("mumble") module can only be built and used on Linux.\
`git clone https://github.com/bkacjios/lua-mumble.git`  \
Get the dependencies for the module\
`sudo apt-get install libluajit-5.1-dev protobuf-c libprotobuf-c-dev libssl-dev libopus-dev libvorbis-dev `\
CD into lua-mumble and `make`.  \
Place the main.lua into lua-mumble.  \
Run the command `luajit main.lua`  \
The bot will run.

Using it
--------
Of course, this bot is written for a specific mumble and won't be useful to you out of the box, but you may find it useful as an example document or something to fork.\
Make sure you make yourself some certificates if you want to register your bot to be an admin on your server.\
`openssl req -x509 -newkey rsa:2048 -keyout filename.key -out filename.pem -days 1000 -nodes`\
should work.
