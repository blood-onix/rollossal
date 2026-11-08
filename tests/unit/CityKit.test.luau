--!strict
-- Content checks for src/shared/Content/CityKit.luau and the strings that name it (013). The ranges are written out
-- by hand from specs/013-city-asset-kit/data-model.md, not read from the data under test.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")
local CityKit = require("../../src/shared/Content/CityKit")
local CityKitStrings = require("../../src/shared/Localization/CityKitStrings")
local Config = require("../../src/shared/Config")

local test, expect = harness.test, harness.expect

local ZONE_COUNTS: { [string]: number } = {
	building = 25,
	street = 21,
	park = 22,
	suburbs = 15,
	mainstreet = 13,
	downtown = 11,
	signage = 7,
	meme = 7,
}
-- Tier size bands (studs): T1 0.3 to 1.5, T2 1.6 to 3.9, T3 4.2 to 9.8, T4 10 to 25, T5 26 to 60.
local SIZE_BANDS = { { 0.3, 1.5 }, { 1.6, 3.9 }, { 4.2, 9.8 }, { 10, 25 }, { 26, 60 } }
local TIER_CEILINGS = { 5, 12, 30, 70, 150 }
local TARGET_SHARE = 0.6
local FLOORS: { [string]: number } = { pocket = 40, flat = 24, panel = 150 }
local TIER_FLOORS = { 150, 210, 450, 1050, 1500 }

local objects = CityKit.objects
test("CityKit: 121 objects, unique ids, keyed ck_ and named object.citykit.<id>", function()
	expect.equal(#objects, 121)
	local seen: { [string]: boolean } = {}
	for _, object in objects do
		expect.falsy(seen[object.id], object.id)
		seen[object.id] = true
		expect.equal(object.assetKey, "ck_" .. object.id)
		expect.equal(object.nameKey, "object.citykit." .. object.id)
		expect.equal(object.bookId, "citykit." .. object.id)
		expect.truthy(string.match(object.id, "^[a-z0-9_]+$") ~= nil, object.id)
		expect.falsy(object.light, object.id)
	end
end)

test("CityKit: zone counts match the asset list", function()
	local counts: { [string]: number } = {}
	for _, object in objects do
		local zone = object.zone :: string
		counts[zone] = (counts[zone] or 0) + 1
	end
	for zone, expected in ZONE_COUNTS do
		expect.equal(counts[zone] or 0, expected, zone)
	end
end)

test("CityKit: new meshes by tier are T1 15, T2 29, T3 23, T4 34, T5 20", function()
	local expected = { 15, 29, 23, 34, 20 }
	local counts = { 0, 0, 0, 0, 0 }
	for _, object in objects do
		counts[object.tier] += 1
	end
	for tier, count in expected do
		expect.equal(counts[tier], count, `tier {tier}`)
	end
end)

test("CityKit: every size sits in its tier band and under the absorb ceiling", function()
	for _, object in objects do
		local band = SIZE_BANDS[object.tier]
		expect.truthy(band ~= nil, object.id)
		expect.truthy(
			object.size >= band[1] and object.size <= band[2],
			`{object.id} size {object.size} outside tier {object.tier}`
		)
		expect.truthy(
			object.size <= Config.absorbRatio * TIER_CEILINGS[object.tier],
			`{object.id} is too big to be absorbed in tier {object.tier}`
		)
		local dims = object.dims :: { number }
		expect.equal(math.max(dims[1], dims[2], dims[3]), object.size, `{object.id} longest dim`)
	end
end)

test("CityKit: the class floor sits under 60 % of the tier budget for every object", function()
	for _, object in objects do
		local class = CityKit.floorClass[object.id]
		expect.truthy(class ~= nil, object.id)
		local floor = FLOORS[class] or TIER_FLOORS[object.tier]
		expect.truthy(
			floor <= Config.Budgets.meshTriangles[object.tier] * TARGET_SHARE,
			`{object.id} floor {floor}`
		)
	end
end)

test(
	"CityKit: the playground in default placements is the swing set and the slide (style bible section 7)",
	function()
		local ids: { [string]: boolean } = {}
		for _, object in objects do
			ids[object.id] = true
		end
		for id in CityKit.notDefault do
			expect.truthy(ids[id], id)
		end
		for _, id in { "seesaw", "climbing_frame", "sandpit" } do
			expect.truthy(CityKit.notDefault[id], id)
		end
		expect.falsy(CityKit.notDefault.swing_set)
		expect.falsy(CityKit.notDefault.slide)
	end
)

test("CityKit: the twelve urban props of the content mix are in the catalogue", function()
	local ids: { [string]: boolean } = {}
	for _, object in objects do
		ids[object.id] = true
	end
	for _, id in
		{
			"traffic_lights",
			"parking_meter",
			"scooter_dock",
			"food_truck",
			"phone_repair_kiosk",
			"neon_sign",
			"scaffolding",
			"skip",
			"water_tank",
			"car_sports",
			"taxi",
			"motorbike",
		}
	do
		expect.truthy(ids[id], id)
	end
end)

test("CityKit: every building class has at least four variants", function()
	local classes: { [string]: number } = { house = 0, shop = 0, midrise = 0, tower = 0 }
	for _, object in objects do
		if object.zone == "building" then
			local prefix = string.match(object.id, "^(%a+)_") :: string
			classes[prefix] += 1
		end
	end
	expect.equal(classes.house, 6)
	expect.equal(classes.shop, 9)
	expect.equal(classes.midrise, 6)
	expect.equal(classes.tower, 4)
end)

test(
	"CityKit: only the 17 shop, billboard and buffering-billboard meshes use the fronts atlas",
	function()
		local fronts = 0
		for _, object in objects do
			local isShop = string.sub(object.id, 1, 5) == "shop_"
			local isBillboard = string.sub(object.id, 1, 10) == "billboard_"
				or object.id == "meme_buffering_billboard"
			expect.equal(object.atlas == "fronts", isShop or isBillboard, object.id)
			if object.atlas == "fronts" then
				fronts += 1
			end
		end
		expect.equal(fronts, 17)
	end
)

test("CityKit: every name has English and Spanish text and no stray strings exist", function()
	local keys = 0
	for key in CityKitStrings :: { [string]: unknown } do
		keys += 1
		expect.truthy(string.sub(key, 1, 15) == "object.citykit.", key)
	end
	expect.equal(keys, 121)
	for _, object in objects do
		local texts = (CityKitStrings :: any)[object.nameKey]
		expect.truthy(texts ~= nil, object.nameKey)
		expect.truthy(type(texts.en) == "string" and #texts.en > 0, object.nameKey)
		expect.truthy(type(texts.es) == "string" and #texts.es > 0, object.nameKey)
	end
end)

-- ---------------------------------------------------------------- memes (FR-008, FR-009)

local MEME_SLOTS: { [string]: number } = {
	meme_wet_floor_sign = 2,
	meme_pond_cart = 3,
	meme_cone_statue = 4,
	meme_phone_1pc = 4,
	meme_buffering_billboard = 4,
	meme_banana_scale = 5,
	meme_vacant_lot = 5,
}
local ANIMATE_ROLES = { "animal", "person", "character" }
-- The cosmetics keep-out list (04-player-cosmetics.md) plus the named brainrot characters (contract).
local MEME_KEEP_OUT = {
	"nyan",
	"doge",
	"grumpy",
	"troll",
	"pepe",
	"this is fine",
	"among us",
	"crewmate",
	"skibidi",
	"rickroll",
	"crab rave",
	"gigachad",
	"meme man",
	"tralalero",
	"bombardiro",
	"tung tung",
	"sahur",
	"ballerina",
	"cappuccina",
	"chimpanzini",
	"brr brr",
	"patapim",
	"lirili",
	"larila",
}

test("CityKit memes: exactly seven inanimate originals at the slot tiers", function()
	local memes = 0
	for _, object in objects do
		if object.zone == "meme" then
			memes += 1
			expect.truthy(MEME_SLOTS[object.id] ~= nil, object.id)
			expect.equal(object.tier, MEME_SLOTS[object.id], object.id)
			for _, animate in ANIMATE_ROLES do
				expect.truthy(object.role ~= animate, object.id)
			end
			expect.truthy(string.sub(object.role :: string, 1, 2) == "w-", object.id)
		end
	end
	expect.equal(memes, 7)
end)

test("CityKit memes: no name holds a keep-out term, in either language", function()
	for id in MEME_SLOTS do
		local texts = (CityKitStrings :: any)["object.citykit." .. id]
		for _, text in { texts.en, texts.es } do
			local lower = string.lower(text)
			for _, term in MEME_KEEP_OUT do
				expect.falsy(string.find(lower, term, 1, true), `{id}: "{text}" holds "{term}"`)
			end
		end
	end
end)

-- ---------------------------------------------------------------- the audit (FR-001, SC-001)

local AUDIT = "specs/013-city-asset-kit/audit/audit.json"
local REWORKED = { dt_fairy_light_bulb = true, dt_ice_lolly = true, dt_tennis_ball = true }

test(
	"Audit: 99 dt_ entries with valid verdicts, reasons and headroom under the ceilings",
	function()
		expect.truthy(fs.isFile(AUDIT))
		local audit = serde.decode("json", fs.readFile(AUDIT))
		local manifest = serde.decode("json", fs.readFile("art/export/manifest.json"))
		local triangles: { [string]: number } = {}
		for _, mesh in manifest.meshes do
			triangles[mesh.id] = mesh.triangles
		end
		expect.equal(#audit.meshes, 99)
		local seen: { [string]: boolean } = {}
		local verdicts = { keep = true, upgrade = true, replace = true }
		for _, mesh in audit.meshes do
			expect.truthy(string.sub(mesh.id, 1, 3) == "dt_", mesh.id)
			expect.falsy(seen[mesh.id], mesh.id)
			seen[mesh.id] = true
			-- audit.json is the baseline before the rebuild: kept meshes still match the manifest, rebuilt ones grew (the kiosk only past its baseline, its floor does not fit the N10 ceilings)
			-- three baseline keeps were rebuilt on purpose by the Phase 9 pocket rework (art/scripts/kit_stage_c.py); they
			-- only have to stay at or above their floor (audit_report.py REWORKED)
			if mesh.verdict == "keep" and not REWORKED[mesh.id] then
				expect.equal(mesh.triangles, triangles[mesh.id], mesh.id)
			elseif mesh.id == "dt_kiosk" then
				expect.truthy(triangles[mesh.id] > mesh.triangles, mesh.id)
			else
				expect.truthy(triangles[mesh.id] >= mesh.floor, mesh.id)
			end
			expect.truthy(verdicts[mesh.verdict], mesh.id)
			if mesh.verdict ~= "keep" then
				expect.truthy(#mesh.reason >= 40, mesh.id)
			else
				expect.truthy(mesh.fillRatio >= 1, mesh.id)
			end
			expect.truthy(mesh.seasonShare.city < 0.15 or mesh.verdict ~= "keep", mesh.id)
			expect.truthy(mesh.seasonShare.winter < 0.15 or mesh.verdict ~= "keep", mesh.id)
		end
		expect.truthy(audit.headroom.unculled <= 550000)
		expect.truthy(audit.headroom.culled <= 290000)
	end
)

-- ---------------------------------------------------------------- shop names and billboards (FR-005, FR-006)

local NAMES_PATH = "docs/design/shop-names.json"
local FRONTS_PATH = "art/atlases/fronts/fronts.json"

local function squash(text: string): string
	return (string.gsub(string.lower(text), "[^%a%d]", ""))
end

local function words(text: string): { [string]: boolean }
	local found: { [string]: boolean } = {}
	for word in string.gmatch(string.lower(text), "%a+") do
		found[word] = true
	end
	return found
end

-- True when the text holds a banned term by the contract's matching rules.
local function banned(text: string, terms: { [string]: { string } }): string?
	for _, term in terms.platform do
		if string.find(squash(text), term, 1, true) then
			return term
		end
	end
	local wordSet = words(text)
	for group, list in terms do
		if group ~= "platform" then
			for _, term in list do
				if wordSet[term] then
					return term
				end
			end
		end
	end
	return nil
end

local shopNames = serde.decode("json", fs.readFile(NAMES_PATH))
local fronts = serde.decode("json", fs.readFile(FRONTS_PATH))

test("Signage: every clear name has searches, a date and sign text within the rules", function()
	local seenCells: { [string]: boolean } = {}
	for _, record in shopNames.names do
		expect.truthy(
			record.verdict == "clear" or record.verdict == "close" or record.verdict == "banned",
			record.name
		)
		expect.truthy(#record.searches >= 1 and #record.date > 0, record.name)
		if record.verdict == "clear" then
			expect.truthy(#record.searches >= 2, record.name)
			expect.truthy(#record.lines >= 1 and #record.lines <= 2, record.name)
			for _, line in record.lines do
				expect.truthy(#line >= 1 and #line <= 13, `{record.name}: line "{line}"`)
				expect.truthy(
					string.match(line, "^[%a%d&' ]+$") ~= nil,
					`{record.name}: line "{line}"`
				)
			end
			expect.truthy(record.cell ~= nil and fronts.signs[record.cell] ~= nil, record.name)
			expect.falsy(seenCells[record.cell], record.cell)
			seenCells[record.cell] = true
			expect.equal(fronts.signs[record.cell].name, record.name)
		end
	end
end)

test("Signage: no name or sign line holds a banned term", function()
	for _, record in shopNames.names do
		if record.verdict == "clear" then
			expect.falsy(banned(record.name, shopNames.bannedTerms), record.name)
			for _, line in record.lines do
				expect.falsy(banned(line, shopNames.bannedTerms), line)
			end
		end
	end
	-- The rule itself: Blocky and Barber pass, B-lox and Ale House do not.
	expect.falsy(banned("Blocky Mart", shopNames.bannedTerms))
	expect.falsy(banned("Hat Trick Barber", shopNames.bannedTerms))
	expect.falsy(banned("Toast Lab", shopNames.bannedTerms))
	expect.truthy(banned("B-lox Corner", shopNames.bannedTerms))
	expect.truthy(banned("Ale House", shopNames.bannedTerms))
end)

test("Signage: every CityKit name passes the banned-term check in both languages", function()
	for _, object in objects do
		local texts = (CityKitStrings :: any)[object.nameKey]
		expect.falsy(banned(texts.en, shopNames.bannedTerms), texts.en)
		expect.falsy(banned(texts.es, shopNames.bannedTerms), texts.es)
	end
end)

test("Signage: the billboard designs stay within Config.Budgets.billboardTextures", function()
	local count = 0
	for _ in fronts.billboards do
		count += 1
	end
	expect.equal(Config.Budgets.billboardTextures, 8)
	expect.truthy(count <= Config.Budgets.billboardTextures)
	local signs = 0
	for _ in fronts.signs do
		signs += 1
	end
	expect.truthy(signs <= 24)
	expect.truthy(fronts.themes.city.pixelSha256 ~= fronts.themes.winter.pixelSha256)
end)

test("Signage: every fronts object has its cells in fronts.json", function()
	local billboardCells = {
		ck_billboard_404 = "bb_404",
		ck_billboard_chart = "bb_chart",
		ck_billboard_loading = "bb_loading",
		ck_billboard_empty = "bb_empty",
		ck_billboard_arrow = "bb_arrow",
		ck_billboard_testcard = "bb_testcard",
		ck_billboard_nested = "bb_nested",
		ck_meme_buffering_billboard = "bb_buffering",
	}
	for key, cell in billboardCells do
		expect.truthy(fronts.billboards[cell] ~= nil, key)
	end
	for _, object in objects do
		if object.atlas == "fronts" and string.sub(object.id, 1, 5) == "shop_" then
			expect.truthy(
				fronts.strips.fx_render ~= nil and fronts.strips.fx_brick ~= nil,
				object.id
			)
		end
	end
end)

test("CityKit: the small end is stocked (Stage C, owner request 2026-11-08)", function()
	-- at least 15 tier 1 objects, at least 10 tier 2 objects in the low half of the band (up to 3 studs), and tier 1
	-- in every everyday zone, so a D1 ball has something to eat wherever the kit is placed
	local tier1, lowTier2 = 0, 0
	local zones: { [string]: boolean } = {}
	for _, object in objects do
		if object.tier == 1 then
			tier1 += 1
			zones[object.zone :: string] = true
		elseif object.tier == 2 and object.size <= 3 then
			lowTier2 += 1
		end
	end
	expect.truthy(tier1 >= 15, `tier 1: {tier1}`)
	expect.truthy(lowTier2 >= 10, `tier 2 up to 3 studs: {lowTier2}`)
	for _, zone in { "street", "park", "suburbs", "mainstreet" } do
		expect.truthy(zones[zone], zone)
	end
end)

return {}
