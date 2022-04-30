map_reload = map_reload or {}

local function callback( ply, cmd, args )
	if IsValid( ply ) and ply:IsSuperAdmin() then
		net.Start( "map_reload" )
			net.WriteFloat( tonumber( args[1] ) or 10 )
		net.SendToServer()
	else
		MsgN( "您需要成为超级管理员才能重新加载地图!" )
	end
end

concommand.Add( "map_reload", callback, nil, "map_reload [delay=10]\n   Reload the map in {delay} seconds\n   To cancel a pending map reload, type: map_reload -1" )

net.Receive( "map_reload", function()
	local delay = net.ReadFloat()
	if delay>0 then
		map_reload.timeout = RealTime()+delay
	else
		map_reload.timeout = nil
	end
end )

do
	surface.CreateFont( "sv_restart_title", {
		size=16,
		weight=750,
		antialias=false,
		additive=false,
		outline=true,
	} )
	surface.CreateFont( "sv_restart_time", {
		size=29,
		antialias=true,
		additive=false,
		outline=true,
	} )
	local hud_x = ScrW()*0.6667
	local title = "Map Reload"
	local title_w = 0
	local time = 0
	local time_w = 0
	local hud_w = 0
	local bg = Color( 0,0,0,128 )
	hook.Add( "HUDPaintBackground", "map_reload", function()
		if map_reload.timeout then
			hud_x = ScrW()*0.6667
			surface.SetFont( "sv_restart_title" )
			title_w = surface.GetTextSize( title )
			time = math.floor( map_reload.timeout-RealTime() )
			surface.SetFont( "sv_restart_time" )
			time_w = surface.GetTextSize( time )
			hud_w = math.max( title_w+4, time_w+6 )
			draw.RoundedBoxEx( 0, hud_x,0, hud_w,50, bg )
		end
	end )
	hook.Add( "HUDPaint", "map_reload", function()
		if map_reload.timeout then
			surface.SetFont( "sv_restart_title" )
			surface.SetTextColor( 255,207,159 )
			surface.SetTextPos( hud_x+( ( hud_w-title_w )/2 ), 2 )
			surface.DrawText( title )
			surface.SetFont( "sv_restart_time" )
			surface.SetTextColor( 255,255,255 )
			surface.SetTextPos( hud_x+( ( hud_w-time_w )/2 ), 20 )
			surface.DrawText( time )
		end
	end )
end
