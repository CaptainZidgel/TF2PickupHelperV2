Installing
==========
The require("mumble") module can only be built and used on Linux.\
Commits a74faae and before (version 3.0 and below in code) require [lua-mumble](https://github.com/bkacjios/lua-mumble), everything after that uses a [custom fork](https://github.com/CaptainZidgel/Lumble/tree/installReady) of [Lumble](https://github.com/bkacjios/Lumble). For docs on installing Lumble, see [here](https://github.com/CaptainZidgel/Lumble/tree/docs/docs).\
If i set up my Lumble branch right, you should clone this folder next to the Lumble folder so a symlink can reach this script.\
If I set up the symlink wrong, you should install manually; this main.lua should be installed as init.lua in Lumble/modules/scripts.\


Writing Commands
================
```Lua
function cmd.command_name(ctx, args, flags)
	print("Hello! Your first argument: "..args[1])
	if flags["second"] then
		print("Your second argument: "..args[2])
	end
end
```
You might call this like:\
`!command_name apple banana -second`\
This would print:\
```
Hello! Your first argument: apple
Your second argument: banana
```
Args are separated by spaces (no support for multiple word arguments).\
Flags are optional and unordered.\
Ctx contains information you may find relevant for usage in a command.\
```
ctx = {
				p_data = players[event.actor:getName():lower()], 
				admin = isAdmin(event.actor), 
				sender_name = event.actor:getName(),
				sender = event.actor,
				channel = event.actor:getChannel()
}
```
