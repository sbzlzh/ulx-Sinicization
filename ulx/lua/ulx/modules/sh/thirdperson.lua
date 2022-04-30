if (CLIENT) then
	local enabled = false;
	concommand.Add("thirdperson_toggle", function ()
		enabled = !enabled;
		if (enabled) then
			chat.AddText(Color(162, 255, 162), "开启第三人称模式.");
		else
			chat.AddText(Color(255, 162, 162), "禁用第三人称模式.");
		end
	end);
	hook.Add("ShouldDrawLocalPlayer", "ThirdPersonDrawPlayer", function ()
		if (enabled && LocalPlayer():Alive()) then
			return true;
		end
	end);
	hook.Add("CalcView", "ThirdPersonView", function (ply, pos, ang, fov, madeByZero)
		if (enabled && IsValid(ply) && ply:Alive()) then
			if (IsValid(ply:GetActiveWeapon())) then
				ply:GetActiveWeapon().AccurateCrosshair = true;
			end
			local view = {};
			view.origin = (pos - (ang:Forward() * 70) + (ang:Right() * 20) + (ang:Up() * 5));
			view.ang = (ply:EyeAngles() + Angle(1, 1, 0));
			local TrD = {}
			TrD.start = (ply:EyePos())
			TrD.endpos = (TrD.start + (ang:Forward() * - 100) + (ang:Right() * 25) + (ang:Up() * 10));
			TrD.filter = ply;
			local trace = util.TraceLine(TrD);
			pos = trace.HitPos;
			if (trace.Fraction < 1) then
				pos = pos + trace.HitNormal * 5;
			end
			view.origin = pos;
			view.fov = fov;
			return GAMEMODE:CalcView(ply, view.origin, view.ang, view.fov);
		end
	end);
end
function ulx.thirdperson(calling_ply)
	calling_ply:SendLua([[RunConsoleCommand("thirdperson_toggle")]]);
end
local thirdperson = ulx.command("功用", "ulx thirdperson", ulx.thirdperson, {"!3p", "!thirdperson"}, true);
thirdperson:defaultAccess(ULib.ACCESS_ADMIN);
thirdperson:help("切换第三人称模式.");