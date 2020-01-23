local mumble = require "mumble"
local inspect = require "inspect"
local csv = require "csv"

function getTime() --the library has mumble.gettime() but that only returns ms
	local _time = os.date('*t')
	_time = ("%02d:%02d:%02d"):format(_time.hour, _time.min, _time.sec)
	return " @ " .. _time --automatically adds the @ symbol for ease of use
end

function log(text, p)	--text to log, print?
	p = p == nil	--normally to make defaults you can do p = p or 'def' but since false is a valid answer here we gotta use something different
	local file = io.open("log.txt", "a")
	file:write("\n")
	file:write(text .. getTime())
	if p then
		print(text .. getTime())
	end
	file:close()
end

function loadCSV(file)
	local t = {}
	local f = csv.open(file)
	for fields in f:lines() do
		table.insert(t, fields[1])	
	end
	return t
end

macadamias = loadCSV("mi.csv")
admins = loadCSV("admins.csv")
channelTable = {}
usersAlpha = {}
players = {}
warnings = loadCSV("warn.csv")

function isMac(s)	--s will be a name only, not a user object
	for _,v in ipairs(macadamias) do
		if v:lower() == s:lower() and players[s:lower()].object:getID() ~= 0 then --0 means unregistered
			return true
		end
	end
end

local client, err = assert(mumble.connect("voice.nut.city", 42069, "lm.pem", "lm.key"))
if err ~= nil then
	log(err, true)
end
client:auth("PoopyJoe") --If the bot is registered on a server, it will always use the name it's registered under, however you'll still need to specify a string in this method.

client:hook("OnServerReject", function(event)
	log("ServerReject: "..reason)
end)

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
	for _,u in pairs(addup:getUsers()) do
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

function getlen(c, recursive)
	local i = 0
	for _,_ in pairs(c:getUsers()) do
		i = i + 1
	end
	if recursive then
		for _,channel in pairs(c:getChildren()) do
			for _,_ in pairs(channel:getUsers()) do
				i = i + 1
			end
		end
	end
	return i
end

function clear_medics()
	for k,v in pairs(players) do
		if not isMac(k) then
			v.medicImmunity = false
			v.captain = false
			v.volunteered = false
		end
	end
end

function roll(t)
	log("Trying to get a new medic pick")
	local i = 1
	local userTesting
	local c1, c2, c3 = channelTable.room1, channelTable.room2, channelTable.room3
	if c1.red.length + c1.blu.length >= 2 then
	if c2.red.length + c2.blu.length >= 2 then
	if c3.red.length + c3.blu.length >= 2 then 
	addup:message("You can't roll, there are already medics.")			
	log("Someone tried to roll but was denied due to sufficient players.") 
		return
	end
	end
	end
	while i <= getlen(addup) do
		if i > getlen(addup) then
			log("Run out of people to test.")
			addup:message("Everyone here has played Medic.")
			return
		else
			userTesting = usersAlpha[t[i]]
			if players[userTesting].medicImmunity == true or players[userTesting].object:getID() == 214 then
				log(userTesting .. " has immunity, continuing...")
				i = i + 1
			elseif players[userTesting].medicImmunity == false then
				log(userTesting .. " doesn't have immunity, breaking loop.")
				break
			end
		end
	end
	log("Selecting medic: " .. userTesting)
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
		log("No room to move players...")
		return
	end
	if red.length <= 0 then
		user.object:move(red.object)
		red.length = red.length + 1
	elseif blu.length <= 0 then
		user.object:move(blu.object)
		blu.length = blu.length + 1
	else
		log("Error in roll-move")
		return
	end
	log("Moved " .. user.object:getName())
	user.dontUpdate = true
	user.medicImmunity = true
	user.captain = true
end

client:hook("OnServerSync", function(event)	--this is where the initialization happens. The bot can do nothing in mumble before this.
	local _date = os.date('*t')
	_date = _date.month.."/".._date.day
	log("===========================================", false)
	log("Newly connected, Syncd as "..event.user:getName().." "..tostring(client:isSynced()).." v2.1.0".." @ ".. _date)
	log("===========================================",false)
	motd, msgen = "", false		--message of the day, message of the day bool	
	joe = event.user
	root = joe:getChannel():getParent():getParent()
	spacebase = find("Inhouse Pugs (Nut City)", "Poopy Joes Space Base")
	connectlobby = find("Inhouse Pugs (Nut City)", "Connection Lobby")
	addup = find("Inhouse Pugs (Nut City)", "Add Up")
	fatkids = find("Add Up", "Fat Kids")
	notplaying = find("Add Up", "Chill Room (Not Playing)")
	pugroot = find("Nut City Limits", "Inhouse Pugs (Nut City)")
	joe:move(spacebase)
	players = {}
	for _,v in pairs(client:getUsers()) do
		local u = v:getName():lower()
		local warn
		for _,w in pairs(warnings) do
			if w[1] == u then
				warn = tonumber(w[2])
				break
			end
		end
		players[u] = {
			object = v,
			volunteered = false,
			captain = false,
			dontUpdate = false,
			channelB = v:getChannel(),
			warnings = warn,
			selfbotdeaf = false
		}
		if isMac(u) then
			players[u].medicImmunity = true
		else
			players[u].medicImmunity = false
		end
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
	draftlock = false
	dle = true
end)

function mumble.channel.messager(self, m) --channel, message
	self:message(m)
	for _,channels in pairs(self:getChildren()) do
		channels:message(m)
	end
end

function lenprintout()
	print("-------------------------",getTime())
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
	local senderData = players[event.actor:getName():lower()]
	local sentchannel = event.actor:getChannel()
	log("MSG FROM " .. sender:getName() .. " IN CHANNEL " .. sentchannel:getName() .. ": " .. msg)
	if string.find(msg, "!help", 1) == 1 then
		sentchannel:message(
		"All Users:<br />!help - this menu.<br />!v red - volunteers for red team.<br />!pmh - prints medic history.<br />!rn - Your name backwords<br />!flip - Flip a coin. Everyone in your channel will see the result.<br />!rng x y - A random number between x and y.<br /><br />Admins:<br />!roll - Rolls for 2 medics. Specify '!roll 1' to roll just one.<br />'!fv user1 user2' - Swaps a Medic user1 out for a volunteer, user2.<br />'!dc 1' - Dump subchannels in server 1.<br />!mute/!unmute - mutes everyone but admins and captains, or unmutes them.<br />!ami - Adds medic immunity to a specified user.<br />!strike - removes medic immunity from a specified user.<br />'!fv userout userin' - Replace medic userout with the NEW medic userin.<br />!draftlock - Toggle whether or not people can move to addup."
		)
	end
	if string.find(msg, "!v ", 1) == 1 then
		if sentchannel == addup or sentchannel == fatkids or sentchannel == connectlobby then
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
				for _,user in pairs(team:getUsers()) do
					if players[user:getName():lower()].volunteered then return end					
					players[user:getName():lower()].medicImmunity = false
					players[user:getName():lower()].captain = false
					user:move(addup)
				end
				sender:move(team)
				local p = players[sender:getName():lower()]
				p.medicImmunity = true
				p.volunteered = true
				p.captain = true
			else
				log("Nut City Error code 102")
			end
		else
			log("Nut City Error code 103")
			log(sentchannel:getName().."*"..sentchannel:getParent():getName())
		end
	end
	if msg == "!rn" then
		sentchannel:message(string.reverse(sender:getName()))
	end
	if msg == "!flip" then
		math.randomseed(os.time())
		local r = math.random(1, 2)
		local c
		if r == 1 then
			c = ("Heads")
		else
			c = ("Tails")
		end
		sentchannel:message(c.." (Coin flipped by "..sender:getName()..")")
	end
	if string.find(msg, "!rng", 1) == 1 then
		local kwords = {}
		for word in msg:gmatch("%w+") do
			table.insert(kwords, word)
		end
		math.randomseed(os.time())
		sender:message(tostring(math.random(tonumber(kwords[2]), tonumber(kwords[3]))))
	end
	if string.find(msg, "!deaf", 1) == 1 then
		if senderData.selfbotdeaf == false then
			sender:setDeaf(true)
			senderData.selfbotdeaf = true
			log(sender:getName() .. " selfbot deafened.")
		else
			sender:message("Says here you're actually server deafened. Is this incorrect? Tell Zidgel.")
			log("Nut City Error 105")
			log("isDeaf", tostring(sender:isDeaf()))
		end
	end
	if string.find(msg, "!undeaf", 1) == 1 then
		if senderData.selfbotdeaf == true then
			sender:setDeaf(false)
			senderData.selfbotdeaf = false
			log(sender:getName() .. " selfbot undeafened.")
		else
			sender:message("Says here you're not server deafened. Is this incorrect? Tell Zidgel.")
			log("Nut City Error 106")
			log("isDeaf", tostring(sender:isDeaf()))
		end
	end
	if isAdmin(sender) then
		if string.find(msg, "!roll", 1) == 1 then
			draftlock = true
			log("Draftlock switched to true after roll begins")
			pugroot:messager("Medics being rolled, draft is locked.")
			for _,u in pairs(players) do
				u.captain = false
				u.volunteered = false
			end
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
			draftlock = false
			if dle then log("Draftlock switched to false after channel dump") end
			local cnl = tonumber(msg:sub(5))
			local server
			if cnl <= 5 and cnl >= 1 then
				server = find("Add Up", "Pug Server "..tostring(cnl))
			else
				log("Invalid channel to dump: " .. cnl)
			end
			sentchannel:messager("Attempting to dump channels...")
			log("Trying to dump channel " .. msg:sub(5))
			for _,room in pairs(server:getChildren()) do
				for _,user in pairs(room:getUsers()) do
					user:move(addup)
				end
			end
			addup:messager("Channel "..cnl.." dumped by ".. sender:getName())
			for k,v in pairs(server:getChildren()) do
				v:link(addup)
			end
		end
		if string.find(msg, "!strike", 1) == 1 then
			local player = msg:sub(9)
			players[player].medicImmunity = false
			log(sender:getName() .. " removes Medic Immunity from " .. player)
			addup:messager(sender:getName() .. " removes " .. player .. "'s medic immunity.")
		end
		if string.find(msg, "!ami", 1) == 1 then
			local player = msg:sub(6)
			players[player].medicImmunity = true
			log(sender:getName() .. " gives medic immunity to " .. player)
			addup:messager(sender:getName() .. " gives " .. player .. " medic immunity.")
		end
		if string.find(msg, "!clearmh", 1) == 1 then
			clear_medics()
			log(sender:getName() .. " cleared medic history.")
		end
		if string.find(msg, "!pmh", 1) == 1 then
			for k,v in pairs(players) do
				if v.medicImmunity then
					sender:message(k .. " has medic immunity")
				end
			end
		end
		if string.find(msg, "mute") then --this part is written very poorly :D ### REWRITE REWRITE REWRITE
			local b			--the boolean to set mute to.
			local ec = true		--whether or not to exclude captains from mutings.
			if string.find(msg, "!mute", 1) == 1 then
				b = true
				log(sender:getName().." muted all users.")
			elseif string.find(msg, "!unmute", 1) == 1 then
				b = false
				log(sender:getName().." unmuted all users.")
			else
				return
			end
			local condition = msg:gsub("!mute ", ""):gsub("!unmute ", ""):lower()
			if condition == "all" or msg:find("!unmute", 1) == 1 then
				ec = false
			else
				ec = true
			end
			for _,user in pairs(addup:getUsers()) do
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
			log("Server " .. msg:sub(7,7) .. " subchannels linked")
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
			draftlock = false
			log("Draftlock switched to false in accordance with unlink, DLE IS: "..tostring(dle))
			log("Server " .. msg:sub(9,9) .. " subchannels unlinked")
		end
		if string.find(msg, "!reload", 1) == 1 then
			local f = msg:sub(9)
			if f == "admins" then
				admins = loadCSV("admins.csv")
				log("Reloaded admins table")
			elseif f == "mi" then
				macadamias = loadCSV("mi.csv")
				log("Reloaded macadamias table")
			end
		end
		if string.find(msg, "!append", 1) == 1 then
			local kwords = {}
			for word in msg:gmatch("%w+") do
				table.insert(kwords, word)
			end
			table.insert(_G[kwords[2]], kwords[3])
			local file = io.open(kwords[2]..'.csv', 'a')
			file:write(kwords[3])
			file:close()
			log(sender:getName() .. " committed " .. kwords[3] .. " to table " .. kwords[2])
		end
		if string.find(msg, "!getid", 1) == 1 then
			local player = msg:sub(8)
			print(tostring(players[player].object:getID()))
		end
		if string.find(msg, "!printall", 1) == 1 then
			for k,v in pairs(players) do
				print(k, inspect(v))
				print("*****************************")
			end
		end
		if string.find(msg, "!copy", 1) == 1 then
			local kwords = {}
			for word in msg:gmatch("%w+") do
				table.insert(kwords, word)
			end
			players[kwords[3]] = players[kwords[2]]
			--"!copy GamerA GamerB" 
			--GamerB takes on the data (med immunity, etc) of GamerA
			log("data copied: " ..kwords[2].."->"..kwords[3])
		end
		if string.find(msg, "!fv", 1) == 1 then
			--fv Gamer1 Gamer2
			--Gamer1 is a med and Gamer2 is a civilian, but now they swap roles
			--as if Gamer2 had used !v
			local kwords = {}
			for word in msg:gmatch("%w+") do
				table.insert(kwords, word)
			end
			local pOut, pIn = players[kwords[2]], players[kwords[3]]
			local nc = pOut.object:getChannel()
			if pOut.volunteered then
				log(kwords[2].." can't be volunteered for, they're already a volunteer.")
				return
			end
			pIn.object:move(nc)
			pIn.medicImmunity, pIn.volunteered, pIn.captain = true, true, true
			pOut.object:move(addup)
			pOut.medicImmunity, pOut.captain = false, false
			log("Force-volunteer, swapped med "..kwords[2].." for civilian "..kwords[3])
		end
		if string.find(msg, "!warn", 1) == 1 then
			local player = msg:sub(7)
			if players[player].warnings then
				players[player].warnings = players[player].warnings + 1
			else
				players[player].warnings = 1
			end
			players[player].object:message("You've been warned.")
			log(sender:getName() .. " warns " .. player .. " who now has " .. players[player].warnings .. " warns.")
		end
		if string.find(msg, "!getwarns", 1) == 1 then
			local player = msg:sub(11)
			sender:message(player .." was warned ")
		end
		if string.find(msg, "!draftlock", 1) == 1 then
			draftlock = not draftlock
			if draftlock and dle then 
				addup:messager(sender:getName() .. " locked the draft!") 
			else
				addup:messager(sender:getName() .. " unlocked the draft!")
			end
			log(sender:getName() .. " toggled draft lock to " .. tostring(draftlock))
		end
		if string.find(msg, "!sync", 1) == 1 then
			for _,server in pairs(channelTable) do
				for _,room in pairs(server) do
					room.length = getlen(room.object)
				end
			end
			log("Updated channel lengths on the fly.")
			lenprintout()
		end
		if string.find(msg, "!toggle", 1) == 1 then
			local kwords = {}
			for word in msg:gmatch("%w+") do
				table.insert(kwords, word)
			end
			if kwords[2] == "dl" or kwords[2] == "dle" then
				dle = not dle
				sender:message("The draftlock system is now..")
				if dle then
					sender:message("On.")
					sender:message("Draftlocked?: "..tostring(draftlock))
				else
					sender:message("Off.")
				end
				log("Draftlock eligibility toggled to "..tostring(dle))
			elseif kwords[2] == "motd" then
				msgen = not msgen
				log("MOTD toggled to "..tostring(msgen).." by "..sender:getName())
			end		
		end
		if string.find(msg, "!cull", 1) == 1 then
			pugroot:messager("Deafened users are being moved to chill room! Blame "..sender:getName())
			for _,user in pairs(addup:getUsers()) do
				if user:isSelfDeaf() then
					user:move(notplaying)
				end
			end
			log("Deafened users culled")
		end
		if string.find(msg, "!mund", 1) == 1 then
			local t = {}
			for key,user in pairs(client:getUsers()) do
				local n = players[user:getName():lower()]
				if n.selfbotdeaf then
					user:setDeaf(false)
					n.selfbotdeaf = false
					table.insert(t, user:getName())
				end
			end
			log(sender:getName() .. " mass undeafened: " .. table.concat(t, " "))
		end
		if string.find(msg, "!setmotd", 1) == 1 then
			motd = string.sub(msg, 10) 
			log("MOTD set to "..motd.." by "..sender:getName())
		end
	end
end)

client:hook("OnUserConnected", function(event)
	local name = event.user:getName():lower()
	log("USER CONNECT: "..event.user:getName())
	local warn
	for _,w in pairs(warnings) do
		if w[1] == u then
			warn = tonumber(w[2])
			break
		end
	end
	if players[name] == nil then
		players[name] = {
			object = event.user,
			volunteered = false,
			captain = false,
			channelB = event.user:getChannel(),
			dontUpdate = false,
			warnings = warn,
			selfbotdeaf = false
		}
		if isMac(event.user:getName()) then
			players[name].medicImmunity = true
		else
			players[name].medicImmunity = false
		end
	else
		players[name].object = event.user
		players[name].volunteered = false
		players[name].captain = false
		players[name].channelB = event.user:getChannel()
		players[name].selfbotdeaf = false
	end
	if msgen then
		event.user:message(motd)
	end
end)

client:hook("OnUserRemove", function(event)
	if event.user == nil then
		log("Nut City Error 104: Nil user remove")
		return --i dont know if this needs to be here but im somehow getting an error that event.user is nil?
	end
	local u = players[event.user:getName():lower()]
	log("USER DISCO/REM: "..event.user:getName(), false)
	if event.ban then
	log(event.user:getName() .. " banned by "..event.actor:getName().." with reason "..event.reason)
	end
	for _,server in pairs(channelTable) do
		for _,room in pairs(server) do
			if room.object == u.channelB then
				room.length = room.length - 1
				return
			end
		end
	end
	if getlen(root, true) < 2 then
		log("Automatically clearing medic history.")
		clear_medics()
	end
end)

client:hook("OnUserChannel", function(event)	
	--When a user changes channels.
	--event is a table with keys: "user", "actor", "from", "to"
	if dle and draftlock and event.to == addup or event.to == fatkids and event.from == connectlobby or event.from == notplaying and not isAdmin(event.actor) then
			--using if event.from == connectlobby will exclude people moving in from other channels, like game channels or general, but thats a rare use case
			log(event.user:getName() .. " tried to addup, was locked out.")
			event.user:move(connectlobby)
			event.user:message("Sorry! Picking has already started and you're late! If you believe you've been wrongly locked out, tell an admin. They'll move you.")
			--we COULD use a user.key to save the data of whether a person was in addup to allow people to reconnect and still addup, but that would be a lot of work so I'm not going to, lol
	else
		if players[event.user:getName():lower()] == nil then
			return --user just connected
		end
		local u = players[event.user:getName():lower()]
		if u.dontUpdate == false then
			for _,server in pairs(channelTable) do
				for n,room in pairs(server) do
					if event.from == room.object then
						room.length = room.length - 1
					elseif event.to == room.object then
						room.length = room.length + 1
					end
				end
			end
		else
			u.dontUpdate = false
		end
		u.channelB = event.to
	end
end)

client:hook("OnTick", function()

end)

client:hook("OnChannelState", function(channel)

end)

client:hook("OnError", function(error_)
	if client:isSynced() then
		log(error_)
	else
		print('Err, not synced')
	end
end)

while client:isConnected() do
	client:update()
	mumble.sleep(0.01)
end
