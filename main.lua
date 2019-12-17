local mumble = require "mumble"
local inspect = require "inspect"
local socket = require "socket"

print(socket._VERSION)

admins = {
"wolsne",
"pizza_fart",
"CaptainZidgel",
"Antecedent",
"Slicerogue",
"Okiewaka",
"Console-",
"dave2",
"HEDGEHOG_HERO"
}

usersAlpha = {}

local client, err = assert(mumble.connect("voice.nut.city", 42069, "lm.pem", "lm.key"))
client:auth("TESTBOT")

function find(p, c)		--parent, child | The library technically has a way to do this within it but I don't understand it :D
	for _,v in pairs(client:getChannels()) do
		if v:getName() == c and v:getParent():getName() == p then
			return v
		end
	end
end

function isAdmin(s)		--s will be the sender of a message, a user obj
	for _,v in ipairs(admins) do
		if v:lower() == s:getName():lower() and s:getID() ~= 0 then --0 means unregistered
			return true
		end
	end
end

function generateUsersAlpha()
	usersAlpha = {}
	local users = addup:getUsers()
	for _,u in pairs(users) do
		table.insert(usersAlpha, u:getName():lower())
	end
	table.sort(usersAlpha)
end

function randomTable(n)
	math.randomseed(os.time())
	local t = {}
	for i =	1, n do
		table.insert(t, i)
	end
	local r
	for i = 1, #t do
		r = math.random(i, #t)
		t[i], t[r] = t[r], t[i]
	end
	return t
end

function getlen(c)
	local c = c:getUsers()
	local i = 0
	for k,v in pairs(c) do
		i = i + 1
	end
	return i
end

function roll(t)
	print("Trying to get a new medic pick")
	local i = 1
	local userTesting
	local c1, c2, c3 = channelTable.room1, channelTable.room2, channelTable.room3
	if c1.red.length + c1.blu.length >= 2 then
		if c2.red.length + c2.blu.length >= 2 then
			if c3.red.length + c3.blu.length >= 2 then 					addup:message("You can't roll, ther are already medics.")			print("Someone tried to roll but was denied due to sufficient players.") 
			end
		end
	end
	while i <= getlen(addup) do
		if i > getlen(addup) then
			print("Run out of people to test.")
			addup:message("Everyone here has played Medic.")
			return
		else
			userTesting = usersAlpha[t[i]]
			if players[userTesting].medicImmunity == true then
				print(userTesting .. " has immunity, continuing...")
				i = i + 1
			elseif players[userTesting].medicImmunity == false then
				print(userTesting .. " doesn't have immunity, breaking loop.")
				break
			end
		end
	end
	print("Selecting medic: " .. userTesting)
	addup:message("Medic: " .. userTesting .. " (" .. t[i] .. ")")
	local user = players[userTesting]
	local red, blu
	if c1.red.length + c1.blu.length < 2 then
		red = c1.red
		blu = c1.blu
	elseif c2.red.length + c2.blu.length < 2 then
		red = c2.red
		blu = c2.blu
	elseif c3.red.length + c3.blu.length < 2 then
		red = c3.red
		blu = c3.blu
	else
		print("No room to move players...")
		return
	end
	if red.length <= 0 then
		user.object:move(red.object)
		red.length = red.length + 1
	elseif blu.length <= 0 then
		user.object:move(blu.object)
		blu.length = blu.length + 1
	else
		print("Error in roll-move")
		return
	end
	print("Moved " .. user.object:getName())
	user.dontUpdate = true
	user.medicImmunity = true
	user.captain = true
end

client:hook("OnServerSync", function(event)	--this is where the initialization happens. The bot can do nothing in mumble before this.
	print("Syncd as", event.user:getName())
	print(client:isSynced())
	joe = event.user
	root = joe:getChannel():getParent():getParent()
	spacebase = find("Inhouse Pugs (Nut City)", "Poopy Joes Space Base")
	connectlobby = find("Inhouse Pugs (Nut City)", "Connection Lobby")
	addup = find("Inhouse Pugs (Nut City)", "Add Up")
	joe:move(spacebase)
	players = {}
	for _,v in pairs(client:getUsers()) do
		print(v:getName():lower())
		local u = v:getName():lower()
		players[u] = {
			medicImmunity = false,
			object = v,
			volunteered = false,
			captain = false,
			dontUpdate = false,
			channelB = v:getChannel()
		}
	end
	channelTable = {
		room1 = {
		    red = {
		        object = find("Pug Server 1", "Red"),
		        length = getlen(find("Pug Server 1", "Red"))
		    },
		    blu = {
		        object = find("Pug Server 1", "Blu"),
		        length = getlen(find("Pug Server 1", "Blu"))
		    }
		},
		room2 = {
		    red = {
		        object = find("Pug Server 2", "Red"),
		        length = getlen(find("Pug Server 2", "Red"))
		    },
		    blu = {
		        object = find("Pug Server 2", "Blu"),
		        length = getlen(find("Pug Server 2", "Blu"))
		    }
		},
		room3 = {
		    red = {
		        object = find("Pug Server 3", "Red"),
		        length = getlen(find("Pug Server 3", "Red"))
		    },
		    blu = {
		        object = find("Pug Server 3", "Blu"),
		        length = getlen(find("Pug Server 3", "Blu"))
		    }
		}
	}
	lenprintout()
	
end)

function lenprintout()
	print("-------------------------")
	print("LENGTH OF RED1: " .. tostring(channelTable.room1.red.length))
	print("LENGTH OF BLU1: " .. tostring(channelTable.room1.blu.length))
	print("LENGTH OF RED2: " .. tostring(channelTable.room2.red.length))
	print("LENGTH OF BLU2: " .. tostring(channelTable.room2.blu.length))
	print("-------------------------")
end

client:hook("OnMessage", function(event)
	--[[
	channel:message("TEXT!") --send message to channel!
	event is a table with keys: "actor", "message", "users", "channels"
	]]--
	local msg = event.message:lower()
	msg = msg:gsub("<.+>", ""):gsub("\n*", ""):gsub("%s$", "")
	local sender = event.actor
	local sentchannel = event.actor:getChannel()
	print("MSG from".. sender:getName() .. ":		                         	" .. msg)

	if string.find(msg, "!v ", 1) == 1 then
		if sentchannel == addup or sentchannel == fatkids then
			local team = msg:sub(4,6):lower()
			local server = tonumber(msg:sub(-1))
			if server == 1 then
				server = channelTable.room1
			elseif server == 2 then
				server = channelTable.room2
			elseif server == 3 then
				server = channelTable.room3
			else
				if channelTable.room1.red.length + channelTable.room1.blu.length < 3 then
					server = channelTable.room1
				elseif channelTable.room2.red.length + channelTable.room2.blu.length < 3 then
					server = channelTable.room2
				elseif channelTable.room3.red.length + channelTable.room3.blu.length < 3 then
					server = channelTable.room3
				end
			end
			if server.red.length + server.blu.length < 3 then
				if team == "red" then
					team = server.red.object
				elseif team == "blu" then
					team = server.blu.object
				end
				for _,user in team:getUsers() do
					if players[user:getName():lower()].volunteered then return end					players[user:getName():lower()].medicImmunity = false
					players[user:getName():lower()].captain = false
					user:move(addup)
				end
				sender:move(team)
				local p = players[sender:getName():lower()]
				p.medicImmunity = true
				p.volunteered = true
				p.captain = true
			else
				print("Nut City Error code 102")
			end
		else
			print("Nut City Error code 103")
		end
	end
	if isAdmin(sender) then
		if string.find(msg, "!roll", 1) == 1 then
			generateUsersAlpha()
			local toRoll
			if #msg < 7 then
				toRoll = 2
			else	
				toRoll = tonumber(msg:sub(7,7))
			end
			while toRoll > 0 do
				roll(randomTable(getlen(addup)))
				toRoll = toRoll - 1
			end
		end
		if string.find(msg, "!dc ", 1) == 1 then
			local cnl = tonumber(msg:sub(5))
			local room
			if cnl == 1 then
				room = channelTable.room1
			elseif cnl == 2 then
				room = channelTable.room2
			elseif cnl == 3 then
				room = channelTable.room3
			end
			sentchannel:message("Attempting to dump channels...")
			print("Trying to dump channel " .. msg:sub(8))
			local red, blu = room.red.object, room.blu.object
			for _,u in pairs(red:getUsers()) do
				players[u:getName():lower()].captain = false
				players[u:getName():lower()].volunteered = false
				u:move(addup)
			end
			for _,u in pairs(blu:getUsers()) do
				players[u:getName():lower()].captain = false
				players[u:getName():lower()].volunteered = false
				u:move(addup)
			end
			addup:message("Channel " .. cnl .. " dumped by " .. sender:getName())
		end
		if string.find(msg, "!strike", 1) == 1 then
			local player = msg:sub(9)
			players[player].medicImmunity = false
			print(sender:getName() .. " strikes " .. player)
			addup:message(sender:getName() .. " removes " .. player "'s medic immunity.")
		end
		if string.find(msg, "!ami", 1) == 1 then
			local player = msg:sub(6)
			players[player].medicImmunity = true
			print(sender:getName() .. " gives medic immunity to " .. player)
			addup:message(sender:getName() .. " gives " .. player " medic immunity.")
		end
		if string.find(msg, "!clearmh", 1) == 1 then
			for k,v in pairs(players) do
				v.medicImmunity = false
				v.captain = false
				v.volunteered = false
			end
			print(sender:getName() .. " cleared medic history.")
		end
		if string.find(msg, "!pmh", 1) == 1 then
			for k,v in pairs(players) do
				if v.medicImmunity then
					sender:message(k .. " has medic immunity")
				end
			end
		end
		if string.find(msg, "mute") then --this part is written very poorly :D
			local b
			local ec = true
			if string.find(msg, "!mute", 1) == 1 then
				b = true
			elseif string.find(msg, "!unmute", 1) == 1 then
				b = false
			else
				return
			end
			local condition = msg:gsub("!mute ", ""):gsub("!unmute ", ""):lower()
			if condition == "all" or msg:find("!unmute", 1) == 1 then
				ec = false
			else
				ec = true
			end
			for k,user in pairs(addup:getUsers()) do
				local p = players[user:getName():lower()]
				if not isAdmin(user) then
					if not ec or (ec and not p.captain) then
						user:setMuted(b)
					end
				end
			end
			for _,channel in pairs(addup:getLinks()) do
				for _,user in pairs(channel:getUsers()) do
					local p = players[user:getName():lower()]
					if not isAdmin(user) then
						if not ec or (ec and not p.captain) then
							user:setMuted(b)
						end
					end
				end
			end
		end
		if string.find(msg, "!link", 1) == 1 then
			local server = tonumber(msg:sub(7,7))
			if server == 1 then
				server = channelTable.room1
			elseif server == 2 then
				server = channelTable.room2
			elseif server == 3 then
				server = channelTable.room3
			end
			local red, blu = server.red.object, server.blu.object
			addup:link(blu, red)
			blu:link(red)
		end
		if string.find(msg, "!unlink", 1) == 1 then
			local server = tonumber(msg:sub(9,9))
			if server == 1 then
				server = channelTable.room1
			elseif server == 2 then
				server = channelTable.room2
			elseif server == 3 then
				server = channelTable.room3
			end
			local red, blu = server.red.object, server.blu.object
			addup:unlink(blu, red)
			blu:unlink(red)
		end
	end
end)

client:hook("OnUserConnected", function(event)
	local name = event.user:getName():lower()
	print("CONNECT FROM " .. name)
	print("L " .. inspect(players[name]))
	if players[name] == nil then
	print("We gamin'")
		players[name] = {
			medicImmunity = false,
			object = v,
			volunteered = false,
			captain = false,
			channelB = v:getChannel()
		}
	else
		players[name].object = v
		players[name].volunteered = false
		players[name].captain = false
		players[name].channelB = v:getChannel()
	end
	print(inspect(event.user:getChannel()))
	print("We won mr stark")
end)

client:hook("OnUserRemove", function(event)
	print("DISCONNECT")
	local u = players[event.user:getName():lower()]
	for _,server in pairs(channelTable) do
		for n,room in pairs(server) do
			if room.object == u.channelB then
				room.length = room.length - 1
				break
			end
		end
	end
	lenprintout()
	print("DISCO " .. u.channelB:getName())
end)

client:hook("OnUserChannel", function(event)	
	--When a user changes channels.
	--event is a table with keys: "user", "actor", "from", "to"
	local u = players[event.user:getName():lower()]
	if u.dontUpdate == false then
		for _,server in pairs(channelTable) do
			for n,room in pairs(server) do
				if event.from == room.object then
					room.length = room.length - 1
					print("LEFT " .. event.from:getName())
				elseif event.to == room.object then
					room.length = room.length + 1
					print("TO " .. event.to:getName())
				end
			end
		end
	else
		u.dontUpdate = false
	end
	u.channelB = event.to
	lenprintout()
end)

client:hook("OnTick", function()
	
end)

client:hook("OnChannelState", function(channel)

end)

while client:isConnected() do
	client:update()
	mumble.sleep(0.01)
end
