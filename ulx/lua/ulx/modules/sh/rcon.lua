-- This module holds any type of remote execution functions (IE, 'dangerous')
local CATEGORY_NAME = "执行"

function ulx.rcon( calling_ply, command )
	ULib.consoleCommand( command .. "\n" )

	ulx.fancyLogAdmin( calling_ply, true, "#A 运行 rcon 命令: #s", command )
end
local rcon = ulx.command( CATEGORY_NAME, "ulx rcon", ulx.rcon, "!rcon", true, false, true )
rcon:addParam{ type=ULib.cmds.StringArg, hint="命令", ULib.cmds.takeRestOfLine }
rcon:defaultAccess( ULib.ACCESS_SUPERADMIN )
rcon:help( "在服务器控制台上执行命令." )

function ulx.luaRun( calling_ply, command )
	local return_results = false
	if command:sub( 1, 1 ) == "=" then
		command = "tmp_var" .. command
		return_results = true
	end

	RunString( command )

	if return_results then
		if type( tmp_var ) == "table" then
			ULib.console( calling_ply, "结果:" )
			local lines = ULib.explode( "\n", ulx.dumpTable( tmp_var ) )
			local chunk_size = 50
			for i=1, #lines, chunk_size do -- Break it up so we don't overflow the client
				ULib.queueFunctionCall( function()
					for j=i, math.min( i+chunk_size-1, #lines ) do
						ULib.console( calling_ply, lines[ j ]:gsub( "%%", "<p>" ) )
					end
				end )
			end
		else
			ULib.console( calling_ply, "结果: " .. tostring( tmp_var ):gsub( "%%", "<p>" ) )
		end
	end

	ulx.fancyLogAdmin( calling_ply, true, "#A 运行了: #s", command )
end
local luarun = ulx.command( CATEGORY_NAME, "ulx luarun", ulx.luaRun, nil, false, false, true )
luarun:addParam{ type=ULib.cmds.StringArg, hint="命令", ULib.cmds.takeRestOfLine }
luarun:defaultAccess( ULib.ACCESS_SUPERADMIN )
luarun:help( "在服务器控制台中执行 lua. (使用 '=' 输出）" )

function ulx.exec( calling_ply, config )
	if string.sub( config, -4 ) ~= ".cfg" then config = config .. ".cfg" end
	if not ULib.fileExists( "cfg/" .. config ) then
		ULib.tsayError( calling_ply, "该配置不存在!", true )
		return
	end

	ULib.execFile( "cfg/" .. config )
	ulx.fancyLogAdmin( calling_ply, "#A 执行文件 #s", config )
end
local exec = ulx.command( CATEGORY_NAME, "ulx exec", ulx.exec, nil, false, false, true )
exec:addParam{ type=ULib.cmds.StringArg, hint="文件" }
exec:defaultAccess( ULib.ACCESS_SUPERADMIN )
exec:help( "让服务器执行cfg文件" )

function ulx.cexec( calling_ply, target_plys, command )
	for _, v in ipairs( target_plys ) do
		v:ConCommand( command )
	end

	ulx.fancyLogAdmin( calling_ply, "#A 在 #T 上运行 #s", command, target_plys )
end
local cexec = ulx.command( CATEGORY_NAME, "ulx cexec", ulx.cexec, "!cexec", false, false, true )
cexec:addParam{ type=ULib.cmds.PlayersArg }
cexec:addParam{ type=ULib.cmds.StringArg, hint="命令", ULib.cmds.takeRestOfLine }
cexec:defaultAccess( ULib.ACCESS_SUPERADMIN )
cexec:help( "在目标的控制台上运行命令." )

function ulx.ent( calling_ply, classname, params )
	if not calling_ply:IsValid() then
		Msg( "无法从专用服务器控制台创建实体.\n" )
		return
	end

	classname = classname:lower()
	newEnt = ents.Create( classname )

	-- Make sure it's a valid ent
	if not newEnt or not newEnt:IsValid() then
		ULib.tsayError( calling_ply, "未知实体类型 (" .. classname .. "), 中止.", true )
		return
	end

	local trace = calling_ply:GetEyeTrace()
	local vector = trace.HitPos
	vector.z = vector.z + 20

	newEnt:SetPos( vector ) -- Note that the position can be overridden by the user's flags

	params:gsub( "([^|:\"]+)\"?:\"?([^|]+)", function( key, value )
		key = key:Trim()
		value = value:Trim()
		newEnt:SetKeyValue( key, value )
	end )

	newEnt:Spawn()
	newEnt:Activate()

	undo.Create( "ulx_ent" )
		undo.AddEntity( newEnt )
		undo.SetPlayer( calling_ply )
	undo.Finish()

	if not params or params == "" then
		ulx.fancyLogAdmin( calling_ply, "#A 创建了一个实体： #s", classname )
	else
		ulx.fancyLogAdmin( calling_ply, "#A 创建了一个实体： #s ，额外代码 #s", classname, params )
	end
end
local ent = ulx.command( CATEGORY_NAME, "ulx ent", ulx.ent )
ent:addParam{ type=ULib.cmds.StringArg, hint="种类名" }
ent:addParam{ type=ULib.cmds.StringArg, hint="<flag>:<数值>", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
ent:defaultAccess( ULib.ACCESS_SUPERADMIN )
ent:help( "创建一个实体， separate flag and value with ':'。" )