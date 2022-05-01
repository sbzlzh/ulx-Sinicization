local help = [[
一般用户管理概念：
用户访问由 ULib 的 Ulysses 控制列表 (UCL) 驱动.此列表包含用户和组
它又包含允许和拒绝访问的列表.允许和拒绝列表包含
访问诸如"ulx slap"或"ulx phygunplayer"之类的字符串以显示用户和/或组的行为和行为
无法访问.如果用户在他们的用户允许列表或允许列表中有"ulx slap"
在他们所属的组中,他们可以使用耳光.如果用户在他们的用户拒绝中有"ulx slap"
列出他们被拒绝的命令,即使他们在他们的组允许中拥有该命令
列表.这样,拒绝优先于允许.

ULib 通过能够指定允许不同用户和组访问的内容来支持免疫
目标.这通常用于使较低的管理员无法针对较高的管理员. EG,默认
管理员不能以超级管理员为目标,但超级管理员仍然可以以管理员为目标.


更高级的概念：
组具有继承性.您可以在 addgroup 命令中指定它们从哪个组继承.如果一个
用户在具有继承的组中,UCL 将检查继承中连接的所有组
链.请注意,为简单起见,组不支持拒绝列表.如果你觉得一个
组需要被拒绝的东西,你应该把你的组分开.

"用户"组适用于不属于某个组的每个人.您可以使用
groupallow 就像任何其他组一样,请记住每个人都被允许访问.

ULib 通过使用"访问标签"支持高级的、高度可配置的权限系统.使用权
标签指定允许用户作为参数传递给命令的内容.例如,你可以让它
这样管理员只能杀死名字中带有"killme"的用户,或者你可以
让每个人都可以使用"ulx 传送"命令,但只允许他们传送自己.

下面在 userallow 和 groupallow 命令中给出了使用访问标签的示例.格式
访问标签如下.传递给命令的每个参数都可以由
访问标签.每个被限制的参数必须按照与命令中相同的顺序列出,
用空格隔开.如果您不想限制参数,请使用星号 ("*"). EG,限制"ulx
slap"伤害从 0 到 10,但仍然允许它对任何人使用,使用标签"* 0:10".

用户管理命令：
ulx adduser <user> <group> - 将指定的 CONNECTED 播放器添加到指定的组.
该组必须存在才能使该命令成功.使用操作员、管理员、超级管理员或查看 ulx
添加组.您只能指定一组.关于免疫的解释见上文.
Ex 1. ulx adduser "Someguy" 超级管理员 -- 这将添加连接的 "Someguy" 作为超级管理员
例 2. ulx adduser "Dood" 猴子 -- 这会将连接的 "Dood" 添加到组猴子
  在组存在的条件下

ulx removeuser <user> - 从永久访问列表中删除指定的连接播放器.
Ex 1. ulx removeuser "Foo bar" -- 这将删除用户 "Foo bar"

ulx userallow <user> <access> [<access tag>] - 将访问权限放在 USER'S ALLOW 列表中,使用
  可选访问标签(见上文）
有关允许列表与拒绝列表的说明,以及访问字符串/标签的工作原理,请参见上文.
Ex 1. ulx userallow "Pi" "ulx slap" -- 这授予用户访问"ulx slap"的权限
Ex 2. ulx userallow "Pi" "ulx slap" "!%admin 0" -- 这授予用户访问"ulx slap"的权限
  -- 但是他们只能扇低于管理员的用户,并且只能扇0伤害

ulx userdeny <user> <access> [<revoke>] - 移除玩家的访问权限.如果 revoke 为真,这只是
  从用户的允许/拒绝列表中删除访问字符串,而不是将其添加到用户的
  拒绝名单.有关拒绝列表的说明,请参见上文.

ulx addgroup <group> [<inherits from>] - 创建一个组,可选择从指定的继承
  团体.有关继承的说明,请参见上文.

ulx removegroup <group> - 永久删除一个组.也从所有连接的组中删除
  用户和所有将来连接的用户.如果用户除此之外没有任何组,他们将
  成为客人.请务必小心使用此命令!

ulx renamegroup <当前组> <新组> - 重命名组

ulx setgroupcantarget <group> [<target string>] - 限制一个组可以定位的用户.通过没有
  清除限制的论据.
Ex 1. ulx setgroupcantarget user !%admin - 来宾不能以管理员或更高级别为目标
Ex 2. ulx setgroupcantarget admin !^ - 管理员不能以自己为目标

ulx groupallow <group> <access> [<access tag>] - 将访问权限放在组的允许列表中.看
  以上是关于访问字符串/标签如何工作的.

ulx groupdeny <group> <access> - 删除组的访问权限.


]]

function ulx.showUserHelp()
	local lines = ULib.explode( "\n", help )
	for _, line in ipairs( lines ) do
		Msg( line .. "\n" )
	end
end
