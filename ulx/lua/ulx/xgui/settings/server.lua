--Server settings module for ULX GUI -- by Stickly Man!
--A settings module for modifying server and ULX based settings. Also has the base code for loading the server settings modules.

local server = xlib.makepanel{ parent=xgui.null }

--------------------------GMOD 设置--------------------------
xlib.makecheckbox{ x=10, y=10, label="启用语音聊天", repconvar="rep_sv_voiceenable", parent=server }
xlib.makelabel{ x=10, y=33, label="全局设置设置:", parent=server }
xlib.makecombobox{ x=10, y=50, w=120, repconvar="rep_sv_alltalk", isNumberConvar=true, choices={ "您身边的团队", "仅限团队", "你身边的每一个人", "每个人" }, parent=server }
xlib.makecheckbox{ x=10, y=75, label="禁用 AI", repconvar="rep_ai_disabled", parent=server }
xlib.makecheckbox{ x=10, y=95, label="AI忽略玩家", repconvar="rep_ai_ignoreplayers", parent=server }
local offset = 0
if game.SinglePlayer() then
	offset = 20
	xlib.makecheckbox{ x=10, y=115, label="保持 AI 布娃娃", repconvar="rep_ai_keepragdolls", parent=server }
end
xlib.makelabel{ x=10, y=120+offset, label="sv_gravity", parent=server }
xlib.makeslider{ x=10, y=135+offset, label="<--->", w=125, min=-1000, max=1000, repconvar="rep_sv_gravity", parent=server }
xlib.makelabel{ x=10, y=165+offset, label="phys_timescale", parent=server }
xlib.makeslider{ x=10, y=180+offset, label="<--->", w=125, min=0, max=4, decimal=2, repconvar="rep_phys_timescale", parent=server }

------------------------ULX 类别菜单------------------------
server.mask = xlib.makepanel{ x=295, y=5, w=290, h=322, parent=server }
server.panel = xlib.makepanel{ x=5, w=285, h=322, parent=server.mask }

server.catList = xlib.makelistview{ x=145, y=5, w=150, h=322, parent=server }
server.catList:AddColumn( "服务器设置模块" )
server.catList.Columns[1].DoClick = function() end
server.catList.OnRowSelected = function( self, LineID, Line )
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel
	if nPanel ~= server.curPanel then
		if server.curPanel then
			local temppanel = server.curPanel
			--Close before opening new one
			xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=5, starty=0, endx=-285, endy=0, setvisible=false } )
			xlib.addToAnimQueue( function()	temppanel:SetVisible( false ) end )
		end
		--Open
		server.curPanel = nPanel
		xlib.addToAnimQueue( function() nPanel:SetVisible( true ) end )
		if nPanel.onOpen then xlib.addToAnimQueue( nPanel.onOpen ) end --If the panel has it, call a function when it's opened
		xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=-285, starty=0, endx=5, endy=0, setvisible=true } )
	else
		--Close
		server.curPanel = nil
		self:ClearSelection()
		xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=5, starty=0, endx=-285, endy=0, setvisible=false } )
		xlib.addToAnimQueue( function() nPanel:SetVisible( false ) end )
	end
	xlib.animQueue_start()
end

function xgui.openServerModule( name )
	name = string.lower( name )
	for i = 1, #xgui.modules.submodule do
		local module = xgui.modules.submodule[i]
		if module.mtype == "server" and string.lower(module.name) == name then
			if module.panel ~= server.curPanel then
				server.catList:ClearSelection()
				for i=1, #server.catList.Lines do
					local line = server.catList.Lines[i]
					if string.lower(line:GetColumnText(1)) == name then
						server.catList:SelectItem( line )
						break
					end
				end
			end
			break
		end
	end
end

--流程模块化设置
function server.processModules()
	server.catList:Clear()
	for i, module in ipairs( xgui.modules.submodule ) do
		if module.mtype == "server" and ( not module.access or LocalPlayer():query( module.access ) ) then
			local w,h = module.panel:GetSize()
			if w == h and h == 0 then module.panel:SetSize( 275, 322 ) end

			if module.panel.scroll then --For DListLayouts
				module.panel.scroll.panel = module.panel
				module.panel = module.panel.scroll
			end
			module.panel:SetParent( server.panel )

			local line = server.catList:AddLine( module.name, i )
			if ( module.panel == server.curPanel ) then
				server.curPanel = nil
				server.catList:SelectItem( line )
			else
				module.panel:SetVisible( false )
			end
		end
	end
	server.catList:SortByColumn( 1, false )
end
server.processModules()

xgui.hookEvent( "onProcessModules", nil, server.processModules, "serverSettingsProcessModules" )
xgui.addSettingModule( "Server", server, "icon16/server.png", "xgui_svsettings" )


---------------------------
--服务器设置模块--
---------------------------
--These are submodules that load into the server settings module above.

-------------------------管理员投票地图--------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="管理员投票地图设置" } )
plist:Add( xlib.makelabel{ label="接受地图更改所需的投票率" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votemap2Successratio" } )
plist:Add( xlib.makelabel{ label="成功更改地图的最低投票数" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votemap2Minvotes" } )
xgui.addSubModule( "ULX 管理员投票地图", plist, nil, "server" )

-----------------------------广告-----------------------------
xgui.prepareDataType( "adverts" )
local adverts = xlib.makepanel{ parent=xgui.null }
adverts.tree = xlib.maketree{ w=120, h=296, parent=adverts }
adverts.tree.DoClick = function( self, node )
	adverts.removebutton:SetDisabled( false )
	adverts.updatebutton:SetDisabled( not node.data )
	adverts.nodeup:SetDisabled( not node.data or type( node.group ) == "number" )
	adverts.nodedown:SetDisabled( not node.data or not type( node.group ) == "number" or adverts.isBottomNode( node ) )
	adverts.group:SetText( type(node.group) ~= "number" and node.group or "<No Group>" )
	if node.data then
		adverts.message:SetText( node.data.message )
		adverts.time:SetValue( node.data.rpt )
		adverts.color:SetColor( node.data.color )
		adverts.csay:SetOpen( node.data.len )
		adverts.csay:InvalidateLayout()
		adverts.display:SetValue( node.data.len or 10 )
	end
end
function adverts.isBottomNode( node )
	local parentnode = node:GetParentNode()
	local parentchildren = parentnode.ChildNodes:GetChildren()

	if parentnode:GetParentNode().ChildNodes then --Is node within a subgroup?
		local parentparentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		return parentchildren[#parentchildren] == node and parentparentchildren[#parentparentchildren] == parentnode
	else
		return not adverts.hasGroups or parentchildren[#parentchildren] == node
	end
end
--0 middle, 1 bottom, 2 top, 3 top and bottom
function adverts.getNodePos( node )
	if type( node.group ) == "number" then return 1 end
	local parentchildren = node:GetParentNode().ChildNodes:GetChildren()
	local output = 0
	if parentchildren[#parentchildren] == node then output = 1 end
	if parentchildren[1] == node then output = output + 2 end
	return output
end
adverts.tree.DoRightClick = function( self, node )
	self:SetSelectedItem( node )
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	if not node.data then
		menu:AddOption( "重命名组...", function() adverts.RenameAdvert( node:GetText() ) end )
	end
	menu:AddOption( "删除", function() adverts.removeAdvert( node ) end )
	menu:Open()
end
adverts.seloffset = 0
adverts.message = xlib.maketextbox{ x=125, w=150, h=20, text="输入留言...", parent=adverts, selectall=true }
xlib.makelabel{ x=125, y=25, label="广告重复之前的时间:", parent=adverts }
adverts.time = xlib.makeslider{ x=125, y=40, w=150, label="<--->", value=60, min=1, max=1000, tooltip="显示/重复广告的时间(以秒为单位).", parent=adverts }
adverts.group = xlib.makecombobox{ x=125, y=65, w=150, enableinput=true, parent=adverts, tooltip="选择或创建新的广告组." }
adverts.color = xlib.makecolorpicker{ x=135, y=90, parent=adverts }
local panel = xlib.makelistlayout{ w=150, h=45, spacing=4, parent=xgui.null }
panel:Add( xlib.makelabel{ label="显示时间(秒)" } )
adverts.display = xlib.makeslider{ label="<--->", min=1, max=60, value=10, tooltip="CSay 广告显示的时间(以秒为单位)" }
panel:Add( adverts.display )
adverts.csay = xlib.makecat{ x=125, y=230, w=150, label="居中显示", checkbox=true, contents=panel, parent=adverts, expanded=false }
xlib.makebutton{ x=200, y=302, w=75, label="创建", parent=adverts }.DoClick = function()
	local col = adverts.color:GetColor()
	local rpt = tonumber( adverts.time:GetValue() )
	RunConsoleCommand( "xgui", "addAdvert", adverts.message:GetValue(), ( rpt < 0.1 ) and 0.1 or rpt, adverts.group:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil)
end
adverts.removebutton = xlib.makebutton{ y=302, w=75, label="消除", disabled=true, parent=adverts }
adverts.removebutton.DoClick = function( node )
	adverts.removeAdvert( adverts.tree:GetSelectedItem() )
end
adverts.updatebutton = xlib.makebutton{ x=125, y=302, w=75, label="更新", parent=adverts, disabled=true }
adverts.updatebutton.DoClick = function( node )
	local node = adverts.tree:GetSelectedItem()
	local col = adverts.color:GetColor()
	if ((( type( node.group ) == "number" ) and "<无组>" or node.group ) == adverts.group:GetValue() ) then
		RunConsoleCommand( "xgui", "updateAdvert", type( node.group ), node.group, node.number, adverts.message:GetValue(), ( adverts.time:GetValue() < 0.1 ) and 0.1 or adverts.time:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil )
	else
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", adverts.message:GetValue(), ( adverts.time:GetValue() < 0.1 ) and 0.1 or adverts.time:GetValue(), adverts.group:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil)
		adverts.selnewgroup = adverts.group:GetValue()
		if xgui.data.adverts[adverts.group:GetValue()] then
			adverts.seloffset = #xgui.data.adverts[adverts.group:GetValue()]+1
		else
			adverts.seloffset = 1
		end
	end
end
adverts.nodeup = xlib.makebutton{ x=80, y=302, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, parent=adverts, disabled=true }
adverts.nodeup.DoClick = function()
	adverts.nodedown:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	local node = adverts.tree:GetSelectedItem()
	local state = adverts.getNodePos( node )
	if state <= 1 then
		RunConsoleCommand( "xgui", "moveAdvert", type( node.group ), node.group, node.number, node.number-1 )
		adverts.seloffset = adverts.seloffset - 1
	else
		local parentnode = node:GetParentNode()
		local parentparentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		local newgroup = "<No Group>"
		for i,v in ipairs( parentparentchildren ) do
			if v == parentnode then
				if parentparentchildren[i-1] and type( parentparentchildren[i-1].group ) ~= "number" then
					newgroup = parentparentchildren[i-1].group
					adverts.selnewgroup = newgroup
					adverts.seloffset = #xgui.data.adverts[newgroup]+1
				end
				break
			end
		end
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", node.data.message, node.data.rpt, newgroup, node.data.color.r, node.data.color.g, node.data.color.b, node.data.len)
		if newgroup == "<No Group>" then
			adverts.selnewgroup = #xgui.data.adverts+1
			adverts.seloffset = 1
		end
	end
end
adverts.nodedown = xlib.makebutton{ x=100, y=302, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, parent=adverts, disabled=true }
adverts.nodedown.DoClick = function()
	adverts.nodedown:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	local node = adverts.tree:GetSelectedItem()
	local state = adverts.getNodePos( node )
	if state == 1 or state == 3 then
		local parentnode = type( node.group ) == "string" and node:GetParentNode() or node
		local parentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		local newgroup = "<No Group>"
		for index,v in ipairs( parentchildren ) do
			if v == parentnode then
				local temp = 1
				while( type( parentchildren[index+temp].group ) == "number" ) do
					temp = temp + 1
				end
				if type( parentchildren[index+temp].group ) ~= "number" then
					newgroup = parentchildren[index+temp].group
					adverts.selnewgroup = newgroup
					adverts.seloffset = 1
				end
				break
			end
		end
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", node.data.message, node.data.rpt, newgroup, node.data.color.r, node.data.color.g, node.data.color.b, node.data.len or "", "hold" )
		RunConsoleCommand( "xgui", "moveAdvert", type( newgroup ), newgroup, #xgui.data.adverts[newgroup]+1, 1 )
	else
		RunConsoleCommand( "xgui", "moveAdvert", type( node.group ), node.group, node.number, node.number+1 )
		adverts.seloffset = adverts.seloffset + 1
	end
end
function adverts.removeAdvert( node )
	if node then
		Derma_Query( "你确定要删除这个吗 " .. ( node.data and "广告?" or "广告组?" ), "XGUI WARNING",
		"Delete", function()
			if node.data then --Remove a single advert
				RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ) )
			else --Remove an advert group
				RunConsoleCommand( "xgui", "removeAdvertGroup", node.group, type( node.group ) )
			end
			adverts.tree:SetSelectedItem( nil )
		end, "Cancel", function() end )
	end
end
function adverts.RenameAdvert( old )
	advertRename = xlib.makeframe{ label="设置广告组名称 - " .. old, w=400, h=80, showclose=true, skin=xgui.settings.skin }
	advertRename.text = xlib.maketextbox{ x=10, y=30, w=380, h=20, text=old, parent=advertRename }
	advertRename.text.OnEnter = function( self )
		RunConsoleCommand( "xgui", "renameAdvertGroup", old, self:GetValue() )
		advertRename:Remove()
	end
	xlib.makebutton{ x=175, y=55, w=50, label="OK", parent=advertRename }.DoClick = function()
		advertRename.text:OnEnter()
	end
end
function adverts.updateAdverts()
	adverts.updatebutton:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	adverts.nodedown:SetDisabled( true )
	adverts.removebutton:SetDisabled( true )
	--Store the currently selected node, if any
	local lastNode = adverts.tree:GetSelectedItem()
	if adverts.selnewgroup then
		lastNode.group = adverts.selnewgroup
		lastNode.number = adverts.seloffset
		adverts.selnewgroup = nil
		adverts.seloffset = 0
	end
	--Check for any previously expanded group nodes
	local groupStates = {}
	if adverts.tree.RootNode.ChildNodes then
		for _, node in ipairs( adverts.tree.RootNode.ChildNodes:GetChildren() ) do
			if node.m_bExpanded then
				groupStates[node:GetText()] = true
			end
		end
	end
	adverts.hasGroups = false
	adverts.tree:Clear()
	adverts.group:Clear()
	adverts.group:AddChoice( "<无组>" )
	adverts.group:ChooseOptionID( 1 )

	local sortGroups = {}
	local sortSingle = {}
	for group, advertgroup in pairs( xgui.data.adverts ) do
		if type( group ) == "string" then --Check if it's a group or a single advert
			table.insert( sortGroups, group )
		else
			table.insert( sortSingle, { group=group, message=advertgroup[1].message } )
		end
	end
	table.sort( sortSingle, function(a,b) return string.lower( a.message ) < string.lower( b.message ) end )
	table.sort( sortGroups, function(a,b) return string.lower( a ) < string.lower( b ) end )
	for _, advert in ipairs( sortSingle ) do
		adverts.createNode( adverts.tree, xgui.data.adverts[advert.group][1], advert.group, 1, xgui.data.adverts[advert.group][1].message, lastNode )
	end
	for _, group in ipairs( sortGroups ) do
		advertgroup = xgui.data.adverts[group]
		adverts.hasGroups = true
		local foldernode = adverts.tree:AddNode( group, "icon16/folder.png" )
		adverts.group:AddChoice( group )
		foldernode.group = group
		--Check if folder was previously selected
		if lastNode and not lastNode.data and lastNode:GetValue() == group then
			adverts.tree:SetSelectedItem( foldernode )
			adverts.removebutton:SetDisabled( false )
		end
		for advert, data in ipairs( advertgroup ) do
			adverts.createNode( foldernode, data, group, advert, data.message, lastNode )
		end
		--Expand folder if it was expanded previously
		if groupStates[group] then foldernode:SetExpanded( true, true ) end
	end

	adverts.tree:InvalidateLayout()
	local node = adverts.tree:GetSelectedItem()
	if node then
		if adverts.seloffset ~= 0 then
			for i,v in ipairs( node:GetParentNode().ChildNodes:GetChildren() ) do
				if v == node then
					node = node:GetParentNode().ChildNodes:GetChildren()[i+adverts.seloffset]
					adverts.tree:SetSelectedItem( node )
					break
				end
			end
			adverts.seloffset = 0
		end
		if adverts.isBottomNode( node ) then adverts.nodedown:SetDisabled( true ) end
		adverts.nodeup:SetDisabled( type( node.group ) == "number" )
	end
end
function adverts.createNode( parent, data, group, number, message, lastNode )
	local node = parent:AddNode( message, data.len and "icon16/style.png" or "icon16/text_smallcaps.png" )
	node.data = data
	node.group = group
	node.number = number
	node:SetTooltip( xlib.wordWrap( message, 250, "Default" ) )
	if lastNode and lastNode.data then
		--Check if node was previously selected
		if lastNode.group == group and lastNode.number == number then
			adverts.tree:SetSelectedItem( node )
			adverts.group:SetText( type(node.group) ~= "number" and node.group or "<No Group>" )
			adverts.updatebutton:SetDisabled( false )
			adverts.nodeup:SetDisabled( false )
			adverts.nodedown:SetDisabled( false )
			adverts.removebutton:SetDisabled( false )
		end
	end
end
function adverts.onOpen()
	ULib.queueFunctionCall( adverts.tree.InvalidateLayout, adverts.tree )
end
adverts.updateAdverts() -- For autorefresh
xgui.hookEvent( "adverts", "process", adverts.updateAdverts, "serverUpdateAdverts" )
xgui.addSubModule( "ULX 广告", adverts, nil, "server" )

---------------------------封禁信息---------------------------
xgui.prepareDataType( "banmessage" )
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="向被封禁的用户显示的消息", zpos=1 } )
plist.txtBanMessage = xlib.maketextbox{ zpos=2, h=236, multiline=true }
plist:Add( plist.txtBanMessage )
plist:Add( xlib.makelabel{ label="插入变量:", zpos=3 } )
plist.variablePicker = xlib.makecombobox{ choices={ "禁止人 - 管理员:创建封禁的 SteamID","禁止开始 - 创建封禁的日期/时间","原因","剩余时间","SteamID（不包括非数字字符）","SteamID64(适用于构建用于上诉禁令的 URL)" }, zpos=4 }
plist:Add( plist.variablePicker )

plist.btnPreview = xlib.makebutton{ label="预览封禁信息", zpos=4 }
plist.btnPreview.DoClick = function()
	net.Start( "XGUI.PreviewBanMessage" )
		net.WriteString( plist.txtBanMessage:GetText() )
	net.SendToServer()
end
xgui.handleBanPreview = function( message )
	local preview = xlib.makeframe{ w=380, h=200 }
	local message = xlib.makelabel{ x=20, y=35, label=message, textcolor=Color( 191, 191, 191, 255 ), font="默认大", parent=preview }
	message:SizeToContents()
	local close = xlib.makebutton{ x=288, y=message:GetTall()+42, w=72, h=24, label="关闭", font="默认大", parent=preview }
	close.DoClick = function()
		preview:Remove()
	end
	preview:SetTall( message:GetTall() + 85 )
end
plist:Add( plist.btnPreview )
plist.btnSave = xlib.makebutton{ label="保存封禁消息", zpos=5 }
plist.btnSave.DoClick = function()
	net.Start( "XGUI.SaveBanMessage" )
		net.WriteString( plist.txtBanMessage:GetText() )
	net.SendToServer()
end
plist:Add( plist.btnSave )

plist.variablePicker.OnSelect = function( self, index, value, data )
	self:SetValue( "" )
	local newVariable = ""
	if index == 1 then
		newVariable = "{{BANNED_BY}}"
	elseif index == 2 then
		newVariable = "{{BAN_START}}"
	elseif index == 3 then
		newVariable = "{{REASON}}"
	elseif index == 4 then
		newVariable = "{{TIME_LEFT}}"
	elseif index == 5 then
		newVariable = "{{STEAMID}}"
	elseif index == 6 then
		newVariable = "{{STEAMID64}}"
	end
	plist.txtBanMessage:SetText( plist.txtBanMessage:GetText() .. newVariable )
end

plist.updateBanMessage = function()
	plist.txtBanMessage:SetText( xgui.data.banmessage.message or "" )
end
plist.updateBanMessage()
xgui.hookEvent( "banmessage", "process", plist.updateBanMessage, "serverUpdateBanMessage" )

xgui.addSubModule( "ULX 封禁信息", plist, nil, "server" )

------------------------------回声-------------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="命令/事件回显设置" } )
plist:Add( xlib.makecheckbox{ label="Echo 玩家投票选择", repconvar="ulx_voteEcho" } )
plist:Add( xlib.makecombobox{ repconvar="ulx_logEcho", isNumberConvar=true, choices={ "不要回显管理命令", "匿名回显管理员命令", "回显命令并识别管理员" } } )
plist:Add( xlib.makecombobox{ repconvar="ulx_logSpawnsEcho", isNumberConvar=true, choices={ "不要回声产卵", "Echo 只生成给管理员", "回声对每个人产生" } } )
plist:Add( xlib.makecheckbox{ label="启用彩色事件回声", repconvar="ulx_logEchoColors" } )

plist:Add( xlib.makelabel{ label="默认文本颜色" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorDefault", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="控制台颜色" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorConsole", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="自己的颜色" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorSelf", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="每个人的颜色" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorEveryone", noalphamodetwo=true } )
plist:Add( xlib.makecheckbox{ label="为玩家显示球队颜色", repconvar="ulx_logEchoColorPlayerAsGroup" } )
plist:Add( xlib.makelabel{ label="玩家的颜色(当上面被禁用时)" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorPlayer", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="其他一切的颜色" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorMisc", noalphamodetwo=true } )
xgui.addSubModule( "ULX 命令/事件回声", plist, nil, "server" )

------------------------通用设置-------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="常规 ULX 设置" } )
plist:Add( xlib.makeslider{ label="聊天垃圾时间", min=0, max=5, decimal=1, repconvar="ulx_chattime" } )
plist:Add( xlib.makelabel{ label="\n允许 '/我' 聊天功能" } )
plist:Add( xlib.makecombobox{ repconvar="ulx_meChatEnabled", isNumberConvar=true, choices={ "已禁用", "仅限沙盒", "启用" } } )
plist:Add( xlib.makelabel{ label="\n欢迎消息" } )
plist:Add( xlib.maketextbox{ repconvar="ulx_welcomemessage", selectall=true } )
plist:Add( xlib.makelabel{ label="允许的变量: %curmap%, %host%" } )
plist:Add( xlib.makelabel{ label="\n自动改名踢球者" } )
plist:Add( xlib.makelabel{ label="名称更改次数直到被踢(0 禁用)" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, decimal=0, repconvar="ulx_kickAfterNameChanges" } )
plist:Add( xlib.makeslider{ label="冷却时间(秒)", min=0, max=600, decimal=0, repconvar="ulx_kickAfterNameChangesCooldown" } )
plist:Add( xlib.makecheckbox{ label="警告玩家还有多少更名", repconvar="ulx_kickAfterNameChangesWarning" } )

xgui.addSubModule( "ULX 通用设置", plist, nil, "server" )

------------------------------Gimps------------------------------
xgui.prepareDataType( "gimps" )
local gimps = xlib.makepanel{ parent=xgui.null }
gimps.textbox = xlib.maketextbox{ w=225, h=20, parent=gimps, selectall=true }
gimps.textbox.OnEnter = function( self )
	if self:GetValue() then
		RunConsoleCommand( "xgui", "addGimp", self:GetValue() )
		self:SetText( "" )
	end
end
gimps.textbox.OnGetFocus = function( self )
	gimps.button:SetText( "添加" )
	self:SelectAllText()
	xgui.anchor:SetKeyboardInputEnabled( true )
end
gimps.button = xlib.makebutton{ x=225, w=50, label="添加", parent=gimps }
gimps.button.DoClick = function( self )
	if self:GetValue() == "添加" then
		gimps.textbox:OnEnter()
	elseif gimps.list:GetSelectedLine() then
		RunConsoleCommand( "xgui", "removeGimp", gimps.list:GetSelected()[1]:GetColumnText(1) )
	end
end
gimps.list = xlib.makelistview{ y=20, w=275, h=302, multiselect=false, headerheight=0, parent=gimps }
gimps.list:AddColumn( "Gimp 谚语" )
gimps.list.OnRowSelected = function( self, LineID, Line )
	gimps.button:SetText( "消除" )
end
gimps.updateGimps = function()
	gimps.list:Clear()
	for k, v in pairs( xgui.data.gimps ) do
		gimps.list:AddLine( v )
	end
end
gimps.updateGimps()
xgui.hookEvent( "gimps", "process", gimps.updateGimps, "serverUpdateGimps" )
xgui.addSubModule( "ULX 瞎搞", gimps, nil, "server" )

------------------------踢/封禁原因-------------------------
xgui.prepareDataType( "banreasons", ulx.common_kick_reasons )
local panel = xlib.makepanel{ parent=xgui.null }
panel.textbox = xlib.maketextbox{ w=225, h=20, parent=panel, selectall=true }
panel.textbox.OnEnter = function( self )
	if self:GetValue() then
		RunConsoleCommand( "xgui", "addBanReason", self:GetValue() )
		self:SetText( "" )
	end
end
panel.textbox.OnGetFocus = function( self )
	panel.button:SetText( "添加" )
	self:SelectAllText()
	xgui.anchor:SetKeyboardInputEnabled( true )
end
panel.button = xlib.makebutton{ x=225, w=50, label="添加", parent=panel }
panel.button.DoClick = function( self )
	if self:GetValue() == "Add" then
		panel.textbox:OnEnter()
	elseif panel.list:GetSelectedLine() then
		RunConsoleCommand( "xgui", "removeBanReason", panel.list:GetSelected()[1]:GetColumnText(1) )
	end
end
panel.list = xlib.makelistview{ y=20, w=275, h=302, multiselect=false, headerheight=0, parent=panel }
panel.list:AddColumn( "踢/封禁原因" )
panel.list.OnRowSelected = function()
	panel.button:SetText( "消除" )
end
panel.updateBanReasons = function()
	panel.list:Clear()
	for k, v in pairs( ulx.common_kick_reasons ) do
		panel.list:AddLine( v )
	end
end
panel.updateBanReasons()
xgui.hookEvent( "banreasons", "process", panel.updateBanReasons, "serverUpdateBanReasons" )
xgui.addSubModule( "ULX 踢/封禁原因", panel, "xgui_managebans", "server" )

--------------------------日志设置---------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="日志设置" } )
plist:Add( xlib.makecheckbox{ label="启用记录到文件", repconvar="ulx_logFile" } )
plist:Add( xlib.makecheckbox{ label="日志聊天", repconvar="ulx_logChat" } )
plist:Add( xlib.makecheckbox{ label="记录玩家事件(连接,死亡等)", repconvar="ulx_logEvents" } )
plist:Add( xlib.makecheckbox{ label="原木生成(道具,效果,布娃娃等)", repconvar="ulx_logSpawns" } )
plist:Add( xlib.makelabel{ label="将日志文件保存到此目录:" } )
local logdirbutton = xlib.makebutton{}
xlib.checkRepCvarCreated( "ulx_logdir" )
logdirbutton:SetText( "data/" .. GetConVar( "ulx_logDir" ):GetString() )

function logdirbutton.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if cl_cvar == "ulx_logdir" then
		logdirbutton:SetText( "data/" .. new_val )
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_ulx_logDir", logdirbutton.ConVarUpdated )
plist:Add( logdirbutton )
xgui.addSubModule( "ULX 日志", plist, nil, "server" )

------------------------------公告-------------------------------
xgui.prepareDataType( "motdsettings" )
local motdpnl = xlib.makepanel{ w=275, h=322, parent=xgui.null }
local plist = xlib.makelistlayout{ w=275, h=298, parent=motdpnl }

local fontWeights = { "普通的", "大", "100", "200", "300", "400", "500", "600", "700", "800", "900", "lighter", "bolder" }
local commonFonts = { "宋体", "宋体黑", "口径", "坎德拉", "坎布里亚", "康索拉斯", "快递新", "弗拉克林哥特中号", "Futura", "Georgia", "Helvetica", "Impact", "Lucida Console", "Segoe UI", "Tahoma", "Times New Roman", "Trebuchet MS", "Verdana" }


plist:Add( xlib.makelabel{ label="MOTD模式:", zpos=0 } )
plist:Add( xlib.makecombobox{ repconvar="ulx_showmotd", isNumberConvar=true, choices={ "0 - 禁用", "1 - 本地文件", "2 - MOTD 生成器", "3 - URL" }, zpos=1 } )
plist.txtMotdFile = xlib.maketextbox{ repconvar="ulx_motdfile", zpos=2 }
plist:Add( plist.txtMotdFile )
plist.txtMotdURL = xlib.maketextbox{ repconvar="ulx_motdurl", zpos=3 }
plist:Add( plist.txtMotdURL )
plist.lblDescription = xlib.makelabel{ zpos=4 }
plist:Add( plist.lblDescription )


----- MOTD Generator helper methods
local function unitToNumber(value)
	return tonumber( string.gsub(value, "[^%d]", "" ), _ )
end

local function hexToColor(value)
	value = string.gsub(value, "#","")
	return Color(tonumber("0x"..value:sub(1,2)), tonumber("0x"..value:sub(3,4)), tonumber("0x"..value:sub(5,6)))
end

local function colorToHex(color)
	return string.format("#%02x%02x%02x", color.r, color.g, color.b )
end

local didPressEnter = false
local selectedPanelTag = nil
local function registerMOTDChangeEventsTextbox( textbox, setting, sendTable )
	textbox.hasChanged = false

	textbox.OnEnter = function( self )
		didPressEnter = true
	end

	textbox.OnLoseFocus = function( self )
		selectedPanelTag = nil
		hook.Call( "OnTextEntryLoseFocus", nil, self )

		-- OnLoseFocus gets called twice when pressing enter. This will hackishly take care of one of them.
		if didPressEnter then
			didPressEnter = false
			return
		end

		if self:GetValue() and textbox.hasChanged then
			textbox.hasChanged = false
			if sendTable then
				net.Start( "XGUI.SetMotdData" )
					net.WriteString( setting )
					net.WriteTable( ULib.explode( "\n", self:GetValue() ) )
				net.SendToServer()
			else
				net.Start( "XGUI.UpdateMotdData" )
					net.WriteString( setting )
					net.WriteString( self:GetValue() )
				net.SendToServer()
			end
		end
	end

	-- Don't submit the data if the text hasn't changed.
	textbox:SetUpdateOnType( true )
	textbox.OnValueChange = function( self, strValue )
		textbox.hasChanged = true
	end

	-- Store focused setting so we can re-set the focused element when the panels are recreated.
	textbox.OnGetFocus = function( self )
		hook.Run( "OnTextEntryGetFocus", self )
		selectedPanelTag = setting
	end
	if selectedPanelTag == setting then
		timer.Simple( 0, function() textbox:RequestFocus() end )
	end

end

local function registerMOTDChangeEventsCombobox( combobox, setting )
	registerMOTDChangeEventsTextbox( combobox.TextEntry, setting )

	combobox.OnSelect = function( self )
		net.Start( "XGUI.UpdateMotdData" )
			net.WriteString( setting )
			net.WriteString( self:GetValue() )
		net.SendToServer()
	end
end

local function registerMOTDChangeEventsSlider( slider, setting )
	registerMOTDChangeEventsTextbox( slider.TextArea, setting )

	local tmpfunc = slider.Slider.SetDragging
	slider.Slider.SetDragging = function( self, bval )
		tmpfunc( self, bval )
		if ( !bval ) then
			net.Start( "XGUI.UpdateMotdData" )
				net.WriteString( setting )
				net.WriteString( slider.TextArea:GetValue() )
			net.SendToServer()
		end
	end

	local tmpfunc2 = slider.Scratch.OnMouseReleased
	slider.Scratch.OnMouseReleased = function( self, mousecode )
		tmpfunc2( self, mousecode )
		net.Start( "XGUI.UpdateMotdData" )
			net.WriteString( setting )
			net.WriteString( slider.TextArea:GetValue() )
		net.SendToServer()
	end
end

local function registerMOTDChangeEventsColor( colorpicker, setting )
	colorpicker.OnChange = function( self, color )
		net.Start( "XGUI.UpdateMotdData" )
			net.WriteString( setting )
			net.WriteString( colorToHex( color ) )
		net.SendToServer()
	end
end

local function performMOTDInfoUpdate( data, setting )
	net.Start( "XGUI.SetMotdData" )
		net.WriteString( setting )
		net.WriteTable( data )
	net.SendToServer()
end


-- MOTD 生成器用户界面
plist.generator = xlib.makelistlayout{ w=255, h=250, zpos=6 }
plist:Add( plist.generator )
plist.generator:SetVisible( false )

plist.generator:Add( xlib.makelabel{ label="MOTD 生成器标题:", zpos=-2 } )

local txtServerDescription = xlib.maketextbox{ zpos=-1 }
plist.generator:Add( txtServerDescription )

plist.generator:Add( xlib.makelabel{ label="\nMOTD 生成器信息" } )
local pnlInfo = xlib.makelistlayout{ w=271 }
plist.generator:Add( pnlInfo )

plist.generator:Add( xlib.makelabel{} )

local btnAddSection = xlib.makebutton{ label="添加新部分..." }
btnAddSection.DoClick = function()
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	menu:AddOption( "文字内容", function()
		local info = xgui.data.motdsettings.info
		table.insert( info, {
			type="文本",
			title="关于本服务器",
			contents={"在此处输入服务器描述!"}
		})
		performMOTDInfoUpdate( info[#info], "信息["..#info.."]" )
	end )
	menu:AddOption( "项目符号列表", function()
		local info = xgui.data.motdsettings.info
		table.insert( info, {
			type="列表",
			title="示例列表",
			contents={"每个换行符都成为它自己的要点.", "您可以根据需要添加任意数量!"}
		})
		performMOTDInfoUpdate( info[#info], "信息["..#info.."]" )
	end )
	menu:AddOption( "编号列表", function()
		local info = xgui.data.motdsettings.info
		table.insert( info, {
			type="有序列表",
			title="示例编号列表",
			contents={"每个换行符都成为它自己的编号项目.", "您可以根据需要添加任意数量!"}
		})
		performMOTDInfoUpdate( info[#info], "info["..#info.."]" )
	end )
	menu:AddOption( "已安装的插件", function()
		local info = xgui.data.motdsettings.info
		table.insert( info, {
			type="模组",
			title="已安装的插件"
		})
		performMOTDInfoUpdate( info[#info], "info["..#info.."]" )
	end )
	menu:AddOption( "列出组中的用户", function()
		local info = xgui.data.motdsettings.info
		table.insert( info, {
			type="管理员",
			title="我们的管理员",
			contents={"superadmin", "admin"}
		})
		performMOTDInfoUpdate( info[#info], "info["..#info.."]" )
	end )
	menu:Open()
end
plist.generator:Add( btnAddSection )

plist.generator:Add( xlib.makelabel{ label="\nMOTD 生成器字体" } )

plist.generator:Add( xlib.makelabel{ label="\n服务器名称(标题)" } )
local pnlFontServerName = xlib.makepanel{h=80, parent=xgui.null }
xlib.makelabel{ x=5, y=8, label="字体名称", parent=pnlFontServerName }
pnlFontServerName.name = xlib.makecombobox{ x=65, y=5, w=190, enableinput=true, selectall=true, choices=commonFonts, parent=pnlFontServerName }
pnlFontServerName.size = xlib.makeslider{ x=5, y=30, w=250, label="字体大小(像素)", value=16, min=4, max=72, parent=pnlFontServerName }
xlib.makelabel{ x=5, y=58, label="字体粗细", parent=pnlFontServerName }
pnlFontServerName.weight = xlib.makecombobox{ x=72, y=55, w=183, enableinput=true, selectall=true, choices=fontWeights, parent=pnlFontServerName }
plist.generator:Add( pnlFontServerName )

plist.generator:Add( xlib.makelabel{ label="\n服务器说明(副标题)" } )
local pnlFontSubtitle = xlib.makepanel{h=80, parent=xgui.null }
xlib.makelabel{ x=5, y=8, label="字体名称", parent=pnlFontSubtitle }
pnlFontSubtitle.name = xlib.makecombobox{ x=65, y=5, w=190, enableinput=true, selectall=true, choices=commonFonts, parent=pnlFontSubtitle }
pnlFontSubtitle.size = xlib.makeslider{ x=5, y=30, w=250, label="字体大小(像素)", value=16, min=4, max=72, parent=pnlFontSubtitle }
xlib.makelabel{ x=5, y=58, label="字体粗细", parent=pnlFontSubtitle }
pnlFontSubtitle.weight = xlib.makecombobox{ x=72, y=55, w=183, enableinput=true, selectall=true, choices=fontWeights, parent=pnlFontSubtitle }
plist.generator:Add( pnlFontSubtitle )

plist.generator:Add( xlib.makelabel{ label="\n章节标题" } )
local pnlFontSection = xlib.makepanel{h=80, parent=xgui.null }
xlib.makelabel{ x=5, y=8, label="字体名称", parent=pnlFontSection }
pnlFontSection.name = xlib.makecombobox{ x=65, y=5, w=190, enableinput=true, selectall=true, choices=commonFonts, parent=pnlFontSection }
pnlFontSection.size = xlib.makeslider{ x=5, y=30, w=250, label="字体大小（像素）", value=16, min=4, max=72, parent=pnlFontSection }
xlib.makelabel{ x=5, y=58, label="字体粗细", parent=pnlFontSection }
pnlFontSection.weight = xlib.makecombobox{ x=72, y=55, w=183, enableinput=true, selectall=true, choices=fontWeights, parent=pnlFontSection }
plist.generator:Add( pnlFontSection )

plist.generator:Add( xlib.makelabel{ label="\n常规文本" } )
local pnlFontRegular = xlib.makepanel{ h=80, parent=xgui.null }
xlib.makelabel{ x=5, y=8, label="字体名称", parent=pnlFontRegular }
pnlFontRegular.name = xlib.makecombobox{ x=65, y=5, w=190, enableinput=true, selectall=true, choices=commonFonts, parent=pnlFontRegular }
pnlFontRegular.size = xlib.makeslider{ x=5, y=30, w=250, label="字体大小(像素)", value=16, min=4, max=72, parent=pnlFontRegular }
xlib.makelabel{ x=5, y=58, label="字体粗细", parent=pnlFontRegular }
pnlFontRegular.weight = xlib.makecombobox{ x=72, y=55, w=183, enableinput=true, selectall=true, choices=fontWeights, parent=pnlFontRegular }
plist.generator:Add( pnlFontRegular )


plist.generator:Add( xlib.makelabel{ label="\nMOTD 发电机颜色\n" } )

plist.generator:Add( xlib.makelabel{ label="背景颜色" } )
local pnlColorBackground = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlColorBackground )
plist.generator:Add( xlib.makelabel{ label="标题颜色" } )
local pnlColorHeaderBackground = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlColorHeaderBackground )
plist.generator:Add( xlib.makelabel{ label="标题文本颜色" } )
local pnlColorHeader = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlColorHeader )
plist.generator:Add( xlib.makelabel{ label="部分标题文本颜色" } )
local pnlColorSection = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlColorSection )
plist.generator:Add( xlib.makelabel{ label="Default Text Color" } )
local pnlColorText = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlColorText )

plist.generator:Add( xlib.makelabel{ label="\nMOTD 发生器顶部/底部边框\n" } )

local pnlBorderThickness = xlib.makeslider{ label="边框厚度(像素)", w=200, value=1, min=0, max=32 }
plist.generator:Add( pnlBorderThickness )
plist.generator:Add( xlib.makelabel{ label="边框颜色" } )
local pnlBorderColor = xlib.makecolorpicker{ noalphamodetwo=true }
plist.generator:Add( pnlBorderColor )

registerMOTDChangeEventsTextbox( txtServerDescription, "info.description" )

registerMOTDChangeEventsCombobox( pnlFontServerName.name, "style.fonts.server_name.family" )
registerMOTDChangeEventsSlider( pnlFontServerName.size, "style.fonts.server_name.size" )
registerMOTDChangeEventsCombobox( pnlFontServerName.weight, "style.fonts.server_name.weight" )
registerMOTDChangeEventsCombobox( pnlFontSubtitle.name, "style.fonts.subtitle.family" )
registerMOTDChangeEventsSlider( pnlFontSubtitle.size, "style.fonts.subtitle.size" )
registerMOTDChangeEventsCombobox( pnlFontSubtitle.weight, "style.fonts.subtitle.weight" )
registerMOTDChangeEventsCombobox( pnlFontSection.name, "style.fonts.section_title.family" )
registerMOTDChangeEventsSlider( pnlFontSection.size, "style.fonts.section_title.size" )
registerMOTDChangeEventsCombobox( pnlFontSection.weight, "style.fonts.section_title.weight" )
registerMOTDChangeEventsCombobox( pnlFontRegular.name, "style.fonts.regular.family" )
registerMOTDChangeEventsSlider( pnlFontRegular.size, "style.fonts.regular.size" )
registerMOTDChangeEventsCombobox( pnlFontRegular.weight, "style.fonts.regular.weight" )

registerMOTDChangeEventsColor( pnlColorBackground, "style.colors.background_color" )
registerMOTDChangeEventsColor( pnlColorHeaderBackground, "style.colors.header_color" )
registerMOTDChangeEventsColor( pnlColorHeader, "style.colors.header_text_color" )
registerMOTDChangeEventsColor( pnlColorSection, "style.colors.section_text_color" )
registerMOTDChangeEventsColor( pnlColorText, "style.colors.text_color" )

registerMOTDChangeEventsColor( pnlBorderColor, "style.borders.border_color" )
registerMOTDChangeEventsSlider( pnlBorderThickness, "style.borders.border_thickness" )



-- MOTD Cvar and data handling
plist.updateGeneratorSettings = function( data )
	if not data then data = xgui.data.motdsettings end
	if not data or not data.style or not data.info then return end
	if not plist.generator:IsVisible() then return end

	local borders = data.style.borders
	local colors = data.style.colors
	local fonts = data.style.fonts

	-- Description
	txtServerDescription:SetText( data.info.description )

	-- Section panels
	pnlInfo:Clear()
	for i=1, #data.info do
		local section = data.info[i]
		local sectionPanel = xlib.makelistlayout{ w=270 }

		if section.type == "text" then
			sectionPanel:Add( xlib.makelabel{ label="\n"..i..": Text Content", zpos=0 } )

			local sectionTitle = xlib.maketextbox{ zpos=1 }
			registerMOTDChangeEventsTextbox( sectionTitle, "info["..i.."].title" )
			sectionTitle:SetText( section.title )
			sectionPanel:Add( sectionTitle )

			local sectionText = xlib.maketextbox{ h=100, multiline=true, zpos=2 }
			registerMOTDChangeEventsTextbox( sectionText, "info["..i.."].contents", true )
			sectionText:SetText( table.concat( section.contents, "\n" ) )
			sectionPanel:Add( sectionText )

		elseif section.type == "ordered_list" then
			sectionPanel:Add( xlib.makelabel{ label="\n"..i..": Numbered List" } )

			local sectionTitle = xlib.maketextbox{ zpos=1 }
			registerMOTDChangeEventsTextbox( sectionTitle, "info["..i.."].title" )
			sectionTitle:SetText( section.title )
			sectionPanel:Add( sectionTitle )

			local sectionOrderedList = xlib.maketextbox{ h=110, multiline=true, zpos=2 }
			registerMOTDChangeEventsTextbox( sectionOrderedList, "info["..i.."].contents", true )
			sectionOrderedList:SetText( table.concat( section.contents, "\n" ) )
			sectionPanel:Add( sectionOrderedList )

		elseif section.type == "list" then
			sectionPanel:Add( xlib.makelabel{ label="\n"..i..": Bulleted List" } )

			local sectionTitle = xlib.maketextbox{ zpos=1 }
			registerMOTDChangeEventsTextbox( sectionTitle, "info["..i.."].title" )
			sectionTitle:SetText( section.title )
			sectionPanel:Add( sectionTitle )

			local sectionList = xlib.maketextbox{ h=100, multiline=true, zpos=2 }
			registerMOTDChangeEventsTextbox( sectionList, "info["..i.."].contents", true )
			sectionList:SetText( table.concat( section.contents, "\n" ) )
			sectionPanel:Add( sectionList )

		elseif section.type == "mods" then
			sectionPanel:Add( xlib.makelabel{ label="\n"..i..": Installed Addons" } )

			local modsTitle = xlib.maketextbox{ zpos=1 }
			registerMOTDChangeEventsTextbox( modsTitle, "info["..i.."].title" )
			modsTitle:SetText( section.title )
			sectionPanel:Add( modsTitle )

		elseif section.type == "admins" then
			sectionPanel:Add( xlib.makelabel{ label="\n"..i..": List Users in Group" } )

			local adminsTitle = xlib.maketextbox{ zpos=1 }
			registerMOTDChangeEventsTextbox( adminsTitle, "info["..i.."].title" )
			adminsTitle:SetText( section.title )
			sectionPanel:Add( adminsTitle )

			for j=1, #section.contents do
				local group = section.contents[j]
				local adminPnl = xlib.makepanel{ h=20, w=270, zpos=i+j }
				xlib.makelabel{ h=20, w=200, label=group, parent=adminPnl }
				local adminBtn = xlib.makebutton{ x=204, w=50, label="Remove", parent=adminPnl }
				adminBtn.DoClick = function()
					table.remove( section.contents, j )
					performMOTDInfoUpdate( section.contents, "info["..i.."].contents" )
				end
				sectionPanel:Add( adminPnl )
			end

			local adminAddPnl = xlib.makepanel{ h=20, w=270, zpos=99 }
			local adminBtn = xlib.makebutton{ w=100, label="Add Group...", parent=adminAddPnl }
			adminBtn.DoClick = function()
				local menu = DermaMenu()
				menu:SetSkin(xgui.settings.skin)
				for j=1, #xgui.data.groups do
					local group = xgui.data.groups[j]
					if not table.HasValue( section.contents, group ) then
						menu:AddOption( group, function()
							table.insert( section.contents, group )
							performMOTDInfoUpdate( section.contents, "info["..i.."].contents" )
						end )
					end
				end
				menu:Open()
			end
			sectionPanel:Add( adminAddPnl )

		end

		local actionPnl = xlib.makepanel{ w=270, h=20, zpos=100 }
		local btnRemove = xlib.makebutton{ w=100, label="删除部分", parent=actionPnl }
		btnRemove.DoClick = function()
			Derma_Query( "您确定要删除该部分吗 \"" .. section.title .. "\"?", "XGUI 警告",
				"Remove",	function()
								table.remove( data.info, i )
								performMOTDInfoUpdate( data.info, "info" )
							end,
				"Cancel", 	function() end )
		end
		local btnUp = xlib.makebutton{ x=214, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, disabled=(i==1), parent=actionPnl }
		btnUp.DoClick = function()
			local tmp = data.info[i-1]
			data.info[i-1] = data.info[i]
			data.info[i] = tmp
			performMOTDInfoUpdate( data.info, "info" )
		end
		local btnDown = xlib.makebutton{ x=234, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, disabled=(i==#data.info), parent=actionPnl }
		btnDown.DoClick = function()
			local tmp = data.info[i+1]
			data.info[i+1] = data.info[i]
			data.info[i] = tmp
			performMOTDInfoUpdate( data.info, "info" )
		end
		sectionPanel:Add( actionPnl )

		pnlInfo:Add( sectionPanel )
	end

	-- Fonts
	pnlFontServerName.name:SetText( fonts.server_name.family )
	pnlFontServerName.size:SetValue( unitToNumber( fonts.server_name.size ) )
	pnlFontServerName.weight:SetText( fonts.server_name.weight )
	pnlFontSubtitle.name:SetText( fonts.subtitle.family )
	pnlFontSubtitle.size:SetValue( unitToNumber( fonts.subtitle.size ) )
	pnlFontSubtitle.weight:SetText( fonts.subtitle.weight )
	pnlFontSection.name:SetText( fonts.section_title.family )
	pnlFontSection.size:SetValue( unitToNumber( fonts.section_title.size ) )
	pnlFontSection.weight:SetText( fonts.section_title.weight )
	pnlFontRegular.name:SetText( fonts.regular.family )
	pnlFontRegular.size:SetValue( unitToNumber( fonts.regular.size ) )
	pnlFontRegular.weight:SetText( fonts.regular.weight )

	-- Colors
	pnlColorBackground:SetColor( hexToColor( colors.background_color ) )
	pnlColorHeaderBackground:SetColor( hexToColor( colors.header_color ) )
	pnlColorHeader:SetColor( hexToColor( colors.header_text_color ) )
	pnlColorSection:SetColor( hexToColor( colors.section_text_color ) )
	pnlColorText:SetColor( hexToColor( colors.text_color ) )

	-- Borders
	pnlBorderThickness:SetValue( unitToNumber( borders.border_thickness ) )
	pnlBorderColor:SetColor( hexToColor( borders.border_color ) )
end
xgui.hookEvent( "motdsettings", "process", plist.updateGeneratorSettings, "serverUpdateGeneratorSettings" )
plist.updateGeneratorSettings()

plist.btnPreview = xlib.makebutton{ label="预览 MOTD", w=275, y=302, parent=motdpnl }
plist.btnPreview.DoClick = function()
	RunConsoleCommand( "ulx", "motd" )
end

function plist.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if string.lower( cl_cvar ) == "ulx_showmotd" then
		local previewDisabled = false
		local showMotdFile = false
		local showGenerator = false
		local showURL = false

		if new_val == "0" then
			previewDisabled = true
			plist.lblDescription:SetText( "MOTD 已完全禁用.\n" )
		elseif new_val == "1" then
			showMotdFile = true
			plist.lblDescription:SetText( "MOTD 是给定文件的内容.\n文件位于服务器的 garrysmod 根目录中.\n" )
		elseif new_val == "2" then
			showGenerator = true
			plist.lblDescription:SetText( "MOTD 是使用基本模板和以下设置生成的\n.\n" )
		elseif new_val == "3" then
			showURL = true
			plist.lblDescription:SetText( "MOTD 是给定的 URL.\n您可以使用 %curmap% 和 %steamid%\n(例如,server.com/?map=%curmap%&id=%steamid%)\n" )
		end

		plist.btnPreview:SetDisabled( previewDisabled )
		plist.txtMotdFile:SetVisible( showMotdFile )
		plist.generator:SetVisible( showGenerator )
		plist.txtMotdURL:SetVisible( showURL )
		plist.lblDescription:SizeToContents()
		plist.updateGeneratorSettings()

		plist.scroll:InvalidateChildren()
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_ulx_showMotd", plist.ConVarUpdated )

xlib.checkRepCvarCreated( "ulx_showMotd" )
plist.ConVarUpdated( nil, "ulx_showMotd", nil, nil, GetConVar( "ulx_showMotd" ):GetString() )

xgui.addSubModule( "ULX 公告", motdpnl, "ulx showmotd", "server" )

-----------------------玩家投票列表-----------------------
xgui.prepareDataType( "votemaps", ulx.votemaps )
local panel = xlib.makepanel{ w=285, h=322, parent=xgui.null }
xlib.makelabel{ label="允许的投票地图", x=5, y=3, parent=panel }
xlib.makelabel{ label="排除的投票地图", x=150, y=3, parent=panel }
panel.votemaps = xlib.makelistview{ y=20, w=135, h=262, multiselect=true, headerheight=0, parent=panel }
panel.votemaps:AddColumn( "" )
panel.votemaps.OnRowSelected = function( self, LineID, Line )
	panel.add:SetDisabled( true )
	panel.remove:SetDisabled( false )
	panel.remainingmaps:ClearSelection()
end
panel.remainingmaps = xlib.makelistview{ x=140, y=20, w=135, h=262, multiselect=true, headerheight=0, parent=panel }
panel.remainingmaps:AddColumn( "" )
panel.remainingmaps.OnRowSelected = function( self, LineID, Line )
	panel.add:SetDisabled( false )
	panel.remove:SetDisabled( true )
	panel.votemaps:ClearSelection()
end
panel.remove = xlib.makebutton{ y=282, w=135, label="消除 -->", disabled=true, parent=panel }
panel.remove.DoClick = function()
	panel.remove:SetDisabled( true )
	local temp = {}
	for _, v in ipairs( panel.votemaps:GetSelected() ) do
		table.insert( temp, v:GetColumnText(1) )
	end
	net.Start( "XGUI.RemoveVotemaps" )
		net.WriteTable( temp )
	net.SendToServer()
end
panel.add = xlib.makebutton{ x=140, y=282, w=135, label="<-- 添加", disabled=true, parent=panel }
panel.add.DoClick = function()
	panel.add:SetDisabled( true )
	local temp = {}
	for _, v in ipairs( panel.remainingmaps:GetSelected() ) do
		table.insert( temp, v:GetColumnText(1) )
	end
	net.Start( "XGUI.AddVotemaps" )
		net.WriteTable( temp )
	net.SendToServer()
end
panel.votemapmode = xlib.makecombobox{ y=302, w=275, repconvar="ulx_votemapMapmode", isNumberConvar=true, numOffset=0, choices={ "Include new maps by default", "Exclude new maps by default" }, parent=panel }
panel.updateList = function()
	if #ulx.maps ~= 0 then
		panel.votemaps:Clear()
		panel.remainingmaps:Clear()
		panel.add:SetDisabled( true )
		panel.remove:SetDisabled( true )
		for _, v in ipairs( ulx.maps ) do
			if table.HasValue( ulx.votemaps, v ) then
				panel.votemaps:AddLine( v )
			else
				panel.remainingmaps:AddLine( v )
			end
		end
	end
end
panel.updateList()
xgui.hookEvent( "votemaps", "process", panel.updateList, "serverUpdateVotemapList" )
xgui.addSubModule( "ULX 玩家投票列表", panel, nil, "server" )

---------------------玩家投票地图设置---------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="玩家投票地图设置" } )
plist:Add( xlib.makecheckbox{ label="启用玩家投票地图", repconvar="ulx_votemapEnabled" } )
plist:Add( xlib.makelabel{ label="用户可以为地图投票之前的时间(分钟)" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=300, repconvar="ulx_votemapMintime" } )
plist:Add( xlib.makelabel{ label="用户可以更改投票的时间(分钟)" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=60, decimal=1, repconvar="ulx_votemapWaittime" } )
plist:Add( xlib.makelabel{ label="接受改变地图所需的投票比例" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votemapSuccessratio" } )
plist:Add( xlib.makelabel{ label="成功更改地图的最低投票数" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votemapMinvotes" } )
plist:Add( xlib.makelabel{ label="管理员否决地图更改的时间(秒)" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=300, repconvar="ulx_votemapVetotime" } )
xgui.addSubModule( "ULX 玩家投票地图设置", plist, nil, "server" )

-------------------------预留插槽--------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="预留插槽设置" } )
plist:Add( xlib.makecombobox{ repconvar="ulx_rslotsMode", isNumberConvar=true, choices={ "0 - 保留插槽禁用", "1 - 管理员填充插槽", "2 - 管理员不填充插槽", "3 - 管理员踢最新玩家" } } )
plist:Add( xlib.makeslider{ label="预留槽位数", min=0, max=game.MaxPlayers(), repconvar="ulx_rslots" } )
plist:Add( xlib.makecheckbox{ label="保留插槽可见", repconvar="ulx_rslotsVisible" } )
plist:Add( xlib.makelabel{ w=265, wordwrap=true, label="保留插槽模式信息:\n1 - 设置一定数量的为管理员保留的空位-- 当管理员加入时,他们将填满这些空位.\n2 - 与 #1 相同,但管理员不会填满空位-- 当玩家离开时,他们将被释放.\n3 - 始终为管理员打开 1 个插槽,如果已满,则在管理员加入时以最短的连接时间踢用户,从而保持 1 个插槽打开.\n\n保留插槽可见:\n启用时,如果没有常规玩家服务器中可用的插槽,看起来服务器已满。这样做的主要缺点是管理员无法使用'查找服务器'对话框连接到服务器.相反,他们必须转到控制台并使用命令'connect <ip>'" } )
xgui.addSubModule( "ULX 预留插槽", plist, nil, "server" )

------------------------投票踢出/投票封禁-------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="投票设置" } )
plist:Add( xlib.makelabel{ label="接受投票所需的投票率" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votekickSuccessratio" } )
plist:Add( xlib.makelabel{ label="成功投票所需的最低票数" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votekickMinvotes" } )
plist:Add( xlib.makelabel{ label="\n投票禁令设置" } )
plist:Add( xlib.makelabel{ label="接受投票禁令所需的投票率" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votebanSuccessratio" } )
plist:Add( xlib.makelabel{ label="成功投票禁令所需的最低票数" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votebanMinvotes" } )
xgui.addSubModule( "ULX 投票踢出/投票封禁", plist, nil, "server" )
