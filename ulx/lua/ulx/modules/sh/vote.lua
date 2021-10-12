local CATEGORY_NAME = "投票"

---------------
--Public vote--
---------------
if SERVER then ulx.convar( "voteEcho", "0", _, ULib.ACCESS_SUPERADMIN ) end -- Echo votes?

if SERVER then
	util.AddNetworkString( "ulx_vote" )
end
-- First, our helper function to make voting so much easier!
function ulx.doVote( title, options, callback, timeout, filter, noecho, ... )
	timeout = timeout or 20
	if ulx.voteInProgress then
		Msg( "错误! ULX 试图在另一次投票正在进行时开始投票!\n" )
		return false
	end

	if not options[ 1 ] or not options[ 2 ] then
		Msg( "错误! ULX 试图在没有至少两个选项的情况下开始投票!\n" )
		return false
	end

	local voters = 0
	local rp = RecipientFilter()
	if not filter then
		rp:AddAllPlayers()
		voters = #player.GetAll()
	else
		for _, ply in ipairs( filter ) do
			rp:AddPlayer( ply )
			voters = voters + 1
		end
	end
	
	
	net.Start("ulx_vote")
		net.WriteString( title )
		net.WriteInt( timeout, 16 )
		net.WriteTable( options )
	net.Broadcast()
	

	ulx.voteInProgress = { callback=callback, options=options, title=title, results={}, voters=voters, votes=0, noecho=noecho, args={...} }

	timer.Create( "ULXVoteTimeout", timeout, 1, ulx.voteDone )

	return true
end

function ulx.voteCallback( ply, command, argv )
	if not ulx.voteInProgress then
		ULib.tsayError( ply, "没有正在进行的投票" )
		return
	end

	if not argv[ 1 ] or not tonumber( argv[ 1 ] ) or not ulx.voteInProgress.options[ tonumber( argv[ 1 ] ) ] then
		ULib.tsayError( ply, "无效或超出范围的投票." )
		return
	end

	if ply.ulxVoted then
		ULib.tsayError( ply, "你已经投过票!" )
		return
	end

	local echo = ULib.toBool( GetConVarNumber( "ulx_voteEcho" ) )
	local id = tonumber( argv[ 1 ] )
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] or 0
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] + 1

	ulx.voteInProgress.votes = ulx.voteInProgress.votes + 1

	ply.ulxVoted = true -- Tag them as having voted

	local str = ply:Nick() .. " 投票赞成: " .. ulx.voteInProgress.options[ id ]
	if echo and not ulx.voteInProgress.noecho then
		ULib.tsay( _, str ) -- TODO, color?
	end
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end

	if ulx.voteInProgress.votes >= ulx.voteInProgress.voters then
		ulx.voteDone()
	end
end
if SERVER then concommand.Add( "ulx_vote", ulx.voteCallback ) end

function ulx.voteDone( cancelled )
	local players = player.GetAll()
	for _, ply in ipairs( players ) do -- Clear voting tags
		ply.ulxVoted = nil
	end

	local vip = ulx.voteInProgress
	ulx.voteInProgress = nil
	timer.Remove( "ULXVoteTimeout" )
	if not cancelled then
		ULib.pcallError( vip.callback, vip, unpack( vip.args, 1, 10 ) ) -- Unpack is explicit in length to avoid odd LuaJIT quirk.
	end
end
-- End our helper functions





local function voteDone( t )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local str
	if not winner then
		str = "投票结果:没有选项获胜,因为没有人投票!"
	else
		str = "投票结果:选项 '" .. t.options[ winner ] .. "' 票胜利. (" .. winnernum .. "/" .. t.voters .. ")"
	end
	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.vote( calling_ply, title, ... )
	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "已经有投票正在进行中.请等待当前的结束.", true )
		return
	end

	ulx.doVote( title, { ... }, voteDone )
	ulx.fancyLogAdmin( calling_ply, "#A started a vote (#s)", title )
end
local vote = ulx.command( CATEGORY_NAME, "ulx vote", ulx.vote, "!vote" )
vote:addParam{ type=ULib.cmds.StringArg, hint="title" }
vote:addParam{ type=ULib.cmds.StringArg, hint="options", ULib.cmds.takeRestOfLine, repeat_min=2, repeat_max=10 }
vote:defaultAccess( ULib.ACCESS_ADMIN )
vote:help( "Starts a public vote." )

-- Stop a vote in progress
function ulx.stopVote( calling_ply )
	if not ulx.voteInProgress then
		ULib.tsayError( calling_ply, "目前没有正在进行的投票.", true )
		return
	end

	ulx.voteDone( true )
	ulx.fancyLogAdmin( calling_ply, "#A 已停止当前投票." )
end
local stopvote = ulx.command( CATEGORY_NAME, "ulx stopvote", ulx.stopVote, "!stopvote" )
stopvote:defaultAccess( ULib.ACCESS_SUPERADMIN )
stopvote:help( "停止正在进行的投票." )

local function voteMapDone2( t, changeTo, ply )
	local shouldChange = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logServAct( ply, "#A 批准投票地图" )
		shouldChange = true
	else
		ulx.logServAct( ply, "#A 拒绝投票地图" )
	end

	if shouldChange then
		ULib.consoleCommand( "更改级别 " .. changeTo .. "\n" )
	end
end

local function voteMapDone( t, argv, ply )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votemap2Successratio" )
	local minVotes = GetConVarNumber( "ulx_votemap2Minvotes" )
	local str
	local changeTo
	-- Figure out the map to change to, if we're changing
	if #argv > 1 then
		changeTo = t.options[ winner ]
	else
		changeTo = argv[ 1 ]
	end

	if (#argv < 2 and winner ~= 1) or not winner or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "投票结果:投票失败."
	elseif ply:IsValid() then
		str = "投票结果:选项 '" .. t.options[ winner ] .. "' 赢了,变更地图待批准. (" .. winnernum .. "/" .. t.voters .. ")"

		ulx.doVote( "接受结果并将映射更改为 " .. changeTo .. "?", { "是", "否" }, voteMapDone2, 30000, { ply }, true, changeTo, ply )
	else -- It's the server console, let's roll with it
		str = "投票结果:选项 '" .. t.options[ winner ] .. "' 赢了. (" .. winnernum .. "/" .. t.voters .. ")"
		ULib.tsay( _, str )
		ulx.logString( str )
		ULib.consoleCommand( "更改级别 " .. changeTo .. "\n" )
		return
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end
end

function ulx.votemap2( calling_ply, ... )
	local argv = { ... }

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "已经有投票正在进行中.请等待当前的结束.", true )
		return
	end

	for i=2, #argv do
	    if ULib.findInTable( argv, argv[ i ], 1, i-1 ) then
	        ULib.tsayError( calling_ply, "地图 " .. argv[ i ] .. " 被列出两次.请再试一次" )
	        return
	    end
	end

	if #argv > 1 then
		ulx.doVote( "将地图更改为..", argv, voteMapDone, _, _, _, argv, calling_ply )
		ulx.fancyLogAdmin( calling_ply, "#A 开始了一个带有选项的投票地图" .. string.rep( " #s", #argv ), ... )
	else
		ulx.doVote( "将地图更改为 " .. argv[ 1 ] .. "?", { "是", "否" }, voteMapDone, _, _, _, argv, calling_ply )
		ulx.fancyLogAdmin( calling_ply, "#A 开始投票地图 #s", argv[ 1 ] )
	end
end
local votemap2 = ulx.command( CATEGORY_NAME, "ulx votemap2", ulx.votemap2, "!votemap2" )
votemap2:addParam{ type=ULib.cmds.StringArg, completes=ulx.maps, hint="map", error="无效的地图 \"%s\" 指定的", ULib.cmds.restrictToCompletes, ULib.cmds.takeRestOfLine, repeat_min=1, repeat_max=10 }
votemap2:defaultAccess( ULib.ACCESS_ADMIN )
votemap2:help( "开始公共地图投票." )
if SERVER then ulx.convar( "votemap2Successratio", "0.5", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votemap2 to succeed
if SERVER then ulx.convar( "votemap2Minvotes", "3", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votemap2



local function voteKickDone2( t, target, time, ply, reason )
	local shouldKick = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logUserAct( ply, target, "#A 批准了踢出票 #T (" .. (reason or "") .. ")" )
		shouldKick = true
	else
		ulx.logUserAct( ply, target, "#A 否决了踢出票 #T" )
	end

	if shouldKick then
		if reason and reason ~= "" then
			ULib.kick( target, "投票踢出成功. (" .. reason .. ")" )
		else
			ULib.kick( target, "投票踢出成功." )
		end
	end
end

local function voteKickDone( t, target, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votekickSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votekickMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be kicked. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		if not target:IsValid() then
			str = "投票结果:用户投票被踢，但已经离开."
		elseif ply:IsValid() then
			str = "投票结果:用户现在将被踢出,等待批准. (" .. winnernum .. "/" .. t.voters .. ")"
			ulx.doVote( "接受结果并踢 " .. target:Nick() .. "?", { "是", "否" }, voteKickDone2, 30000, { ply }, true, target, time, ply, reason )
		else -- Vote from server console, roll with it
			str = "投票结果:用户现在将被踢. (" .. winnernum .. "/" .. t.voters .. ")"
			ULib.kick( target, "投票踢出成功." )
		end
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end
end

function ulx.votekick( calling_ply, target_ply, reason )
	if target_ply:IsListenServerHost() then
		ULib.tsayError( calling_ply, "该玩家免疫踢", true )
		return
	end

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "已经有投票正在进行中.请等待当前的结束.", true )
		return
	end

	local msg = "踢 " .. target_ply:Nick() .. "?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "是", "否" }, voteKickDone, _, _, _, target_ply, time, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A 开始投票踢出 #T (#s)", target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A 开始投票踢出 #T", target_ply )
	end
end
local votekick = ulx.command( CATEGORY_NAME, "ulx votekick", ulx.votekick, "!votekick" )
votekick:addParam{ type=ULib.cmds.PlayerArg }
votekick:addParam{ type=ULib.cmds.StringArg, hint="原因", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
votekick:defaultAccess( ULib.ACCESS_ADMIN )
votekick:help( "开始公众投票踢出目标." )
if SERVER then ulx.convar( "votekickSuccessratio", "0.6", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votekick to succeed
if SERVER then ulx.convar( "votekickMinvotes", "2", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votekick



local function voteBanDone2( t, nick, steamid, time, ply, reason )
	local shouldBan = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.fancyLogAdmin( ply, "#A 批准了封禁票 #s (#s 分钟) (#s))", nick, time, reason or "" )
		shouldBan = true
	else
		ulx.fancyLogAdmin( ply, "#A 否决了封禁票 #s", nick )
	end

	if shouldBan then
		ULib.addBan( steamid, time, reason, nick, ply )
	end
end

local function voteBanDone( t, nick, steamid, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votebanSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votebanMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "投票结果：用户不会被封禁. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		reason = ("[ULX 投票封禁] " .. (reason or "")):Trim()
		if ply:IsValid() then
			str = "投票结果:用户现在将被禁封禁,等待批准. (" .. winnernum .. "/" .. t.voters .. ")"
			ulx.doVote( "接受结果并封禁 " .. nick .. "?", { "是", "否" }, voteBanDone2, 30000, { ply }, true, nick, steamid, time, ply, reason )
		else -- Vote from server console, roll with it
			str = "投票结果:用户现在将被封禁. (" .. winnernum .. "/" .. t.voters .. ")"
			ULib.addBan( steamid, time, reason, nick, ply )
		end
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.voteban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError( calling_ply, "该玩家免疫封禁", true )
		return
	end

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "已经有投票正在进行中.请等待当前的结束.", true )
		return
	end

	local msg = "Ban " .. target_ply:Nick() .. " for " .. minutes .. " minutes?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "是", "否" }, voteBanDone, _, _, _, target_ply:Nick(), target_ply:SteamID(), minutes, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A 开始对 #T（#s）进行 #i 分钟的投票封禁", minutes, target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A 开始对 #T 进行 #i 分钟的投票封禁", minutes, target_ply )
	end
end
local voteban = ulx.command( CATEGORY_NAME, "ulx voteban", ulx.voteban, "!voteban" )
voteban:addParam{ type=ULib.cmds.PlayerArg }
voteban:addParam{ type=ULib.cmds.NumArg, min=0, default=1440, hint="分钟", ULib.cmds.allowTimeString, ULib.cmds.optional }
voteban:addParam{ type=ULib.cmds.StringArg, hint="原因", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
voteban:defaultAccess( ULib.ACCESS_ADMIN )
voteban:help( "开始对目标进行公开封禁投票." )
if SERVER then ulx.convar( "votebanSuccessratio", "0.7", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a voteban to succeed
if SERVER then ulx.convar( "votebanMinvotes", "3", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for voteban

-- Our regular votemap command
local votemap = ulx.command( CATEGORY_NAME, "ulx votemap", ulx.votemap, "!votemap" )
votemap:addParam{ type=ULib.cmds.StringArg, completes=ulx.votemaps, hint="地图", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
votemap:defaultAccess( ULib.ACCESS_ALL )
votemap:help( "投票给地图,没有参数列出可用的地图." )

-- Our veto command
local veto = ulx.command( CATEGORY_NAME, "ulx veto", ulx.votemapVeto, "!veto" )
veto:defaultAccess( ULib.ACCESS_ADMIN )
veto:help( "否决成功的投票地图." )
