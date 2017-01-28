-- Minetest 0.4.15+ mod: asteroid cystals
-- namespace: asteroid_crystals
-- (c) 2017 by d.kartaschew

-- Set to true to set trees on fire if the grass gets too close.
local enable_fire = false

local load_start = os.clock()

local namespace = "asteroid_crystals"


-- register black dirt
minetest.register_node( namespace .. ":black_dirt", {
  description = "Black Dirt",
  tiles = { "black_dirt.png" },
  groups = {crumbly=3, soil=1},
  sounds = default.node_sound_dirt_defaults(),
})

-- register black dirt with grass
minetest.register_node( namespace .. ":black_dirt_with_grass", {
  description = "Black Dirt with grass",
  tiles ={"black_dirt_grass.png", "black_dirt.png",
    {name = "black_dirt.png^black_dirt_grass_side.png",
      tileable_vertical = false}},
  groups = {crumbly=3, soil=1},
  drop = namespace .. ":black_dirt",
  sounds = default.node_sound_dirt_defaults(),
})


-- register base crystals
minetest.register_node(namespace .. ":crystal", {
  drawtype = "mesh",
  mesh = "crystal.obj",
  description = "Crystal",
  inventory_image = "astcry_menu_crystal.png",
  tiles = {"astcry_crystal.png"},
  textures = {
    {"astcry_crystal.png"},
  },
  light_source = 20,
  paramtype2 = "facedir",
  groups = {snappy=3},
  walkable = false,
  sunlight_propagates = true,
  use_texture_alpha = true,
  is_ground_content = false,
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
  sounds = default.node_sound_glass_defaults(),
  on_place = minetest.rotate_node
})

-- base tree block
minetest.register_node(namespace .. ":crystal_tree", {
  description = "Crystal Tree",
  --drawtype = "allfaces",
  tiles = {"astcry_crystal_tree_top.png", "astcry_crystal_tree_top.png", "astcry_crystal_tree.png",
    "astcry_crystal_tree.png", "astcry_crystal_tree.png", "astcry_crystal_tree.png"},
  paramtype = "light",
  is_ground_content = false,
  groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1},
  sounds = default.node_sound_glass_defaults(),
  on_place = minetest.rotate_node,
  light_source = 20,
  use_texture_alpha = true,
})

-- base leaves
minetest.register_node(namespace .. ":crystal_leaves", {
  description = "Crystal Leaves",
  drawtype = "allfaces_optional",
  waving = 1,
  tiles = {"astcry_crystal_leaves.png"},
  paramtype = "light",
  is_ground_content = false,
  light_source = 50,
  groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
  drop = {
    max_items = 1,
    items = {
      {
        -- player will get base crystal with 1/20 chance
        items = {namespace .. ":crystal"},
        rarity = 20,
      },
      {
        -- player will get leaves only if he get no saplings,
        -- this is because max_items is 1
        items = {namespace .. ":crystal_leaves"},
      }
    }
  },
  sounds = default.node_sound_leaves_defaults(),

  after_place_node = default.after_place_leaves,
})

-- Allow black dirt to turn
minetest.register_abm({
  nodenames = { namespace .. ":black_dirt"},
  interval = 5,
  chance = 50,
  action = function(pos, node)
    local above = {x=pos.x, y=pos.y+1, z=pos.z}
    local name = minetest.get_node(above).name
    local nodedef = minetest.registered_nodes[name]
    if nodedef and (nodedef.sunlight_propagates or nodedef.paramtype == "light")
      and nodedef.liquidtype == "none"
      and (minetest.get_node_light(above) or 0) >= 10 then
      minetest.set_node(pos, {name = namespace .. ":black_dirt_with_grass"})
    end
  end
})

-- Allow the black dirt to spread, and turn grass into crystals
minetest.register_abm({
  nodenames = { namespace .. ":black_dirt_with_grass"},
  interval = 2,
  chance = 5,
  action = function(pos, node)
    for dx=-1,1,1 do
      for dy=-1,1,1 do
        for dz=-1,1,1 do
          if not (dz == 0 and dx == 0 and dy == 0 ) then
            local nodepos = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
            local name = minetest.get_node(nodepos).name
            if name == "default:dirt" or
              name == "default:dirt_with_grass" or
              name == "default:dirt_with_grass_footsteps" or
              name == "default:dirt_with_dry_grass" or
              name == "default:dirt_with_snow" or
              name == "default:sand" or
              name == "default:desert_sand" or
              name == "default:silver_sand" then
              minetest.set_node(nodepos, {name = namespace .. ":black_dirt"})
            end
            if enable_fire then
              if name == "default:tree" or
                name == "default:jungletree" or
                name == "default:aspen_tree" or
                name == "default:acacia_tree" or
                name == "default:pine_tree" or
                name == "default:leaves" or
                name == "default:jungleleaves" or
                name == "default:acacia_leaves" or
                name == "default:aspen_leaves" or
                name == "default:pine_needles" then
                minetest.set_node(nodepos, {name = "fire:basic_flame"})
              end
            end
            if name == "default:grass_1" or
              name == "default:grass_2" or
              name == "default:grass_3" or
              name == "default:grass_4" or
              name == "default:grass_5" or
              name == "default:dry_grass_1" or
              name == "default:dry_grass_2" or
              name == "default:dry_grass_3" or
              name == "default:dry_grass_4" or
              name == "default:dry_grass_5" or
              name == "default:dry_shrub" or
              name == "default:junglegrass" then
              minetest.set_node(nodepos, {name = namespace .. ":crystal"})
            end
          end
        end
      end
    end
  end
})

local function set_crystal_nodes(pos, branch, nodeName)
  for i = 1,#branch do
    local nodepos = {x=pos.x+(branch[i][1]), y=pos.y+(branch[i][2]), z=pos.z+(branch[i][3])}
    minetest.set_node(nodepos, {name = nodeName})
  end
end

-- Grow a tree function.
local function grow_crystal_tree(pos)
  -- grow center trunk
  for dy=0,9,1 do
    local nodepos = {x=pos.x, y=pos.y+dy, z=pos.z}
    minetest.set_node(nodepos, {name = namespace .. ":crystal_tree"})
  end
  -- grow first branch
  set_crystal_nodes(pos, {{1, 5, 1}, {1,5,-1}, {-1, 5, 1}, {-1, 5, -1}}, (namespace .. ":crystal_tree"))
  -- grow second branch
  set_crystal_nodes(pos, {{0, 8, 1}, {0,8,-1}, {1, 8, 0}, {-1, 8, 0}}, (namespace .. ":crystal_tree"))
  -- grow first branch leaves
  set_crystal_nodes(pos, {{2, 4, 2}, {3,3,3}, {3, 2, 3}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{2, 4, -2}, {3,3,-3}, {3, 2, -3}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{-2, 4, -2}, {-3,3,-3}, {-3, 2, -3}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{-2, 4, 2}, {-3,3,3}, {-3, 2, 3}}, (namespace .. ":crystal_leaves"))
  -- grow second branch leaves
  set_crystal_nodes(pos, {{0,7,2},{0,6,3},{0,5,3},{0,4,3}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{0,7,-2},{0,6,-3},{0,5,-3},{0,4,-3}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{2,7,0},{3,6,0},{3,5,0},{3,4,0}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{-2,7,0},{-3,6,0},{-3,5,0},{-3,4,0}}, (namespace .. ":crystal_leaves"))
  -- grow top branch leaves
  set_crystal_nodes(pos, {{1,10,1},{1,10,-1},{-1,10,-1},{-1,10,1}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{2,9,2},{2,9,-2},{-2,9,-2},{-2,9,2}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{2,8,2},{2,8,-2},{-2,8,-2},{-2,8,2}}, (namespace .. ":crystal_leaves"))
  set_crystal_nodes(pos, {{2,7,2},{2,7,-2},{-2,7,-2},{-2,7,2}}, (namespace .. ":crystal_leaves"))
end

-- Turn a crystal into a tree...
minetest.register_abm({
  nodenames = { namespace .. ":crystal"},
  interval = 5,
  chance = 10,
  action = function(pos, node)
    local above = {x=pos.x, y=pos.y+1, z=pos.z}
    local name = minetest.get_node(above).name
    local nodedef = minetest.registered_nodes[name]
    if nodedef
      and (nodedef.sunlight_propagates or nodedef.paramtype == "light")
      and nodedef.liquidtype == "none"
      and (minetest.get_node_light(above) or 0) >= 10 then
      grow_crystal_tree(pos)
    end
  end
})

if minetest.setting_getbool("log_mods") then
  print(("[AsteroidCrystals] Loaded in %f seconds"):format(os.clock() - load_start))
end

