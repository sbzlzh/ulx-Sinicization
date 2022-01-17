local ulxBuildNumURL = ulx.release and "https://teamulysses.github.io/ulx/ulx.build" or "https://raw.githubusercontent.com/TeamUlysses/ulx/master/ulx.build"
ULib.registerPlugin{
	Name          = "ULX",
	Version       = string.format( "%.2f", ulx.version ),
	IsRelease     = ulx.release,
	Author        = "Team Ulysses",
	URL           = "http://ulyssesmod.net",
	WorkshopID    = 557962280,
	BuildNumLocal         = tonumber(ULib.fileRead( "ulx.build" )),
	BuildNumRemoteURL      = ulxBuildNumURL,
	--BuildNumRemoteReceivedCallback = nil
}

function ulx.getVersion() -- This function will be removed in the future
	return ULib.pluginVersionStr( "ULX" )
end

local ulxCommand = inheritsFrom( ULib.cmds.TranslateCommand )

function ulxCommand:logString( str )
	Msg( "警告: <ulx command>:logString() 被调用,这个函数正在被淘汰!\n" )
end

function ulxCommand:oppositeLogString( str )
	Msg( "警告: <ulx command>:oppositeLogString() 被调用,这个函数正在被淘汰!\n" )
end

function ulxCommand:help( str )
	self.helpStr = str
end

function ulxCommand:getUsage( ply )
	local str = self:superClass().getUsage( self, ply )

	if self.helpStr or self.say_cmd or self.opposite then
		str = str:Trim() .. " - "
		if self.helpStr then
			str = str .. self.helpStr
		end
		if self.helpStr and self.say_cmd then
			str = str .. " "
		end
		if self.say_cmd then
			str = str .. "(say: " .. self.say_cmd[1] .. ")"
		end
		if self.opposite and (self.helpStr or self.say_cmd) then
			str = str .. " "
		end
		if self.opposite then
			str = str .. "(opposite: " .. self.opposite .. ")"
		end
	end

	return str
end

ulx.cmdsByCategory = ulx.cmdsByCategory or {}
function ulx.command( category, command, fn, say_cmd, hide_say, nospace, unsafe )
	if type( say_cmd ) == "string" then say_cmd = { say_cmd } end
	local obj = ulxCommand( command, fn, say_cmd, hide_say, nospace, unsafe )
	obj:addParam{ type=ULib.cmds.CallingPlayerArg }
	ulx.cmdsByCategory[ category ] = ulx.cmdsByCategory[ category ] or {}
	for cat, cmds in pairs( ulx.cmdsByCategory ) do
		for i=1, #cmds do
			if cmds[i].cmd == command then
				table.remove( ulx.cmdsByCategory[ cat ], i )
				break
			end
		end
	end
	table.insert( ulx.cmdsByCategory[ category ], obj )
	obj.category = category
	obj.say_cmd = say_cmd
	obj.hide_say = hide_say
	return obj
end

local function cc_ulx( ply, command, argv )
	local argn = #argv

	if argn == 0 then
		ULib.console( ply, "没有输入命令.如果您需要帮助,请在您的控制台中输入'ulx help'." )
	else
		-- TODO, need to make this cvar hack actual commands for sanity and autocomplete
		-- First, check if this is a cvar and they just want the value of the cvar
		local cvar = ulx.cvars[ argv[ 1 ]:lower() ]
		if cvar and not argv[ 2 ] then
			ULib.console( ply, "\"ulx " .. argv[ 1 ] .. "\" = \"" .. GetConVarString( "ulx_" .. cvar.cvar ) .. "\"" )
			if cvar.help and cvar.help ~= "" then
				ULib.console( ply, cvar.help .. "\n  ULX 生成的 CVAR" )
			else
				ULib.console( ply, "  ULX 生成的 CVAR" )
			end
			return
		elseif cvar then -- Second, check if this is a cvar and they specified a value
			local args = table.concat( argv, " ", 2, argn )
			if ply:IsValid() then
				-- Workaround: gmod seems to choke on '%' when sending commands to players.
				-- But it's only the '%', or we'd use ULib.makePatternSafe instead of this.
				ply:ConCommand( "ulx_" .. cvar.cvar .. " \"" .. args:gsub( "(%%)", "%%%1" ) .. "\"" )
			else
				cvar.obj:SetString( argv[ 2 ] )
			end
			return
		end
		ULib.console( ply, "输入的命令无效.如果您需要帮助,请在您的控制台中输入'ulx help'." )
	end
end
ULib.cmds.addCommand( "ulx", cc_ulx )

function ulx.help( ply )
	ULib.console( ply, "ULX 帮助:" )
	ULib.console( ply, "如果一个命令可以接受多个目标,它通常会让你使用关键字'*'作为目标" )
	ULib.console( ply, "全部,'^' 用于定位您自己,'@' 用于定位您的选择器,'$<userid>' 用于按 ID 定位 (steamid," )
	ULib.console( ply, "uniqueid, userid, ip),'#<group>' 以特定组中的用户为目标,'%<group>' 为目标" )
	ULib.console( ply, "有权访问组的用户(继承计数). IE, ulx slap #user slaps 所有玩家" )
	ULib.console( ply, "在默认访客访问组中.这些关键字中的任何一个都可以以'!'开头否定它." )
	ULib.console( ply, "EG,ulx slap！^ 除了你之外的所有人." )
	ULib.console( ply, "您还可以用逗号分隔多个目标. IE,ulx slap bob,jeff,henry.")
	ULib.console( ply, "所有命令必须以 \"ulx \", ie \"ulx slap\"" )
	ULib.console( ply, "\n命令帮助:\n" )

	for category, cmds in pairs( ulx.cmdsByCategory ) do
		local lines = {}
		for _, cmd in ipairs( cmds ) do
			local tag = cmd.cmd
			if cmd.manual then tag = cmd.access_tag end
			if ULib.ucl.query( ply, tag ) then
				local usage
				if not cmd.manual then
					usage = cmd:getUsage( ply )
				else
					usage = cmd.helpStr
				end
				table.insert( lines, string.format( "\to %s %s", cmd.cmd, usage:Trim() ) )
			end
		end

		if #lines > 0 then
			table.sort( lines )
			ULib.console( ply, "\nCategory: " .. category )
			for _, line in ipairs( lines ) do
				ULib.console( ply, line )
			end
			ULib.console( ply, "" ) -- New line
		end
	end


	ULib.console( ply, "\n-帮助结束\nULX 版本: " .. ULib.pluginVersionStr( "ULX" ) .. "\n" )
end
local help = ulx.command( "功用", "ulx help", ulx.help )
help:help( "显示此帮助." )
help:defaultAccess( ULib.ACCESS_ALL )

function ulx.dumpTable( t, indent, done )
	done = done or {}
	indent = indent or 0
	local str = ""

	for k, v in pairs( t ) do
		str = str .. string.rep( "\t", indent )

		if type( v ) == "table" and not done[ v ] then
			done[ v ] = true
			str = str .. tostring( k ) .. ":" .. "\n"
			str = str .. ulx.dumpTable( v, indent + 1, done )

		else
			str = str .. tostring( k ) .. "\t=\t" .. tostring( v ) .. "\n"
		end
	end

	return str
end

function ulx.uteamEnabled()
	return ULib.isSandbox() and GAMEMODE.Name ~= "DarkRP"
end
