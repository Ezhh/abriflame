
local function smoke(pos, node, clicker, enable)
	local meta = minetest.get_meta(pos)
	local handler = meta:get_int("sound")
	local particle = meta:get_int("smoke")

	if particle ~= 0 or enable ~= true then
		if handler then
			minetest.sound_stop(handler)
		end
		minetest.delete_particlespawner(particle)
		meta:set_int("smoke", 0)
		meta:set_int("sound", 0)
		return
	end

	if minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z}).name ~= "air" or particle ~= 0 then
		return
	end

	particle = minetest.add_particlespawner({
		amount = 4,
		time = 0,
		collisiondetection = true,
		minpos = {x = pos.x - 0.25, y = pos.y + 0.4, z = pos.z-0.25},
		maxpos = {x = pos.x + 0.25, y = pos.y + 5, z = pos.z + 0.25},
		minvel = {x = -0.2, y = 0.3, z = -0.2},
		maxvel = {x = 0.2, y = 1, z = 0.2},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0.5, z = 0},
		minexptime = 1,
		maxexptime = 3,
		minsize = 4,
		maxsize = 8,
		texture = "smoke_particle.png",
	})

	handler = minetest.sound_play("fire_small", {
		pos = pos,
		max_hear_distance = 5,
		loop = true
	})

	meta:set_int("smoke", particle)
	meta:set_int("sound", handler)
end


-- flame types
local flame_types = {
	"green", "yellow", "black", "orange", "cyan",
	"magenta", "purple", "blue", "red", "frosted"
}

for _, f in pairs(flame_types) do
	minetest.register_node("abriflame:" .. f .. "_fire", {
		inventory_image = f .. "_fire_inv.png",
		wield_image = f .. "_fire_inv.png",
		description = f .. " fire",
		drawtype = "plantlike",
		paramtype = "light",
		groups = {dig_immediate = 3, not_in_creative_inventory = 1},
		sunlight_propagates = true,
		buildable_to = true,
		walkable = false,
		light_source = 14,
		waving = 1,
		drop = "",
		tiles = {{
			name = f .. "_fire_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}},

		on_rightclick = function (pos, node, clicker)
			smoke(pos, node, clicker, true)
		end,

		on_destruct = function (pos)
			smoke(pos, nil, nil, false)
			minetest.sound_play("fire_extinguish_flame", {
				pos = pos,
				max_hear_distance = 5,
				gain = 0.25
			})
		end,
	})
end


-- fire starter tool
minetest.register_tool("abriflame:flint", {
	description = "Fire Starter",
	inventory_image = "fire_flint_steel.png",
	stack_max = 1,
	liquids_pointable = false,

	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = ({x = pointed_thing.under.x,
			y = pointed_thing.under.y + 1,
			z = pointed_thing.under.z})

		if minetest.get_node(pos).name ~= "air" or
				minetest.is_protected(pos, user:get_player_name()) or
				minetest.is_protected(pointed_thing.above, user:get_player_name()) then
			return itemstack
		end

		local node = minetest.get_node(pointed_thing.under).name
		local nodesplit, namesplit = node:split(":"), {}
		if #nodesplit == 2 then
			namesplit = nodesplit[2]:split("_")
		end

		if nodesplit[1] == "abriglass" and #namesplit == 3 and namesplit[1] == "stained" then
			minetest.set_node(pos, {name = "abriflame:" .. namesplit[3] .. "_fire"})
		end

		itemstack:add_wear(65535 / 65)
		return itemstack
	end,
})


-- fire starter tool recipe
minetest.register_craft({
	output = "abriflame:flint",
	recipe = {
		{"default:mese_crystal_fragment", "default:steel_ingot"}
	}
})
