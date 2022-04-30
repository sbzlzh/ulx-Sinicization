map_reload = map_reload or {}
util.AddNetworkString( "map_reload" )

local function DoReload()
	game.ConsoleCommand( 'changelevel "'..game.GetMap()..'"\n' )
end

local function callback( ply, cmd, args )
	if not IsValid( ply ) or ply:IsSuperAdmin() then
		local delay = tonumber( args[1] ) or 10
		if delay==0 then -- now
			DoReload()
		elseif delay>0 then -- delayed
			timer.Create( "map_reload", delay, 1, DoReload )
			PrintMessage( HUD_PRINTCENTER, "The map will be reloaded in "..delay.." seconds!" )
			map_reload.RestartTime = RealTime()+delay
			net.Start( "map_reload" )
				net.WriteFloat( delay )
			net.Broadcast()
			if delay>10 then
				timer.Create( "map_reload_LastWarning", delay-5, 1, function()
					PrintMessage( HUD_PRINTCENTER, "地图将在5秒内重新加载!" )
				end )
			end
		else -- cancel
			map_reload.RestartTime = nil
			timer.Remove( "map_reload" )
			PrintMessage( HUD_PRINTCENTER, "地图重新加载已取消!" )
			net.Start( "map_reload" )
				net.WriteFloat( -1 )
			net.Broadcast()
			timer.Remove( "map_reload_LastWarning" )
		end
	end
end
concommand.Add( "map_reload", callback, nil, "map_reload [delay=10]\n   Reload the map in {delay} seconds\n   To cancel a pending map reload, type: map_reload -1" )
util.AddNetworkString( "map_reload" )
net.Receive( "map_reload", function( len, ply )
	callback( ply, nil, {net.ReadFloat()} )
end )
