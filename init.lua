diplazer_amount=15
diplazer_Tele={}
diplazer_UserTele={}
GGunTime=0
GGunInUse=0

local function getAmount(player, moden,admin)
	local Name=player:get_inventory():get_stack("main", player:get_wield_index()-1):get_name()
	local is_node=(minetest.registered_nodes[Name] or Name == "air")
	local stack_count=player:get_inventory():get_stack("main", player:get_wield_index()-1):get_count()
	local Node= {name=Name}
	if stack_count>diplazer_amount and admin==0 then stack_count=diplazer_amount
	elseif stack_count>diplazer_amount*2 and admin==1 then stack_count=diplazer_amount*2
	end
	if (mode==2 or mode==4) then
		return stack_count
	end
	if is_node and (mode==1 or mode==3) then
		return stack_count
	else
		return 0
	end
end

function T(name,msg,user,admin)
if msg==-1 then
minetest.chat_send_player(name, "To change modes: Use while sneaking  / hold shift and left click")
elseif msg==-2 then 
minetest.chat_send_player(name, "Use while point a player or mob or item/stack to select, then point a block to teleport it.")
return 0
else
Mode={}
Mode[1]="Place "..	getAmount(user, msg,admin) .. " front"
Mode[2]="Dig " .. getAmount(user, msg,admin) .. " nodes front"
Mode[3]="Place " .. getAmount(user, msg,admin) .. " up"
Mode[4]="Dig " .. getAmount(user, msg,admin) .. " nodes down"
Mode[5]="Dig 3x3 nodes"
Mode[6]="Teleport"
Mode[7]="Teleport objects"
Mode[8]="Gravity gun (click to pickup, click it again to drop, right+click to throw it away)"
minetest.chat_send_player(name,"Diplazer Mode" .. msg .. ": ".. Mode[msg])
end
end

local function getLength(a)
	local count = 0
	for _ in pairs(a) do count = count + 1 end
	return count
end


local function USEGgun(meta,user,pointed_thing)
	if meta.mode ~= 8
	or pointed_thing.type ~= "object"
	or not pointed_thing.ref then
		return
	end		-- remove Terget
	local keys = user:get_player_control()
	local player_name=user:get_player_name()
	local len=getLength(diplazer_UserTele)
	local is_removed=0
	if len==0 then len=1 end
	for i=1,len,1 do
		if meta.mode .."?".. player_name==diplazer_UserTele[i] and (not diplazer_Tele[i]==false) then 
			if pointed_thing.ref==diplazer_Tele[i] then
			if diplazer_Tele[i]:is_player()==true then diplazer_Tele[i]:set_physics_override({gravity=1,}) end
				diplazer_Tele[i]=false is_removed=1
				GGunInUse=GGunInUse-1
			end
		end	
	end

	if keys.RMB then
		pointed_thing.ref:setvelocity(vector.multiply(user:get_look_dir(), 30))-- end of keys.RMB
		return 0
	end
	if is_removed==1 then return 0 end
end


minetest.register_on_leaveplayer(function(player)
	local player_name=player:get_player_name()
	local len=getLength(diplazer_UserTele)
	local is_using=0				--Removing from using tp/Ggun
	for i=1,len,1 do
		if ("8?".. player_name==diplazer_UserTele[i]) or ("7?".. player_name==diplazer_UserTele[i]) then
			if not diplazer_Tele[i]==false then
				if diplazer_Tele[i]:is_player()==true then
					diplazer_Tele[i]:set_physics_override({gravity=1}) 
				end
			end
			diplazer_UserTele[i]=false
			diplazer_Tele[i]=false
			GGunInUse=GGunInUse-1
		end
	end
	for i=1,len,1 do				--If not someone is using tp or GGun
		if diplazer_UserTele[i]==false then
			is_using=is_using+1
		end
	end
	if is_using>=len then			--IF not, clear the array to save CPU
		diplazer_UserTele={}
		diplazer_Tele={}
		print("diplazer GGun&Tp is cleaned (" ..  is_using .. " " .. len ..")")
		GGunInUse=0
	else
		print("diplazer GGun&Tp is using (" ..  is_using .. " " .. len ..")")

	end
end)



local function haveGGun(player)
	if player == nil then
		return false
	end
	local inv = player:get_inventory()
	local hotbar = inv:get_list("main")
	for i = 1, 8 do
		if hotbar[i]:get_name() == "diplazer:gun8" or hotbar[i]:get_name() == "diplazer:admin8" then
			local meta = minetest.deserialize(hotbar[i]:get_metadata())
				return true
		end
	end
	return false
end



minetest.register_globalstep(function(dtime)
	if GGunInUse < 1 then
		return
	end
	for i, player in pairs(minetest.get_connected_players()) do
		if haveGGun(player)==true then
			local player_name = player:get_player_name()
			local pos = player:getpos()
			local len=getLength(diplazer_UserTele)
			for i=1,len,1 do
				if "8?".. player_name == diplazer_UserTele[i]
				and diplazer_Tele[i] ~= false then
					if diplazer_Tele[i]:is_player()==true then
						diplazer_Tele[i]:set_physics_override({gravity=0})
					end
					pos.y = pos.y+1.625
					pos = vector.add(pos, vector.multiply(player:get_look_dir(), 4))
					local cpos = diplazer_Tele[i]:getpos()
					if not cpos then
						return
					end
					local vel = vector.subtract(pos, cpos)
					--vel.y = vel.y+1
					vel = vector.multiply(vel, 0.03/dtime)
					--diplazer_Tele[i]:setacceleration(vel)
					diplazer_Tele[i]:setacceleration(vector.zero)
					diplazer_Tele[i]:setvelocity(vel)
					diplazer_Tele[i]:moveto(pos)
				end
			end
		else
			local len=getLength(diplazer_UserTele)
			local player_name = player:get_player_name()
			for i=1,len,1 do
				if "8?".. player_name==diplazer_UserTele[i]
				and diplazer_Tele[i] ~= false then 
					if diplazer_Tele[i]:is_player()==true then diplazer_Tele[i]:set_physics_override({gravity=1}) end
					diplazer_Tele[i]=false
					GGunInUse=GGunInUse-1
				end
			end
		end
	end
end)


local function dig(pos,player)
	local node=minetest.get_node(pos)
	if node.name == "air" or node.name == "ignore" then return end
	if node.name == "default:lava_source" then minetest.remove_node(pos) return end
	if node.name == "default:lava_flowing" then minetest.remove_node(pos) return end
	if node.name == "default:water_source" then minetest.remove_node(pos) return end
	if node.name == "default:water_flowing" then minetest.remove_node(pos) return end
	if node.name == "default:river_water_source" then minetest.remove_node(pos) return end
	if node.name == "default:river_water_flowing" then minetest.remove_node(pos) return end
	minetest.node_dig(pos,node,player)
end

local function getdir (player)
	local dir=player:get_look_dir()
	if math.abs(dir.x)>math.abs(dir.z) then 
		if dir.x>0 then return 0 end
		return 1
	end
	if dir.z>0 then return 2 end
	return 3
end

local function dig2 (pos,player)
	dig (pos,player)
	pos.z=pos.z+1
	dig (pos,player)
	pos.z=pos.z-2
	dig (pos,player)
	pos.z=pos.z+1
	pos.y=pos.y+1
	dig (pos,player)
	pos.z=pos.z+1
	dig (pos,player)
	pos.z=pos.z-2
	dig (pos,player)
	pos.z=pos.z+1
	pos.y=pos.y-2
	dig (pos,player)
	pos.z=pos.z+1
	dig (pos,player)
	pos.z=pos.z-2
	dig (pos,player)
end

local function dig3 (pos,player)
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
	pos.x=pos.x+1
	pos.y=pos.y+1
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
	pos.x=pos.x+1
	pos.y=pos.y-2
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
end

local function dig4 (pos,player)
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
	pos.x=pos.x+1
	pos.z=pos.z+1
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
	pos.x=pos.x+1
	pos.z=pos.z-2
	dig (pos,player)
	pos.x=pos.x+1
	dig (pos,player)
	pos.x=pos.x-2
	dig (pos,player)
end

local function is_protected(pos,player_name)
	if minetest.is_protected(pos, player_name) then
--		minetest.record_protection_violation(pos, player:get_player_name())
		return true
	else
		return false
	end
end

local function use(pos, player, mode,admin)
	local Name=player:get_inventory():get_stack("main", player:get_wield_index()-1):get_name()
	local player_name=player:get_player_name()
	local is_node= not (minetest.registered_nodes[Name] or Name == "air")
	local stack_count=player:get_inventory():get_stack("main", player:get_wield_index()-1):get_count()
	local creative=minetest.setting_getbool("creative_mode")
	local Node= {name=Name}
	local diplazer_amountT=diplazer_amount
	if admin==1 then diplazer_amountT=diplazer_amount*2 end

-- Place front

	if mode == 1 then 							
		if Name=="" or Name==nil or Name=="ignore" or is_node or Name=="default:chest_locked" then
		else
			minetest.sound_play("place", {pos = pos, gain = 1.0, max_hear_distance = diplazer_amount,})
			dir = getdir(player)
			pos.y=pos.y+1
 -- x+
			if dir == 0 then
				for i=1,diplazer_amountT,1 do
					local fn = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

					if fn.name=="air" or fn.name=="default:lava_source" or fn.name=="default:lava_flowing" or fn.name=="default:water_source" or fn.name=="default:water_flowing" then 
						if stack_count>0 then
							minetest.add_node({x=pos.x, y=pos.y, z=pos.z}, Node)
							if not creative and admin==0 then player:get_inventory():remove_item("main", Name) end
							stack_count=stack_count-1
						else
							return 0
						end
					pos.x=pos.x+1
					else
					return false
					end
				end

			end
-- x-
			if dir == 1 then
				for i=1,diplazer_amountT,1 do
				local fn = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

				if fn.name=="air" or fn.name=="default:lava_source" or fn.name=="default:lava_flowing" or fn.name=="default:water_source" or fn.name=="default:water_flowing" then 
						if stack_count>0 then
						minetest.add_node({x=pos.x, y=pos.y, z=pos.z}, Node)
						if not creative and admin==0  then player:get_inventory():remove_item("main", Name) end
						stack_count=stack_count-1
						else
							return 0
						end
					pos.x=pos.x-1
				else
				return false
				end
			end
		end

-- z+
		if dir==2 then
			for i=1,diplazer_amountT,1 do
				local fn = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

				if fn.name=="air" or fn.name=="default:lava_source" or fn.name=="default:lava_flowing" or fn.name=="default:water_source" or fn.name=="default:water_flowing" then 
						if stack_count>0 then
						minetest.add_node({x=pos.x, y=pos.y, z=pos.z}, Node)
						if not creative and admin==0  then player:get_inventory():remove_item("main", Name) end
						stack_count=stack_count-1
						else
							return 0
						end
				pos.z=pos.z+1
				else
				return false
				end
			end
		end
-- z-
	if dir==3 then
		for i=1,diplazer_amountT,1 do
			local fn = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

			if fn.name=="air" or fn.name=="default:lava_source" or fn.name=="default:lava_flowing" or fn.name=="default:water_source" or fn.name=="default:water_flowing" then 
						if stack_count>0 then
						minetest.add_node({x=pos.x, y=pos.y, z=pos.z}, Node)
						if not creative and admin==0  then player:get_inventory():remove_item("main", Name) end
						stack_count=stack_count-1
						else
							return 0
						end
				pos.z=pos.z-1
				else
				return false
				end
			end
		end
	end
end

-- dig Front
	if mode == 2 then
		dir = getdir(player)
		minetest.sound_play("dig", {pos = pos, gain = 1.0, max_hear_distance = diplazer_amount,})
		if dir == 0 then -- x+
			for i=1,diplazer_amountT,1 do
				if stack_count>0 then	
					dig (pos,player)
					stack_count=stack_count-1
				end
				pos.x=pos.x+1
			end
		end
		if dir == 1 then  -- x-
			for i=1,diplazer_amountT,1 do
				if stack_count>0 then	
					dig (pos,player)
					stack_count=stack_count-1
				end
				pos.x=pos.x-1
			end
		end
		if dir==2 then  -- z+
			for i=1,diplazer_amountT,1 do

				if stack_count>0 then	
					dig (pos,player)
					stack_count=stack_count-1
				end
				pos.z=pos.z+1
			end
		end
		if dir==3 then  -- z-
			for i=1,diplazer_amountT,1 do

				if stack_count>0 then	
					dig (pos,player)
					stack_count=stack_count-1
				end
				pos.z=pos.z-1
			end
		end
	end
 -- Place up
	if mode==3 then			
		if Name=="" or Name==nil or Name=="ignore" or is_node or Name=="default:chest_locked" then
		else
			minetest.sound_play("place", {pos = pos, gain = 1.0, max_hear_distance = diplazer_amount,})
			pos.y=pos.y+1
			local stack_count=player:get_inventory():get_stack("main", player:get_wield_index()-1):get_count()
 -- x+
				for i=1,diplazer_amountT,1 do
					local fn = minetest.get_node({x=pos.x, y=pos.y, z=pos.z})

					if fn.name=="air" or fn.name=="default:lava_source" or fn.name=="default:lava_flowing" or fn.name=="default:water_source" or fn.name=="default:water_flowing" then 
						if stack_count>0 then
						minetest.add_node({x=pos.x, y=pos.y, z=pos.z}, Node)
						if not creative and admin==0  then player:get_inventory():remove_item("main", Name) end
						stack_count=stack_count-1
						else
							return 0
						end
					pos.y=pos.y+1
					else
					return false
					end
				end

			end
-- x-
	end
--dig down
	if mode==4 then
		minetest.sound_play("dig", {pos = pos, gain = 1.0, max_hear_distance = diplazer_amount,})
		for i=1,diplazer_amountT,1 do

			if stack_count>0 then
				dig (pos,player)
				stack_count=stack_count-1
			end
			pos.y=pos.y-1
		end
	end
--dig 3 x 3

	if mode==5 then
		local dir=player:get_look_dir()
		minetest.sound_play("dig", {pos = pos, gain = 1.0, max_hear_distance = diplazer_amount,})
		if math.abs(dir.y)<0.5 then
			dir=getdir(player)
				if dir==0 or dir==1 then -- x
					dig2(pos,player)
				end
				if dir==2 or dir==3 then  -- z
					dig3(pos,player)
				end
		else
		dig4(pos,player)
		end
	end

--teleport

	if mode==6 then
		minetest.sound_play("teleport", {pos = pos, gain = 1.1, max_hear_distance = diplazer_amount,})
		player:moveto({ x=pos.x, y=pos.y+1, z=pos.z },false)
	end

--teleport object

	if mode==7 then
		local len=getLength(diplazer_UserTele)
		local player_name = player:get_player_name()
		for i=1,len,1 do
			if mode .."?".. player_name==diplazer_UserTele[i] then
				diplazer_Tele[i]:moveto({ x=pos.x, y=pos.y+1, z=pos.z },false)
				minetest.sound_play("teleport", {pos = pos, gain = 1.1, max_hear_distance = diplazer_amount,})
				return 0
			end
		end
		T(player_name,-2)
	end
end



local function pos_is_pointable(pos)
	local node = minetest.get_node(pos)
	local nodedef = minetest.registered_nodes[node.name]
	return nodedef and nodedef.pointable
end


local function setmode(user,itemstack,admin,keys)
	minetest.sound_play("mode", {pos = pos, gain = 2.0, max_hear_distance = diplazer_amount,})
	local player_name=user:get_player_name()
	local item=itemstack:to_table()
	local meta=minetest.deserialize(item["metadata"])
	if meta==nil then
		meta={}
		mode=0
	end
	if meta["mode"]==nil then
		T(player_name,-1)
		meta["mode"]=0
		mode=0
	end
	mode=(meta["mode"])

	if keys.sneak and keys.jump then mode=mode-1 
	else mode=mode+1
	end

	if mode>=9 then mode=1 end
	if mode<=0 then mode=8 end

	T(player_name,mode,user,admin)

	if admin==0 then
		item["name"]="diplazer:gun"..mode
	else
		item["name"]="diplazer:admin"..mode
	end
	meta["mode"]=mode
	item["metadata"]=minetest.serialize(meta)
	itemstack:replace(item)
	return itemstack
end

local function onuse(itemstack, user, pointed_thing, admin)

if minetest.check_player_privs(user:get_player_name(), {teleport=true})==false and admin==0 then
minetest.chat_send_player(user:get_player_name(), "You need teleport priv to use this tool")
print(user:get_player_name() .. " tried to use diplazer:gun - missing priv: teleport ====WARNING!====")
return 0
end

if minetest.check_player_privs(user:get_player_name(), {give=true})==false and admin==1 then
minetest.chat_send_player(user:get_player_name(), "You need give priv to use this tool")
print(user:get_player_name() .. " tried to use diplazer:admin - missing priv: give ====WARNING!====")
return 0
end

	local keys = user:get_player_control()
	local player_name = user:get_player_name()
	local meta = minetest.deserialize(itemstack:get_metadata())

	if not meta or not meta.mode or keys.sneak or (keys.sneak and keys.jump) then
		return setmode(user, itemstack, admin,keys)
	end
	if pointed_thing.type ~= "node" or not pos_is_pointable(pointed_thing.under) then
	if USEGgun(meta,user,pointed_thing)==0 then return end
		if (meta.mode==7 or meta.mode==8) and pointed_thing.type=="object" and pointed_thing.ref then  -- Set Terget
			local len=getLength(diplazer_UserTele)
			if len==0 then len=1 end
			for i=1,len,1 do
				if meta.mode .."?".. player_name==diplazer_UserTele[i] then 
					GGunInUse=GGunInUse+1
					diplazer_Tele[i]=pointed_thing.ref
					diplazer_UserTele[i]=meta.mode .."?".. player_name
					return 0
				end
			end
			GGunInUse=GGunInUse+1
			table.insert(diplazer_Tele, pointed_thing.ref)
			table.insert(diplazer_UserTele,meta.mode .."?"..  player_name)
			return 0
		end
		if pointed_thing.type=="object" and pointed_thing.ref then -- 		Shoot
			local ob=pointed_thing.ref
			if admin==0 then
			hp=ob:get_hp()-10
			else
			hp=0
			end
			minetest.sound_play("dig", {pos = ob:getpos(), gain = 1.0, max_hear_distance = diplazer_amount,})
			ob:set_hp(hp)
			ob:punch(user,0,"diplazer:gun",getdir(user))
		end
		if pointed_thing.type=="object" and pointed_thing.ref and meta.mode==6 then -- Teleport to object, then shoot
		else
			return
		end
	end
		local pos = minetest.get_pointed_thing_position(pointed_thing, above)
		use(pos, user, meta.mode,admin)
	return itemstack
end

minetest.register_tool("diplazer:gun", {
	description = "Diplazer",
	range = diplazer_amount,
	inventory_image = "diplazer.png",
	groups = {not_in_creative_inventory=1},
	on_use = function(itemstack, user, pointed_thing)
	onuse(itemstack,user,pointed_thing,0)
	return itemstack
	end,
})

minetest.register_tool("diplazer:admin", {
	description = "Diplazer Admin",
	range = diplazer_amount,
	inventory_image = "diplazeradmin.png",
	groups = {not_in_creative_inventory=1},
	on_use = function(itemstack, user, pointed_thing)
	onuse(itemstack,user,pointed_thing,1)
	return itemstack
	end,
})

for i=1,8,1 do
	minetest.register_tool("diplazer:gun" .. i, {
		description = "Diplazer mode ".. i,
		inventory_image = "diplazer.png^diplazer_mode"..i..".png",
		range = diplazer_amount,
		wield_image = "diplazer.png^diplazer_Colmode"..i..".png",
		groups = {not_in_creative_inventory=1},
		on_use = function(itemstack, user, pointed_thing)
		onuse(itemstack,user,pointed_thing,0)
		return itemstack
		end,
	})
	minetest.register_tool("diplazer:admin" .. i, {
		description = "Diplazer Admin mode ".. i,
		inventory_image = "diplazeradmin.png^diplazer_mode"..i..".png",
		range = diplazer_amount,
		wield_image = "diplazeradmin.png^diplazer_Colmode"..i..".png",
		groups = {not_in_creative_inventory=1},
		on_use = function(itemstack, user, pointed_thing)
		onuse(itemstack,user,pointed_thing,1)
		return itemstack
		end,
	})
end
