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
`!mute` all players who aren't admins  \
`!dc` move all players in a specified channel to add up.
`!cull` + `!afkcheck` move players who are deafened (cull) or idle for 5 minutes (afkcheck) to a specified room.  \

Installing
==========
The require("mumble") module can only be built and used on Linux.\
`git clone https://github.com/bkacjios/lua-mumble.git`  \
Get the dependencies for the module\
`sudo apt-get install libluajit-5.1-dev protobuf-c libprotobuf-c-dev libssl-dev libopus-dev libvorbis-dev `\
CD into lua-mumble and `make` then `make install`. I'm not too familiar with making so this might be wrong. Just make sure you `make install` if you intend to use the module outside of the folder you made it in.  \
Run the command `luajit main.lua`  \
The bot will run.

Using it
--------
Of course, this bot is written for a specific mumble and won't be useful to you out of the box, but you may find it useful as an example document or something to fork.\
Make sure you make yourself some certificates if you want to register your bot to be an admin on your server.\
`openssl req -x509 -newkey rsa:2048 -keyout filename.key -out filename.pem -days 1000 -nodes`\
should work.  \
This particular script comes with a template for ease of writing commands.  \
See the parse function for details on how commands are called.  \
They're written like this:  \
```Lua
function cmd.yourcommand(context, arguments)
--[[context =
	p_data = senderData,						-- The data we store in a table for all players.
	admin = isAdmin,						-- bool if sender is admin.
	sender_name = event.actor:getName(),	--
	sender = event.actor,					-- sender (mumble.user)
	channel = event.actor:getChannel()		-- sender's channel (mumble.channel) NOT the channel the message is sent to
]]--
--[[arguments is anything after yourcommand is called, separated by spaces.
	arguments = {'yourcommand', 'A', 'B', 'cd_ef'}
]]--
end
```
Call it from chat like this: `!yourcommand A B cd_ef`
