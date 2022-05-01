local CATEGORY_NAME = "功用"

------------------------------ Who ------------------------------
function ulx.who( calling_ply, steamid )
	if not steamid or steamid == "" then
		ULib.console( calling_ply, "ID 名字                            组" )

		local players = player.GetAll()
		for _, player in ipairs( players ) do
			local id = tostring( player:UserID() )
			local nick = utf8.force( player:Nick() )
			local text = string.format( "%i%s %s%s ", id, string.rep( " ", 2 - id:len() ), nick, string.rep( " ", 31 - utf8.len( nick ) ) )

			text = text .. player:GetUserGroup()

			ULib.console( calling_ply, text )
		end
	else
		data = ULib.ucl.getUserInfoFromID( steamid )

		if not data then
			ULib.console( calling_ply, "不存在提供的 ID 的信息" )
		else
			ULib.console( calling_ply, "   ID: " .. steamid )
			ULib.console( calling_ply, " 名字: " .. data.name )
			ULib.console( calling_ply, "组: " .. data.group )
		end


	end
end
local who = ulx.command( CATEGORY_NAME, "ulx who", ulx.who )
who:addParam{ type=ULib.cmds.StringArg, hint="steamid", ULib.cmds.optional }
who:defaultAccess( ULib.ACCESS_ALL )
who:help( "查看当前在线用户的信息." )

------------------------------ Version ------------------------------
function ulx.versionCmd( calling_ply )
	ULib.tsay( calling_ply, "ULib " .. ULib.pluginVersionStr("ULib"), true )
	ULib.tsay( calling_ply, "ULX " .. ULib.pluginVersionStr("ULX"), true )
end
local version = ulx.command( CATEGORY_NAME, "ulx version", ulx.versionCmd, "!version" )
version:defaultAccess( ULib.ACCESS_ALL )
version:help( "查看版本信息." )

------------------------------ Map ------------------------------
function ulx.map( calling_ply, map, gamemode )
	if not gamemode or gamemode == "" then
		ulx.fancyLogAdmin( calling_ply, "#A 将地图更改为 #s", map )
	else
		ulx.fancyLogAdmin( calling_ply, "#A 使用游戏模式 #s 将地图更改为 #s", map, gamemode )
	end
	if gamemode and gamemode ~= "" then
		game.ConsoleCommand( "gamemode " .. gamemode .. "\n" )
	end
	game.ConsoleCommand( "changelevel " .. map ..  "\n" )
end
local map = ulx.command( CATEGORY_NAME, "ulx map", ulx.map, "!map" )
map:addParam{ type=ULib.cmds.StringArg, completes=ulx.maps, hint="地图", error="无效的地图 \"%s\" 指定的", ULib.cmds.restrictToCompletes }
map:addParam{ type=ULib.cmds.StringArg, completes=ulx.gamemodes, hint="游戏模式", error="无效的游戏模式 \"%s\" 指定的", ULib.cmds.restrictToCompletes, ULib.cmds.optional }
map:defaultAccess( ULib.ACCESS_ADMIN )
map:help( "更改地图和游戏模式." )

function ulx.kick( calling_ply, target_ply, reason )
	if target_ply:IsListenServerHost() then
		ULib.tsayError( calling_ply, "该玩家免疫踢", true )
		return
	end

	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A 踢出 #T (#s)", target_ply, reason )
	else
		reason = nil
		ulx.fancyLogAdmin( calling_ply, "#A 踢出 #T", target_ply )
	end
	-- Delay by 1 frame to ensure the chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.kick, target_ply, reason, calling_ply )
end
local kick = ulx.command( CATEGORY_NAME, "ulx kick", ulx.kick, "!kick" )
kick:addParam{ type=ULib.cmds.PlayerArg }
kick:addParam{ type=ULib.cmds.StringArg, hint="未说明", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
kick:defaultAccess( ULib.ACCESS_ADMIN )
kick:help( "踢出目标." )

------------------------------ Ban ------------------------------
function ulx.ban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsListenServerHost() then
		ULib.tsayError( calling_ply, "该玩家免疫封禁", true )
		return
	end

	local time = "给予 #s"
	if minutes == 0 then time = "永久" end
	local str = "#A 封禁 #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.kickban, target_ply, minutes, reason, calling_ply )
end
local ban = ulx.command( CATEGORY_NAME, "ulx ban", ulx.ban, "!ban", false, false, true )
ban:addParam{ type=ULib.cmds.PlayerArg }
ban:addParam{ type=ULib.cmds.NumArg, hint="分钟,0 表示永久", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
ban:addParam{ type=ULib.cmds.StringArg, hint="未说明", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
ban:defaultAccess( ULib.ACCESS_ADMIN )
ban:help( "封禁目标." )

------------------------------ BanID ------------------------------
function ulx.banid( calling_ply, steamid, minutes, reason )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "无效的steamid." )
		return
	end

	local name, target_ply
	local plys = player.GetAll()
	for i=1, #plys do
		if plys[ i ]:SteamID() == steamid then
			target_ply = plys[ i ]
			name = target_ply:Nick()
			break
		end
	end

	if target_ply and (target_ply:IsListenServerHost() ) then
		ULib.tsayError( calling_ply, "该玩家免疫封禁", true )
		return
	end

	local time = "给予 #s"
	if minutes == 0 then time = "永久" end
	local str = "#A 封禁 steamid #s "
	displayid = steamid
	if name then
		displayid = displayid .. "(" .. name .. ") "
	end
	str = str .. time
	if reason and reason ~= "" then str = str .. " (#4s)" end
	ulx.fancyLogAdmin( calling_ply, str, displayid, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.addBan, steamid, minutes, reason, name, calling_ply )
end
local banid = ulx.command( CATEGORY_NAME, "ulx banid", ulx.banid, nil, false, false, true )
banid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
banid:addParam{ type=ULib.cmds.NumArg, hint="分钟,0 表示永久", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
banid:addParam{ type=ULib.cmds.StringArg, hint="未说明", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
banid:defaultAccess( ULib.ACCESS_SUPERADMIN )
banid:help( "封禁 steamid." )

function ulx.unban( calling_ply, steamid )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "无效的 steamid." )
		return
	end

	name = ULib.bans[ steamid ] and ULib.bans[ steamid ].name

	ULib.unban( steamid, calling_ply )
	if name then
		ulx.fancyLogAdmin( calling_ply, "#A 解封 steamid #s", steamid .. " (" .. name .. ")" )
	else
		ulx.fancyLogAdmin( calling_ply, "#A 解封 steamid #s", steamid )
	end
end
local unban = ulx.command( CATEGORY_NAME, "ulx unban", ulx.unban, nil, false, false, true )
unban:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
unban:defaultAccess( ULib.ACCESS_ADMIN )
unban:help( "解封 steamid." )

------------------------------ Noclip ------------------------------
function ulx.noclip( calling_ply, target_plys )
	if not target_plys[ 1 ]:IsValid() then
		Msg( "你是神,不受凡人筑墙的束缚.\n" )
		return
	end

	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if v.NoNoclip then
			ULib.tsayError( calling_ply, v:Nick() .. " 现在不能飞行.", true )
		else
			if v:GetMoveType() == MOVETYPE_WALK then
				v:SetMoveType( MOVETYPE_NOCLIP )
				table.insert( affected_plys, v )
			elseif v:GetMoveType() == MOVETYPE_NOCLIP then
				v:SetMoveType( MOVETYPE_WALK )
				table.insert( affected_plys, v )
			else -- Ignore if they're an observer
				ULib.tsayError( calling_ply, v:Nick() .. " 现在不能飞行.", true )
			end
		end
	end
end
local noclip = ulx.command( CATEGORY_NAME, "ulx noclip", ulx.noclip, "!noclip" )
noclip:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
noclip:defaultAccess( ULib.ACCESS_ADMIN )
noclip:help( "允许目标飞行." )

function ulx.spectate( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( "您无法从服务器控制台观看.\n" )
		return
	end

	-- Check if player is already spectating. If so, stop spectating so we can start again
	local hookTable = hook.GetTable()["KeyPress"]
	if hookTable and hookTable["ulx_unspectate_" .. calling_ply:EntIndex()] then
		-- Simulate keypress to properly exit spectate.
		hook.Call( "KeyPress", _, calling_ply, IN_FORWARD )
	end

	if ulx.getExclusive( calling_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( calling_ply, calling_ply ), true )
		return
	end

	ULib.getSpawnInfo( calling_ply )

	local pos = calling_ply:GetPos()
	local ang = calling_ply:GetAngles()

	local wasAlive = calling_ply:Alive()

	local function stopSpectate( player )
		if player ~= calling_ply then -- For the spawning, make sure it's them doing the spawning
			return
		end

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() )
		hook.Remove( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex() )
		hook.Remove( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex() )

		if player.ULXHasGod then player:GodEnable() end -- Restore if player had ulx god.
		player:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox
		ulx.fancyLogAdmin( calling_ply, true, "#A 停止偷窥 #T", target_ply )
		ulx.clearExclusive( calling_ply )
	end
	hook.Add( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex(), stopSpectate, HOOK_MONITOR_HIGH )

	local function unspectate( player, key )
		if calling_ply ~= player then return end -- Not the person we want
		if key ~= IN_FORWARD and key ~= IN_BACK and key ~= IN_MOVELEFT and key ~= IN_MOVERIGHT then return end -- Not a key we're interested in

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() ) -- Otherwise spawn would cause infinite loop
		if wasAlive then -- We don't want to spawn them if they were already dead.
		    ULib.spawn( player, true ) -- Get out of spectate.
		end
		stopSpectate( player )
		player:SetPos( pos )
		player:SetAngles( ang )
	end
	hook.Add( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex(), unspectate, HOOK_MONITOR_LOW )

	local function disconnect( player ) -- We want to watch for spectator or target disconnect
		if player == target_ply or player == calling_ply then -- Target or spectator disconnecting
			unspectate( calling_ply, IN_FORWARD )
		end
	end
	hook.Add( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex(), disconnect, HOOK_MONITOR_HIGH )

	calling_ply:Spectate( OBS_MODE_IN_EYE )
	calling_ply:SpectateEntity( target_ply )
	calling_ply:StripWeapons() -- Otherwise they can use weapons while spectating

	ULib.tsay( calling_ply, "离开观众,向前走.", true )
	ulx.setExclusive( calling_ply, "旁观" )

	ulx.fancyLogAdmin( calling_ply, true, "#A 开始偷窥 #T", target_ply )
end
local spectate = ulx.command( CATEGORY_NAME, "ulx spectate", ulx.spectate, "!spectate", true )
spectate:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
spectate:defaultAccess( ULib.ACCESS_ADMIN )
spectate:help( "偷窥目标." )

function ulx.addForcedDownload( path )
	if ULib.fileIsDir( path ) then
		files = ULib.filesInDir( path )
		for _, v in ipairs( files ) do
			ulx.addForcedDownload( path .. "/" .. v )
		end
	elseif ULib.fileExists( path ) then
		resource.AddFile( path )
	else
		Msg( "[ULX] 错误:试图将不存在的或空的文件添加到强制下载 '" .. path .. "'\n" )
	end
end

function ulx.debuginfo( calling_ply )
	local str = string.format( "ULX 版本: %s\nULib 版本: %s\n", ULib.pluginVersionStr( "ULX" ), ULib.pluginVersionStr( "ULib" ) )
	str = str .. string.format( "游戏模式: %s\nMap: %s\n", GAMEMODE.Name, game.GetMap() )
	str = str .. "Dedicated server: " .. tostring( game.IsDedicated() ) .. "\n\n"

	local players = player.GetAll()
	str = str .. string.format( "当前连接的玩家:\nNick%s steamid%s uid%s id lsh\n", str.rep( " ", 27 ), str.rep( " ", 12 ), str.rep( " ", 7 ) )
	for _, ply in ipairs( players ) do
		local id = string.format( "%i", ply:EntIndex() )
		local steamid = ply:SteamID()
		local uid = tostring( ply:UniqueID() )
		local name = utf8.force( ply:Nick() )

		local plyline = name .. str.rep( " ", 32 - utf8.len( name ) ) -- Name
		plyline = plyline .. steamid .. str.rep( " ", 20 - steamid:len() ) -- Steamid
		plyline = plyline .. uid .. str.rep( " ", 11 - uid:len() ) -- Steamid
		plyline = plyline .. id .. str.rep( " ", 3 - id:len() ) -- id
		if ply:IsListenServerHost() then
			plyline = plyline .. "y	  "
		else
			plyline = plyline .. "n	  "
		end

		str = str .. plyline .. "\n"
	end

	local gmoddefault = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "settings/users.txt", true ), "//" ) ) or {}
	str = str .. "\n\nULib.ucl.users (#=" .. table.Count( ULib.ucl.users ) .. "):\n" .. ulx.dumpTable( ULib.ucl.users, 1 ) .. "\n\n"
	str = str .. "ULib.ucl.groups (#=" .. table.Count( ULib.ucl.groups ) .. "):\n" .. ulx.dumpTable( ULib.ucl.groups, 1 ) .. "\n\n"
	str = str .. "ULib.ucl.authed (#=" .. table.Count( ULib.ucl.authed ) .. "):\n" .. ulx.dumpTable( ULib.ucl.authed, 1 ) .. "\n\n"
	str = str .. "Garrysmod default file (#=" .. table.Count( gmoddefault ) .. "):\n" .. ulx.dumpTable( gmoddefault, 1 ) .. "\n\n"

	str = str .. "Active workshop addons on this server:\n"
	local addons = engine.GetAddons()
	for i=1, #addons do
		local addon = addons[i]
		if addon.mounted then
			local name = utf8.force( addon.title )
			str = str .. string.format( "%s%s workshop ID %s\n", name, str.rep( " ", 32 - utf8.len( name ) ), addon.file:gsub( "%D", "" ) )
		end
	end
	str = str .. "\n"

	str = str .. "Active legacy addons on this server:\n"
	local _, possibleaddons = file.Find( "addons/*", "GAME" )
	for _, addon in ipairs( possibleaddons ) do
		if not ULib.findInTable( {"checkers", "chess", "common", "go", "hearts", "spades"}, addon:lower() ) then -- Not sure what these addon folders are
			local name = addon
			local author, version, date
			if ULib.fileExists( "addons/" .. addon .. "/addon.txt" ) then
				local t = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "addons/" .. addon .. "/addon.txt" ), "//" ) )
				if t and t.AddonInfo then
					t = t.AddonInfo
					if t.name then name = t.name end
					if t.version then version = t.version end
					if tonumber( version ) then version = string.format( "%g", version ) end -- Removes innaccuracy in floating point numbers
					if t.author_name then author = t.author_name end
					if t.up_date then date = t.up_date end
				end
			end

			name = utf8.force( name )
			str = str .. name .. str.rep( " ", 32 - utf8.len( name ) )
			if author then
				str = string.format( "%s by %s%s", str, author, version and "," or "" )
			end

			if version then
				str = str .. " version " .. version
			end

			if date then
				str = string.format( "%s (%s)", str, date )
			end
			str = str .. "\n"
		end
	end

	ULib.fileWrite( "data/ulx/debugdump.txt", str )
	Msg( "Debug information written to garrysmod/data/ulx/debugdump.txt on server.\n" )
end
local debuginfo = ulx.command( CATEGORY_NAME, "ulx debuginfo", ulx.debuginfo )
debuginfo:help( "Dump some debug information." )

function ulx.resettodefaults( calling_ply, param )
	if param ~= "FORCE" then
		local str = "你确定吗?它将删除 ulx 创建的临时禁令,配置,组和一切!"
		local str2 = "如果您确定,请输入 \"ulx resettodefaults FORCE\""
		if calling_ply:IsValid() then
			ULib.tsayError( calling_ply, str, true )
			ULib.tsayError( calling_ply, str2, true )
		else
			Msg( str .. "\n" )
			Msg( str2 .. "\n" )
		end
		return
	end

	ULib.fileDelete( "data/ulx/adverts.txt" )
	ULib.fileDelete( "data/ulx/banreasons.txt" )
	ULib.fileDelete( "data/ulx/config.txt" )
	ULib.fileDelete( "data/ulx/downloads.txt" )
	ULib.fileDelete( "data/ulx/gimps.txt" )
	ULib.fileDelete( "data/ulx/sbox_limits.txt" )
	ULib.fileDelete( "data/ulx/votemaps.txt" )
	ULib.fileDelete( "data/ulib/bans.txt" )
	ULib.fileDelete( "data/ulib/groups.txt" )
	ULib.fileDelete( "data/ulib/misc_registered.txt" )
	ULib.fileDelete( "data/ulib/users.txt" )

	local str = "Please change levels to finish the reset"
	if calling_ply:IsValid() then
		ULib.tsayError( calling_ply, str, true )
	else
		Msg( str .. "\n" )
	end

	ulx.fancyLogAdmin( calling_ply, "#A 重置所有 ULX 和 ULib 配置" )
end
local resettodefaults = ulx.command( CATEGORY_NAME, "ulx resettodefaults", ulx.resettodefaults )
resettodefaults:addParam{ type=ULib.cmds.StringArg, ULib.cmds.optional }
resettodefaults:help( "重置所有 ULX 和 ULib 配置!" )

if SERVER then
	local ulx_kickAfterNameChanges = 			ulx.convar( "kickAfterNameChanges", "0", "<number> - 玩家每 ulx_kickAfterNameChangesCooldown 秒只能更改自己的名字 x 次. 0 禁用.", ULib.ACCESS_ADMIN )
	local ulx_kickAfterNameChangesCooldown = 	ulx.convar( "kickAfterNameChangesCooldown", "60", "<time> - 玩家可以每 x 秒更改他们的名字 ulx_kickAfterXNameChanges 次.", ULib.ACCESS_ADMIN )
	local ulx_kickAfterNameChangesWarning = 	ulx.convar( "kickAfterNameChangesWarning", "1", "<1/0> - 向用户显示警告,让他们知道他们可以再更改多少次姓名.", ULib.ACCESS_ADMIN )
	ulx.nameChangeTable = ulx.nameChangeTable or {}

	local function checkNameChangeLimit( ply, oldname, newname )
		local maxAttempts = ulx_kickAfterNameChanges:GetInt()
		local duration = ulx_kickAfterNameChangesCooldown:GetInt()
		local showWarning = ulx_kickAfterNameChangesWarning:GetInt()

		if maxAttempts ~= 0 then
			if not ulx.nameChangeTable[ply:SteamID()] then
				ulx.nameChangeTable[ply:SteamID()] = {}
			end

			for i=#ulx.nameChangeTable[ply:SteamID()], 1, -1 do
				if CurTime() - ulx.nameChangeTable[ply:SteamID()][i] > duration then
					table.remove( ulx.nameChangeTable[ply:SteamID()], i )
				end
			end

			table.insert( ulx.nameChangeTable[ply:SteamID()], CurTime() )

			local curAttempts = #ulx.nameChangeTable[ply:SteamID()]

			if curAttempts >= maxAttempts then
				ULib.kick( ply, "改名字太多次了" )
			else
				if showWarning == 1 then
					ULib.tsay( ply, "警告:您已更改姓名 " .. curAttempts .. " 超出 " .. maxAttempts .. " 时间" .. ( maxAttempts ~= 1 and "s" ) .. " in the past " .. duration .. " second" .. ( duration ~= 1 and "s" ) )
				end
			end
		end
	end
	hook.Add( "ULibPlayerNameChanged", "ULXCheckNameChangeLimit", checkNameChangeLimit )
end

--------------------
--	   Hooks	  --
--------------------
-- This cvar also exists in DarkRP (thanks, FPtje)
local cl_cvar_pickup = "cl_pickupplayers"
if CLIENT then CreateClientConVar( cl_cvar_pickup, "1", true, true ) end
local function playerPickup( ply, ent )
	local access, tag = ULib.ucl.query( ply, "ulx physgunplayer" )
	if ent:GetClass() == "player" and ULib.isSandbox() and access and not ent.NoNoclip and not ent.frozen and ply:GetInfoNum( cl_cvar_pickup, 1 ) == 1 then
		-- Extra restrictions! UCL wasn't designed to handle this sort of thing so we're putting it in by hand...
		local restrictions = {}
		ULib.cmds.PlayerArg.processRestrictions( restrictions, ply, {}, tag and ULib.splitArgs( tag )[ 1 ] )
		if restrictions.restrictedTargets == false or (restrictions.restrictedTargets and not table.HasValue( restrictions.restrictedTargets, ent )) then
			return
		end

		ent:SetMoveType( MOVETYPE_NONE ) -- So they don't bounce
		return true
	end
end
hook.Add( "PhysgunPickup", "ulxPlayerPickup", playerPickup, HOOK_HIGH ) -- Allow admins to move players. Call before the prop protection hook.
if SERVER then ULib.ucl.registerAccess( "ulx physgunplayer", ULib.ACCESS_ADMIN, "能够对其他玩家进行physgun", "其他" ) end

local function playerDrop( ply, ent )
	if ent:GetClass() == "player" then
		ent:SetMoveType( MOVETYPE_WALK )
	end
end
hook.Add( "PhysgunDrop", "ulxPlayerDrop", playerDrop )