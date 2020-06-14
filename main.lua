--external includes
local inspect = require("inspect")
--lumble provided
local mumble = require("lumble")
local log = require("log")
local channel = require("lumble.client.channel")
-----------------------
local conn = require("connect")
--------------------------------------Configuration
local params = {
	mode = "client",
	protocol = "sslv23",
	key = conn.key,
	certificate = conn.pem
}
local client, err = mumble.getClient(conn.ip, conn.port, params)
if not client then log.error(err) return end
client:auth("2Poopy2Joe")
--------------------------------------Extra funcs needed for use inside and outside of commands
function file_exists(file) local f = io.open(file, "r") if f ~= nil then io.close(f) return true else return false end end	--https://stackoverflow.com/questions/4990990/check-if-a-file-exists-with-lua

function qlines(file, complex)				--q[uickly read]lines and return their contents.
	if file_exists(file) == false then log.info("Attempting to read file %s which doesn't exist, returning empty table", file) return {} end
	local output = {}
	for line in io.lines(file) do

			if not complex then
				output[line:lower()] = true 
			else
				string.gsub(line, "(%S+)%s(%d)", function(name, digit) output[name] = tonumber(digit) end) 
			end
		
	end
	return output
end

function write_to_file(t, complex)	--write a table to a csv file with the same name. This is the easiest solution I could think of for my problem. Rather than try and reopen and edit out specific lines from files, I just rewrite the files.
	local file = io.open(t..'.csv', 'w+')		--"w+" = open the file given (t..'.csv') and write over it (all data lost)
	for k,v in pairs(_G[t]) do
		if not complex then
			file:write(k..'\n')										--we write K instead of V because these tables store values in keys.
		else
			file:write(string.format("%s %d\n", k, v))
		end
	end
	file:close()
end

local admins = {}
client:requestACL()
local cmd = {}

--these must be global if you wish to use _G to find them (duh!)
macadamias = qlines("macadamias.csv")
warrants = qlines("warrants.csv")
purgatory = qlines("purgatory.csv", true)
local players = {}

function find()

end

function channel:messager(m, ...) --self=channel, m=message | SEND RECURSIVELY
	self:message(m, ...)
	for _,channels in pairs(self:getChildren()) do
		channels:messager(m, ...)
	end
end

function isAdmin(u)	--u is a user. user_id is 0 if unregistered or superuser. SuperUser can't use the bot because of this. Returning false in the case of a nil value so its a friendly boolean.
	if u:getName() == "CaptainZidgel" then return true end	
	return u:getID() ~= 0 and admins[u:getID()] or false
end

function isMac(s)	--s will be a user object
	return macadamias[s:getName():lower()] or false	--if its true return true, if its nil return a false value (to have neat booleans)
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

function load_channels(root)
	local t = {}
	for _,channelr in pairs(root:getChildren()) do
		for _,channel in pairs(channelr:getChildren()) do
			if channel:getName():lower() == "red" or channel:getName():lower() == "blu" then
				local color = channel:getName():lower()
				local c = tonumber(channel:getParent():getName():match("%d"))
				if t[c] == nil then t[c] = {} end
				t[c][color] = {object = channel, length = getlen(channel)}
			end
		end
	end
	return t
	--[[ Explanation:
	We search through each channel and act on team rooms instead of pug servers so there is less looping / the code is more explicit.	
	We find which team this is by getting the name, we find the server by extracting a substring with string:match()
	We assign the data into the actual channelTable by direct indexing.
	]]--
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

function determine_roll_num(ns)
	for i,channel in ipairs(ns.pugs) do
		local server = ns.addup:get("./Pug Server "..tostring(i))
		local l = getlen(server, true)
		if l < 2 then				--if 2 or more players, do the return. else: implicit continue
			return 2 - l			--this will return "2" if 0 people are in the selected server and "1" if 1 person is added up. No overflows.
		end
	end
	ns.addup:messager("Uh, are you sure you have space for new medics?")
	return 0 --no space
end

function roll(t, bottom_up, namespace, uList)
	log.info("Trying to get a new medic pick")
	print("- Determing if possible")
	local i = 1
	local userTesting
	local loop_through_channels = 0
	local addup = namespace.addup
	for _,server in ipairs(namespace.pugs) do
		loop_through_channels = loop_through_channels + 1	--iterate FIRST (so loop_through_channels will always be equal to the "ID" of the server we're searching)
		if server.red.length + server.blu.length < 2 then	--if there is space for medics in a server
			break																						--break this FOR LOOP (go to check purgatory)
		end																								--assume there is no space left in server.
		if loop_through_channels >= #namespace.pugs then	--if we have searched each available pug server
			addup:messager("You can't roll, all channels are full.")
			log.info("Someone tried to roll, was denied due to full medic slots.")
			return
		end
	end
	print("- Checking purgatory")
	for _,player in pairs(addup:getUsers()) do
		local pm = player:getName():lower()
		if purgatory[pm] and players[pm].volunteered == false then	--here, volunteered takes on the role of checking if a person has been moved.
			userTesting = pm
			purgatory[pm] = purgatory[pm] - 1
			if purgatory[pm] == 0 then
				purgatory[pm] = nil
			end
			players[pm].volunteered = true
			write_to_file('purgatory', true)
			log.info("Enforcing purgatory: " .. userTesting)
			goto skipsearch
		end
	end
	print("- Searching addup")
	while i <= getlen(addup) + 1 do
		if i > getlen(addup) then
			log.info("Run out of people to test.")
			namespace.root:messager("Everyone here has played Medic.")
			return
		else
			userTesting = uList[t[i]]
			if players[userTesting].medicImmunity == true then
				log.info(userTesting .. " has immunity, continuing...")
				i = i + 1
			elseif players[userTesting].medicImmunity == false then
				log.info(userTesting .. " doesn't have immunity, breaking loop.")
				break
			end
		end
	end
	::skipsearch::
	addup:messager("Medic: " .. userTesting)
	local user = players[userTesting]
	local red, blu
	local start, stop, iter
	if bottom_up then	--the "length of" namespace.pugs is the number of pug servers available to a namespace.
		start, stop, iter = #namespace.pugs, 1, -1
	else
		start, stop, iter = 1, #namespace.pugs, 1
	end
	for i = start, stop, iter do					--loop through each each of the pug servers.
		local server = namespace.pugs[i]
		if server.red.length + server.blu.length < 2 then
			red, blu = server.red, server.blu
			break
		end
	end
	addup:link(red.object, blu.object)
	if red.length <= 0 then
		user.object:move(red.object)
		red.length = red.length + 1
	elseif blu.length <= 0 then
		user.object:move(blu.object)
		blu.length = blu.length + 1
	else
		log.info("Error in roll-move")
		return
	end
	log.info("Moved " .. user.object:getName())
	user.dontUpdate = true
	user.medicImmunity = true
	user.captain = true
end

function parse(s, context)
	local kwords = {}
	local flags = {}
	for word in string.gmatch(s, "%S+") do  --%s = space char, %S = not space char. + means multiple in a row. Use this over %w+, to retain underscores.
		if word:sub(1, 1) == "-" then
			flags[word:sub(2):lower()] = true	--insert flags without the dash
		else
			table.insert(kwords, word)			--insert each positional argument into table kwords (includes the cmd name until we remove it).
		end	
	end
	local c_name = table.remove(kwords, 1):lower()	--remove+return the first value (the command name). this way, every value in this table is a parameter. set a variable c_name (command_name) to this value for evaluation.
	if cmd[c_name] ~= nil then							--if function exists
		local ret = cmd[c_name](context, kwords, flags)		--call function by name with context and arguments and flags. Set any return to a var.
		if ret == -1 then
			context.sender:message("You don't have permission for this command: "..c_name)
		end
	else	
		context.sender:message("This command is unknown: "..c_name)
	end
end
--------------------------------------------------serversync

client:hook("OnServerSync", function(client, joe)	--this is where the initialization happens. The bot can do nothing in mumble before this. "joe" is "me", this bot's user object.
	local _date = os.date('*t')
	_date = _date.month.."/".._date.day
	log.info("===========================================", false)
	log.info("Connected, Syncd as %s v4.1.0 on %s", joe:getName() ,_date)
	log.info("===========================================", false)
	motd, msgen = "", false		--message of the day, message of the day bool	
	quarantine = false				--whether or not to restrict unregistered users from the server
	------------------------------------------------
	root = client:getChannelRoot()
	pugroot = root:get("./Inhouse Pugs")
	spacebase = root:get("./Inhouse Pugs/Poopy Joes Space Base")
	------------------------------------------------"advanced" pugs (advanced to distinguish from junior)
	advNamed = {
		root = pugroot:get("./Pool 1"),
		connectlobby = pugroot:get("./Pool 1/Connection Lobby"),
		addup = pugroot:get("./Pool 1/Add Up"),
		notplaying = pugroot:get("./Pool 1/Add Up/Chill Room (Not Playing)"),
		draftlock = false
	}
	------------ok jr pugs now----------------------
	jrNamed = {
		root = pugroot:get("./Pool 2"),
		connectlobby = pugroot:get("./Pool 2/Entrance"),
		addup = pugroot:get("./Pool 2/Add Up"),
		notplaying = pugroot:get("./Pool 2/Add Up/Not Playing"),
		draftlock = false
	}
	------------------------------------------------
	joe:move(spacebase)
	players = {}
	for _,v in pairs(client:getUsers()) do
		local u = v:getName():lower()
		players[u] = {
			object = v,
			volunteered = false,
			captain = false,
			dontUpdate = false,
			channelB = v:getChannel(),
			selfbotdeaf = false,
			perma_mute = false,
			imprison = false,
			medicImmunity = isMac(v)
		}
	end
	jrNamed.pugs = load_channels(jrNamed.addup)
	advNamed.pugs = load_channels(advNamed.addup)
	dle = true
end)

------------------------------------supplementary functions that must appear after serversync
function get_namespace(obj)	--the namespace understander
	local channel	
	if obj.__type == "lumble.user" then
		channel = obj:getChannel()
	elseif obj.__type == "lumble.channel" then
		channel = obj
	end
	local channels = {}
	while channel ~= root do
		table.insert(channels, channel)
		channel = channel:getParent()
	end
	if channels[#channels - 1] == advNamed.root then
		return advNamed, "advNamed"
	elseif channels[#channels - 1] == jrNamed.root then
		return jrNamed, "jrNamed"
	else
		--print(obj:getChannel())
		return {pugs={}}
	end
end
----------------------------------commands
--[[Admins]]--
function cmd.roll(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local bottom_up = false
	local ns = flags["newb"] and jrNamed or advNamed
	ns.draftlock = true
	log.info("Draftlock switched to true after roll begins")
	ns.root:messager("Medics being rolled, draft is locked.")
	local toRoll
	if #args == 0 then
		toRoll = determine_roll_num(ns)
		print("No integer specified, rolling *just enough* medics!: "..tostring(toRoll))
	else	
		toRoll = tonumber(args[1])
		print("Rolling "..args[1].." medics as specified by user")
	end
	if flags["b"] then
		bottom_up = true
	end
	while toRoll > 0 do
		local uList = function() local t = {} for _,u in pairs(ns.addup:getUsers()) do table.insert(t, u:getName():lower()) end return t end
		roll(randomTable(getlen(ns.addup)), bottom_up, ns, uList())
		toRoll = toRoll - 1
	end
end
function cmd.link(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	local server = ns.pugs[tonumber(args[1])]
	local red, blu = server.red.object, server.blu.object
	ns.addup:link(blu, red)
	blu:link(red)
	log.info("Server " .. args[1] .. " subchannels linked by " .. ctx.sender_name)
end
function cmd.unlink(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	local server = ns.pugs[tonumber(args[1])]
	local red, blu = server.red.object, server.blu.object
	ns.addup:unlink(blu, red)
	blu:unlink(red)
	ns.draftlock = false
	log.info("Draftlock -> false. reason: unlink")
	log.info("Server " .. args[1] .. " subchannels unlinked by " .. ctx.sender_name)
end
function cmd.dc(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	ns.draftlock = false
	if dle then log.info("Draftlock switched to false after channel dump") end
	local cnl = tonumber(args[1])
	local server = ns.pugs[cnl]
	if server == nil then
		log.info("Invalid channel to dump: " .. cnl)
		return
	end
	ctx.channel:messager("Attempting to dump channels...")
	log.info("Trying to dump channel " .. args[1])
	for _,room in pairs(server) do
		for _,user in pairs(room.object:getUsers()) do
			user:move(ns.addup)
			local name = user:getName():lower()
			local p = players[name]
			p.imprison, p.captain, p.volunteer = false
			if warrants[name] == true then
				log.info("Banned " .. name .. " due to warrant!")
				event.user:ban("The ban hammer has spoken!")
				warrants[name] = nil														--remove this warrant
				write_to_file("warrants")
				return
			end
		end
	end
	ns.addup:messager("Channel "..cnl.." dumped by "..ctx.sender_name)
	for _,room in pairs(server) do
		room.object:link(ns.addup)
	end
end
function cmd.clearmh(ctx)
	if ctx.admin == false then return -1 end
	for _,v in pairs(players) do
		v.medicImmunity = isMac(v.object)
		v.captain = false
		v.volunteered = false
	end
	pugroot:messager(ctx.sender_name .. " reset medic history.")
	log.info(ctx.sender_name .. " cleared medic history.")
end
function cmd.strike(ctx, args)
	if ctx.admin == false then return -1 end
	local player = args[1]:lower()
	if players[player] then
		players[player].medicImmunity = false
		log.info(ctx.sender_name .. " removes Medic Immunity from " .. player)
		pugroot:messager("%s removes %s's medic immunity.", ctx.sender_name, player)
	else
		ctx.sender:message("Unknown user: %q", player)
	end
end
function cmd.ami(ctx, args)
	if ctx.admin == false then return -1 end
	local player = args[1]:lower()
	if players[player] then
		players[player].medicImmunity = true
		log.info(ctx.sender_name .. " gives medic immunity to " .. player)
		pugroot:messager("%s gives %s medic immunity.", ctx.sender_name, player)
	else
		ctx.sender:message("Unknown user: %q", player)
	end
end
function cmd.massadd(ctx, args)
	if ctx.admin == false then return -1 end
	for _,user in ipairs(args) do
		local p = players[user:lower()]
		if p then
			p.medicImmunity = true
		end
	end
	log.info(ctx.sender_name .. " gave med immunity to " .. table.concat(args, ",", 2))
end
function cmd.cull(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	ns.root:messager("Deafened users are being moved to chill room! Blame "..ctx.sender_name)
	for _,user in pairs(ns.addup:getUsers()) do
		if user:isSelfDeaf() then
			user:move(ns.notplaying)
		end
	end
	log.info("Deafened users culled")
end
function cmd.afkcheck(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	for _,user in pairs(ns.addup:getUsers()) do
		user:requestStats()
		local is = user:getStat("idlesecs")
		if is > 300 then
			log.info("%s is idle, moving them. Mins: %s", user:getName(), is/60)
			user:move(ns.notplaying)
			user:message("Hey! I think you've been idle for 5 minutes so I'm moving you out of add up.")
		end
	end
end
function cmd.mund(ctx)
	if ctx.admin == false then return -1 end
	local t = {}
	for _,user in pairs(client:getUsers()) do
		local p = players[user:getName():lower()]
		if p.selfbotdeaf then
			user:setServerDeafened(false)
			user:setServerMuted(false)
			p.selfbotdeaf = false
			table.insert(t, user:getName())
		end
	end
	log.info(ctx.sender_name .. " mass undeafened: " .. table.concat(t, " "))
end
function cmd.setmotd(ctx, args)
	if ctx.admin == false then return -1 end
	motd = table.concat(args, " ")
	log.info("MOTD set to "..motd.." by "..ctx.sender_name)
end
function cmd.readout(ctx, args)
	if ctx.admin == false then return -1 end
	local foo
	if #args == 1 then
		foo = _G[args[1]]
	else
		foo = _G
		for i=1, #args do
			local ok, err = pcall(function() foo = foo[args[i]] end)
			if not ok then
				ctx.sender:message("Error during index during readout: %s", err)
				return
			end
		end
	end
	if type(foo) == "table" then
		ctx.sender:message("Attemping to readout from table %s", args[#args])
		for k,v in pairs(foo) do
			ctx.sender:message("%key, value: %s, %s", k, v)
		end
		ctx.sender:message("Finished reading from table...")
	else
		ctx.sender:message("Response: %s", foo)
	end
end
function cmd.pmute(ctx, args)									--"perma" mute a user. (in vanilla mumble, if someone server muted reconnects, then they lose their muted status. This keeps this muted.
	if ctx.admin == false then return -1 end
	local player = players[args[1]:lower()]
	local bool = not player.perma_mute				--if user is server muted (method isMuted() appears to not work)
	player.perma_mute = bool
	player.object:setMuted(bool)
end
function cmd.dpr(ctx, args)
	if ctx.admin == false then return -1 end
	players[args[1]:lower()].imprison = false
	log.info("Released from prison: "..args[1])
end
function cmd.append(ctx, args)
	if ctx.admin == false then return -1 end
	if #args < 2 then ctx.sender:message("Are you missing a parameter?") return end
	_G[args[1]][args[2]:lower()] = true
	write_to_file(args[1])
	log.info(ctx.sender_name.." committed "..args[2].." to table "..args[1])
	ctx.sender:message("Added "..args[2].." to table "..args[1])
end
function cmd.remove(ctx, args)
	if ctx.admin == false then return -1 end
	if #args < 2 then ctx.sender:message("Are you missing a parameter?") return end
	_G[args[1]][args[2]:lower()] = nil
	write_to_file(args[1])
	log.info(ctx.sender_name.." removed "..args[2].." from table "..args[1])
	ctx.sender:message("removed "..args[2].." from table "..args[1])
end
function cmd.draftlock(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns, nss = flags["newb"] and jrNamed or advNamed, flags["newb"] and "jrNamed" or "advNamed"
	if #args == 0 then 
		ns.draftlock = not ns.draftlock
	elseif args[1]:lower() == "true" then
		ns.draftlock = true
	elseif args[1]:lower() == "false" then
		ns.draftlock = false
	else
		ctx.sender:message("Unknown value: %q", args[1])
	end
	if dle then pugroot:messager(ctx.sender_name .. " toggled draftlock to " .. tostring(ns.draftlock)) end
	log.info("%s toggled draftlock to %s for namespace %s", ctx.sender_name, tostring(ns.draftlock), nss)
end
function cmd.sync(ctx, args, flags)
	if ctx.admin == false then return -1 end
	if args[1]:lower() == "tables" or args[1]:lower() == "channels" then
		jrNamed.pugs = load_channels(jrNamed.addup)
		advNamed.pugs = load_channels(advNamed.addup)
		ctx.sender:message("Sync'd channels")
		log.info("Updated channels.")
	elseif args[1] == "users" and flags["f"] then
		local _players = {}
		for _,data in pairs(players) do
			local obj = data.object
			_players[obj:getName():lower()] = data
		end
		players = _players
		ctx.sender:message("Syncd users")
		log.info("Updated users")
	elseif args[1]:lower() == "admins" then
		client:requestACL()
		ctx.sender:message("Alright, I've just updated the admins.")
	else
		ctx.sender:message("Unknown option: %q, try TABLES or ADMINS", args[1])
	end
end
function cmd.toggle(ctx, args, flags)
	if ctx.admin == false then return -1 end
	if args[1]:lower() == "dl" or args[1]:lower() == "dle" then
		dle = not dle
		ctx.sender:message("The draftlock system is now..")
		if dle then
			ctx.sender:message("On.")
		else
			ctx.sender:message("Off.")
		end
		log.info("Draftlock eligibility toggled to "..tostring(dle))
	elseif args[1]:lower() == "motd" then
		msgen = not msgen
		log.info("MOTD toggled to %s by %s", msgen, ctx.sender_name)
	elseif args[1]:lower() == "q" or args[1]:lower() == "quarantine" then
		quarantine = not quarantine
		log.info("Quarantine toggled to %s by %s", quarantine, ctx.sender_name)
		ctx.sender:message("Alright, I toggled quarantine to %s", quarantine)
	elseif flags["f"] then
		if type(_G[args[1]]) == "boolean" then
			_G[args[1]] = not _G[args[1]]
			ctx.sender:message(_G[args[1]] .. " set to " .. tostring(_G[args[1]]))
			log.info(_G[args[1]] .. " set to " .. tostring(_G[args[1]]) .. " by " .. ctx.sender_name)
		end
	end		
end
function cmd.purg(ctx, args)
	if ctx.admin == false then return -1 end
	local t = tonumber(args[2]) or 3
	if t == 0 then t = nil end
	purgatory[args[1]:lower()] = t
	log.info("%s set %s 's medic purgatory length to %i", ctx.sender_name, args[1], t)
	write_to_file('purgatory', true)
end
function cmd.mute(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	log.info("%s muting addup. JR?%s", ctx.sender_name, flags["newb"])
	for _,user in pairs(ns.addup:getUsers()) do
		if not isAdmin(user) then
			user:setServerMuted(true)
		end
	end
	ns.addup:unlink(ns.notplaying)
end
function cmd.unmute(ctx, args, flags)
	if ctx.admin == false then return -1 end
	local ns = flags["newb"] and jrNamed or advNamed
	log.info("%s unmuting addup. JR?%s", ctx.sender_name, flags["newb"])
	for _,user in pairs(ns.addup:getUsers()) do
		user:setServerMuted(false)
	end
	ns.addup:link(ns.notplaying)
end
--[[Plebians]]--
function cmd.pmh(ctx, args, flags)
	if flags["me"] then
		if ctx.p_data.medicImmunity then
			ctx.sender:message("You have medic immunity! For now.")
		else
			ctx.sender:message("You don't have immunity! Watch your back.")
		end
	else
		for player,data in pairs(players) do
			if data.medicImmunity then
				ctx.sender:message(player .. " has medic immunity")
			end
		end
	end
end
function cmd.v(ctx, args)
	local ns = get_namespace(ctx.sender)
	local addup, connectlobby = ns.addup, ns.connectlobby
	if ctx.channel == addup or ctx.channel == connectlobby or ctx.channel == spacebase then
		local team = args[1]:lower()		
		if team == "red" or team == "blue" or team == "blu" then --!v red
			local server = args[2]
			if server ~= nil then
				server = ns.pugs[tonumber(server)]
			else
				for _,v in ipairs(ns.pugs) do
					if v.red.length + v.blu.length < 3 then
						server = v
						break
					end
				end
			end
			if server.red.length + server.blu.length < 3 then
				if team == "red" then
					team = server.red.object
				elseif team == "blu" or team == "blue" then
					team = server.blu.object
				end
				for _,user in pairs(team:getUsers()) do
					if players[user:getName():lower()].volunteered then ctx.sender:message("You can't volunteer, this medic is already a volunteer") return end					
					players[user:getName():lower()].medicImmunity = false
					players[user:getName():lower()].captain = false
					user:move(addup)
				end
				ctx.sender:move(team)
				local p = ctx.p_data				--data of the sender
				p.medicImmunity = true
				p.volunteered = true
				p.captain = true
				if getlen(team, true) < 1 then
					log.info(ctx.sender_name .. " has been imprisoned due to their volunteership.")
					ctx.sender:message("Thanks for volunteering! You've been temporarily imprisoned to this channel until the game is over to prevent trolling. If you believe there's been an error and wish to be imprisoned, ask an admin to release you.")
					p.imprison = team
				end
			else																								--rooms full
				log.error("E102.1")
				ctx.sender:message("Sorry, bot says you can't do this!")
			end
		else --!v username
			local recipient = players[args[1]:lower()]
			if recipient == nil then
				ctx.sender:message("Hey, that's not a user I recognize. Did you spell it right?")
				return
			end
			if args[1]:lower() == ctx.sender_name:lower() then
				ctx.sender:message("You can't do that!")
				return
			end
			if recipient.medicImmunity == false then
				ctx.sender:message("This person has to have been rolled on medic to be volunteered for.")
				return
			end
			if recipient.volunteered then
				ctx.sender:message("You can't volunteer, this medic is already a volunteer") 
				return 
			end		
			if string.find(recipient.object:getChannel():getParent():getName(), "Pug Server %d") == nil then
				ctx.sender:message("This can't be done, the person you're trying to volunteer for isn't even in a pug server!")
				return
			end			
			recipient.medicImmunity = false
			recipient.captain = false
			local c = recipient.object:getChannel()
			recipient.object:move(addup)
			local gifter = ctx.p_data
			gifter.volunteered, gifter.captain, gifter.medicImmunity = true, true, true
			gifter.object:move(c)
			log.info("%s has volunteered for %s successfully", ctx.sender_name, args[1])
			if getlen(c, true) < 1 then
				log.info(ctx.sender_name .. " has been imprisoned due to their volunteership.")
				ctx.sender:message("Thanks for volunteering! You've been temporarily imprisoned to this channel until the game is over to prevent trolling. If you believe there's been an error and wish to be imprisoned, ask an admin to release you.")
				gifter.imprison = c
			end
		end
	else						--bad channel
		ctx.sender:message("Error 103")
		log.error("E103 | Can't volunteer from this channel")
		log.info(ctx.channel:getName().."*"..ctx.channel:getParent():getName())
	end
end
function cmd.deaf(ctx)
	ctx.sender:setServerDeafened(true)
	ctx.p_data.selfbotdeaf = true
	log.info(ctx.sender_name .. " selfbot deafened.")
end
function cmd.undeaf(ctx)
	if ctx.p_data.selfbotdeaf == true then
		ctx.sender:setServerDeafened(false)
		ctx.sender:setServerMuted(false)
		ctx.p_data.selfbotdeaf = false
		log.info(ctx.sender_name .. " selfbot undeafened.")
	else
		ctx.sender:message("Says here you're not server deafened. Try doing !deaf then !undeaf")
		log.error("E106 | isDeaf?"..tostring(ctx.sender:isDeaf()))
	end
end
function cmd.purgstatus(ctx, args)
	if purgatory[ctx.sender_name:lower()] then
		ctx.sender:message("You must suffer %d more medic pug(s)!", purgatory[ctx.sender_name:lower()])
	else
		ctx.sender:message("You have no purgatory!")
	end
end

function cmd.flip(ctx)
	math.randomseed(os.time())
	local r = math.random(1, 2)
	local c
	if r == 1 then
		c = ("Heads")
	else
		c = ("Tails")
	end
	ctx.channel:message(c.." (Coin flipped by "..ctx.sender_name..")")
end
function cmd.rng(ctx, args)
	math.randomseed(os.time())
	ctx.sender:message(tostring(math.random(tonumber(args[1]), tonumber(args[2]))))
end
-----------------------------------Hooks
client:hook("OnTextMessage", function(client, event)
	local msg = event.message:gsub("<.+>", ""):gsub("\n*", ""):gsub("%s$", "")	--clean off html tags added by mumble, as well as trailing spaces and newlines.
	if string.find(msg, "!", 1) == 1 then	--if starts with !
		parse(string.sub(msg, 2), {
				p_data = players[event.actor:getName():lower()], 
				admin = isAdmin(event.actor), 
				sender_name = event.actor:getName(),
				sender = event.actor,
				channel = event.actor:getChannel()})
	end
end)

client:hook("OnACL", function(client, event)
	admins = {}
	for i=1, #event.groups.admin.add do
		admins[event.groups.admin.add[i]] = true
	end
	for i=1, #event.groups.moderator.add do
		admins[event.groups.moderator.add[i]] = true
	end
end)

client:hook("OnUserConnected", "When someone connects, update their information. If they need to be banned, ban them.", function(client, event)
	local name = event.user:getName():lower()
	if players[name] == nil then
		players[name] = {
			object = event.user,
			volunteered = false,
			captain = false,
			channelB = event.user:getChannel(),
			dontUpdate = false,
			selfbotdeaf = false,
			perma_mute = false,
			imprison = false,
			medicImmunity = isMac(event.user)
		}
	else
		players[name].object = event.user
		players[name].volunteered = false
		players[name].captain = false
		players[name].channelB = event.user:getChannel()
		players[name].selfbotdeaf = false
		if players[name].perma_mute == true then
			event.user:setMuted(true)
		end
		if players[name].imprison then event.user:move(players[name].imprison) end
	end
	if warrants[name] == true then										--warrants are evaluated after the player data is set so that if this is the user's first time connecting under this bot session, it doesn't cause any errors.
		log.info("Banned " .. name .. " due to warrant!")
		event.user:ban("The ban hammer has spoken!")
		warrants[name] = nil														--remove this warrant
		write_to_file("warrants")
		return
	end
	if msgen then
		event.user:message(motd)
	end
end)

client:hook("OnUserRemove", "When someone leaves the server, whether of their own volition or by the actions of a moderator", function(client, event)
	if event.user == nil then
		log.error("E104: Nil user remove")
		return --i dont know if this needs to be here but im somehow getting an error that event.user is nil?
	end
	local u = players[event.user:getName():lower()]
	local ns = get_namespace(event.user)
	if event.ban then
		log.info("=> %s banned by %s with reason %s", event.user:getName(), event.actor:getName(), event.reason)
	end
	for _,server in ipairs(ns.pugs) do --Due to the way information is updated in Lumble, we need to keep our own records on channel lengths.
		for _,room in pairs(server) do
			if room.object == u.channelB then
				room.length = room.length - 1
				return
			end
		end
	end
	--"User disconnected from outside of pug room"
end)

client:hook("OnUserChannel", "When someone changes channel", function(client, event)	
	--event is a table with keys: "user", "actor", "channel_prev", "channel"
	event.from, event.to = event.channel_prev, event.channel
	local ns, nss = get_namespace(event.channel)
	if players[event.user:getName():lower()] == nil then
			return --user just connected
	end
	if quarantine and event.user:getID() == 0 then --Quarantine user into root
		event.user:move(root)
		event.user:message("Hey sorry about that, we're temporarily keeping unregistered users here to prevent abuse. Hopefully an admin will see to you shortly.")
		return
	end
	if players[event.user:getName():lower()].imprison then						--if user must be imprisoned in one channel
		if event.actor == event.user then event.user:message("Thanks for volunteering! You've been temporarily imprisoned to this channel until the game is over to prevent trolling. If you believe there's been an error and wish to be imprisoned, ask an admin to release you.") end	
		event.user:move(players[event.user:getName():lower()].imprison)
		return
	end
	if dle and ns.draftlock and event.to == ns.addup and not isAdmin(event.actor) then
		if event.actor ~= event.user then
			log.info("%s moved by %s from %s to %s", event.user:getName(), event.actor:getName(), event.from:getName(), event.to:getName())
		end
		log.info(event.user:getName() .. " tried to addup, was locked out.")
		event.user:move(ns.connectlobby)
		event.user:message("Sorry! Picking has already started and you're late! If you believe you've been wrongly locked out, tell an admin. They'll move you.")
	else
		local u = players[event.user:getName():lower()]
		if u.dontUpdate == false and ns.pugs then
			for _,server in ipairs(ns.pugs) do
				for _,room in pairs(server) do
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

client:hook("OnUserState", "Handle name changes", function(client, event)
	if event.user == nil or event.old_user == nil then return end
	--We only want to handle name changes here, I'm pretty sure other hooks will do their jobs better.
	--I think it also will handle ID changes when a user is registered, so that's pretty cool.
	if event.user:getName() ~= event.old_user.name then		--are the usernames different?
		log.info("Username change: %s -> %s", event.old_user.name, event.user:getName())
		players[event.user:getName():lower()] = players[event.old_user.name:lower()]
		players[event.old_user.name:lower()] = nil
	elseif players[event.user:getName():lower()] == nil then	--okay they're the same but was this person here before this state change?
		return		--they weren't, so don't do anything. (OnUserConnected will handle this)
	end
	players[event.user:getName():lower()].object = event.user
end)

