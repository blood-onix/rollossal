--!strict
-- Content tests for src/shared/Content/Worlds/MainStreetSlice.luau (010; contracts/slice-world-and-flags.md
-- guarantees 1 to 9 and contracts/signs-and-billboards.md validation 1 to 6). Expected numbers are written out by hand
-- from the spec, not read from the data under test.

local harness = require("./harness")
local Assets = require("../../src/shared/Assets")
local Config = require("../../src/shared/Config")
local Downtown = require("../../src/shared/Content/Worlds/Downtown")
local MainStreetSlice = require("../../src/shared/Content/Worlds/MainStreetSlice")
local SceneKit = require("../../src/shared/Rules/SceneKit")
local SceneKits = require("../../src/shared/Content/SceneKits")
local Signs = require("../../src/shared/Content/Signs")
local StreetRules = require("../../src/shared/Rules/StreetRules")
local Themes = require("../../src/shared/Content/Themes")
local ThemeResolve = require("../../src/shared/Rules/ThemeResolve")
local Layout = require("../../src/shared/Rules/Layout")

local test, expect = harness.test, harness.expect

local TIER_CEILINGS = { 5, 12, 30, 70, 150 }
local KIT_IDS = {
	"picnic_spread",
	"cafe_terrace",
	"bus_stop",
	"fruit_stall",
	"bike_rack",
	"road_works",
	"car_park_rows",
	"yard_sale",
	"flower_bed",
	"recycling_point",
}
local SLICE_OBJECTS =
	{ "shop_front", "fruit_crate", "flower_pot", "picnic_blanket", "awning", "road_barrier" }

local function build(): any
	return MainStreetSlice.build({
		StreetRules = StreetRules,
		SceneKit = SceneKit,
		SceneKits = SceneKits,
		Signs = Signs,
		Downtown = Downtown,
	})
end

local world = build()

local objectById: { [string]: any } = {}
for _, object in world.objects do
	objectById[object.id] = object
end

-- A footprint is the object's size on a side (a square); blocks are rotated by their yaw, so use the circumscribing box.
local function insideBlock(x: number, z: number, margin: number): boolean
	for _, b in world.environment.blocks do
		if
			b.kind ~= "Boundary"
			and b.cframe.y + b.size.y / 2 > 0.5
			and b.cframe.y - b.size.y / 2 < 0.5
		then
			local yaw = math.rad(b.cframe.yaw)
			local dx, dz = x - b.cframe.x, z - b.cframe.z
			local lx = dx * math.cos(yaw) - dz * math.sin(yaw)
			local lz = dx * math.sin(yaw) + dz * math.cos(yaw)
			if math.abs(lx) < b.size.x / 2 + margin and math.abs(lz) < b.size.z / 2 + margin then
				return true
			end
		end
	end
	return false
end

test("Slice: identity and extents", function()
	expect.equal(world.worldId, "main_street_slice")
	expect.equal(world.halfExtent, 250)
	expect.equal(world.outerHalfExtent, 300)
	expect.equal(world.maxPlacements, 1200)
	expect.equal(world.activeThemeId, "city")
	expect.equal(#world.zones, 0)
	expect.truthy(
		world.ambient ~= nil and world.ambient.pigeons ~= nil and world.ambient.traffic == nil
	)
end)

test("Slice: boundary blocks stand at x = +-100 and z = +-250", function()
	local seen = { e = false, w = false, n = false, s = false }
	for _, b in world.environment.blocks do
		if b.kind == "Boundary" then
			if math.abs(b.cframe.x - 100.5) < 0.01 then
				seen.e = true
			elseif math.abs(b.cframe.x + 100.5) < 0.01 then
				seen.w = true
			elseif math.abs(b.cframe.z - 250.5) < 0.01 then
				seen.n = true
			elseif math.abs(b.cframe.z + 250.5) < 0.01 then
				seen.s = true
			end
		end
	end
	expect.truthy(seen.e and seen.w and seen.n and seen.s)
end)

test("Slice: everything is inside x in [-100, 100] and z in [-250, 250]", function()
	for _, p in world.fixedPlacements do
		expect.truthy(math.abs(p.x) <= 100 and math.abs(p.z) <= 250, p.id)
	end
	for _, b in world.environment.blocks do
		if b.kind ~= "Boundary" then
			local c, s = b.cframe, b.size
			local turned = math.abs(math.sin(math.rad(c.yaw))) > 0.5
			local hx = (if turned then s.z else s.x) / 2
			local hz = (if turned then s.x else s.z) / 2
			expect.truthy(c.x - hx >= -100.01 and c.x + hx <= 100.01, b.id)
			expect.truthy(c.z - hz >= -250.01 and c.z + hz <= 250.01, b.id)
		end
	end
end)

test("Slice: twelve spawns, 10 studs apart, facing +z, clear of solids", function()
	expect.equal(#world.spawnPoints, 12)
	local slots: { [number]: boolean } = {}
	for _, a in world.spawnPoints do
		slots[a.slot] = true
		expect.truthy(math.abs(a.yaw) <= 30, "spawn yaw")
		expect.truthy(a.z <= -130, "spawns are in the park")
		expect.truthy(not insideBlock(a.x, a.z, 1), `spawn {a.slot} is inside a solid`)
		for _, b in world.spawnPoints do
			if a.slot < b.slot then
				local d = math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
				expect.truthy(d >= 10, `spawns {a.slot} and {b.slot} are {d} apart`)
			end
		end
		for _, p in world.fixedPlacements do
			local o = objectById[p.objectId]
			if o.tier >= 2 then
				local d = math.sqrt((a.x - p.x) ^ 2 + (a.z - p.z) ^ 2)
				expect.truthy(d > o.size / 2 + 1, `{p.id} sits on spawn {a.slot}`)
			end
		end
	end
	for slot = 1, 12 do
		expect.truthy(slots[slot], `slot {slot}`)
	end
end)

test("Slice: every spawn has a tier 1 pickup within 15 studs", function()
	for _, a in world.spawnPoints do
		local near = false
		for _, p in world.fixedPlacements do
			if objectById[p.objectId].tier == 1 then
				if math.sqrt((a.x - p.x) ^ 2 + (a.z - p.z) ^ 2) <= 15 then
					near = true
					break
				end
			end
		end
		expect.truthy(near, `spawn {a.slot}`)
	end
end)

test("Slice: zones run park, suburb, main street, skyline along z", function()
	local firstFacade = math.huge
	for _, b in world.environment.blocks do
		if string.match(b.id, "^ms_fac_") then
			firstFacade = math.min(firstFacade, b.cframe.z - b.size.z / 2)
		end
	end
	expect.truthy(firstFacade >= -60, "facades start at z >= -60")
	for _, p in world.fixedPlacements do
		if string.match(p.id, "^ms_sky_") then
			expect.truthy(p.z >= 170, p.id)
			expect.equal(objectById[p.objectId].tier, 5)
		end
		if string.match(p.id, "^ms_shop_") then
			expect.truthy(p.z >= -60 and p.z <= 170, p.id)
		end
		if string.match(p.id, "^ms_trail_") then
			expect.truthy(p.z <= -130, p.id)
		end
	end
end)

test("Slice: placement count is within the budget and ids are unique", function()
	expect.truthy(
		#world.fixedPlacements <= world.maxPlacements,
		`{#world.fixedPlacements} placements`
	)
	expect.truthy(#world.fixedPlacements >= 600, "the street is dressed")
	local seen: { [string]: boolean } = {}
	for _, p in world.fixedPlacements do
		expect.truthy(not seen[p.id], `duplicate id {p.id}`)
		seen[p.id] = true
		expect.truthy(objectById[p.objectId] ~= nil, `unknown object {p.objectId}`)
	end
	local blockIds: { [string]: boolean } = {}
	for _, b in world.environment.blocks do
		expect.truthy(not blockIds[b.id], `duplicate block {b.id}`)
		blockIds[b.id] = true
	end
end)

test("Slice: object sizes obey the absorb ratio, and the six slice objects are defined", function()
	for _, object in world.objects do
		expect.truthy(
			object.size <= Config.absorbRatio * TIER_CEILINGS[object.tier] + 1e-9,
			`{object.id} is too big for tier {object.tier}`
		)
		expect.truthy(object.coins > 0)
	end
	for _, id in SLICE_OBJECTS do
		local object = objectById[id]
		expect.truthy(object ~= nil, id)
		expect.equal(object.bookId, "slice." .. id)
		expect.equal(object.nameKey, "object.slice." .. id)
	end
end)

test("Slice: all ten scene kits appear", function()
	for _, id in KIT_IDS do
		local found = false
		for _, p in world.fixedPlacements do
			if string.match(p.id, "^ms_kit_%d+_" .. id .. "_%d+$") then
				found = true
				break
			end
		end
		expect.truthy(found, `kit {id}`)
	end
end)

test("Slice: building is deterministic", function()
	local again = build()
	expect.equal(#again.fixedPlacements, #world.fixedPlacements)
	for index, p in world.fixedPlacements do
		local q = again.fixedPlacements[index]
		expect.equal(q.id, p.id)
		expect.equal(q.x, p.x)
		expect.equal(q.z, p.z)
		expect.equal(q.yaw, p.yaw)
	end
	expect.equal(#again.environment.blocks, #world.environment.blocks)
	for index, b in world.environment.blocks do
		expect.equal(again.environment.blocks[index].id, b.id)
		expect.equal(again.environment.blocks[index].cframe.x, b.cframe.x)
	end
end)

test("Slice: every block swatch exists in the city palette", function()
	for _, b in world.environment.blocks do
		if b.kind ~= "Boundary" then
			expect.truthy(Themes.city.palette[b.swatch] ~= nil, `{b.id}: {b.swatch}`)
		end
	end
end)

test("Slice: the city theme resolves it with the Layout expander", function()
	local result = ThemeResolve.resolve(world, Themes.city, Layout.expand, 1500)
	expect.equal(#result.placements, #world.fixedPlacements)
end)

test("Slice: every object has an English and a Spanish name", function()
	local Strings = require("../../src/shared/Localization/Strings")
	for _, id in SLICE_OBJECTS do
		local entry = (Strings :: { [string]: { en: string, es: string? } })[objectById[id].nameKey]
		expect.truthy(entry ~= nil and entry.en ~= "" and entry.es ~= nil and entry.es ~= "", id)
	end
end)

-- Signs and billboards ------------------------------------------------------------------------------------------

local BANNED = {
	"roblox",
	"robux",
	"blox",
	"nike",
	"adidas",
	"coca",
	"cola",
	"pepsi",
	"mcdonald",
	"starbucks",
	"apple",
	"google",
	"amazon",
	"lego",
	"disney",
	"nintendo",
	"sony",
	"ikea",
	"beer",
	"wine",
	"vodka",
	"whisky",
	"whiskey",
	"liquor",
	"brewery",
	"casino",
	"poker",
	"bet365",
	"lottery",
	"flag",
	"meme",
	"pepe",
	"doge",
}

local function clean(text: string): boolean
	local lower = string.lower(text)
	for _, word in BANNED do
		if string.find(lower, word, 1, true) ~= nil then
			return false
		end
	end
	return true
end

test("Signs: every facadeId is a facade in the world and every sign is unique", function()
	local facades: { [string]: boolean } = {}
	for _, b in world.environment.blocks do
		if string.match(b.id, "^ms_fac_[rl]_%d+$") then
			facades[b.id] = true
		end
	end
	expect.equal(#Signs.signSlots, 14)
	local ids: { [string]: boolean } = {}
	for _, slot in Signs.signSlots do
		expect.truthy(facades[slot.facadeId], `{slot.id}: no facade {slot.facadeId}`)
		expect.truthy(not ids[slot.id], slot.id)
		ids[slot.id] = true
	end
end)

test("Signs: atlas regions are known, plates exist and sit on the facade", function()
	local known: { [string]: boolean } = {}
	for _, region in Signs.regions do
		known[region] = true
	end
	local plates: { [string]: any } = {}
	for _, b in world.environment.blocks do
		plates[b.id] = b
	end
	for _, slot in Signs.signSlots do
		expect.truthy(known[slot.atlasRegion], slot.id)
		expect.truthy(Signs.regionSwatch[slot.atlasRegion] ~= nil, slot.id)
		expect.truthy(plates[slot.id .. "_plate"] ~= nil, slot.id)
		-- A sign is in front of its facade's face at |x| = 31.6 and within its 24 studs of frontage.
		local facade = plates[slot.facadeId]
		expect.truthy(math.abs(slot.z - facade.cframe.z) <= 12, slot.id)
		expect.truthy(math.abs(slot.x) < 31.6, slot.id)
	end
end)

test(
	"Billboards: keys are in Assets.billboards, at most the texture cap, never sponsored",
	function()
		local distinct: { [string]: boolean } = {}
		local count = 0
		expect.equal(#Signs.billboards, 6)
		for _, slot in Signs.billboards do
			expect.truthy(
				(Assets.billboards :: { [string]: string })[slot.imageAsset] ~= nil,
				slot.id
			)
			expect.truthy(Signs.imageSwatch[slot.imageAsset] ~= nil, slot.id)
			expect.equal(slot.sponsored, false)
			if not distinct[slot.imageAsset] then
				distinct[slot.imageAsset] = true
				count += 1
			end
		end
		expect.truthy(count <= Config.billboardTextureCap, `{count} textures`)
	end
)

test("Signs: shop names and billboard ids pass the banned list", function()
	for _, slot in Signs.signSlots do
		expect.truthy(clean(slot.shopName), slot.shopName)
		expect.truthy(clean(slot.id), slot.id)
	end
	for _, slot in Signs.billboards do
		expect.truthy(clean(slot.id), slot.id)
		expect.truthy(clean(slot.imageAsset), slot.imageAsset)
	end
end)

test("Signs: every slot lies inside the world bounds", function()
	for _, slot in Signs.signSlots do
		expect.truthy(math.abs(slot.x) <= 100 and math.abs(slot.z) <= 250 and slot.y > 0, slot.id)
	end
	for _, slot in Signs.billboards do
		expect.truthy(math.abs(slot.x) <= 100 and math.abs(slot.z) <= 250 and slot.y > 0, slot.id)
	end
end)
