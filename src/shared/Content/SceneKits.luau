--!strict
-- The 10 starter scene kits (010 main-street slice). Data only: no Roblox APIs and no requires, so Lune loads it directly.
-- Shape: Rules/SceneKit.luau (KitDef). Offsets (dx, dz) are studs in kit space, yaw is degrees.
-- Every objectId is a Downtown catalogue id or a slice id (Content/Worlds/MainStreetSlice.luau). No text, no branding.
-- A prop's front is its local -Z: yaw 0 faces -z, 90 faces -x, 180 faces +z, 270 faces +x.

export type KitEntry = { objectId: string, dx: number, dz: number, yaw: number }
export type KitDef = { id: string, halfX: number, halfZ: number, entries: { KitEntry } }

local function kit(id: string, halfX: number, halfZ: number, entries: { KitEntry }): KitDef
	return { id = id, halfX = halfX, halfZ = halfZ, entries = entries }
end

local function e(objectId: string, dx: number, dz: number, yaw: number): KitEntry
	return { objectId = objectId, dx = dx, dz = dz, yaw = yaw }
end

-- Order is the order the kits are listed in the spec.
local order = {
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

local kits: { [string]: KitDef } = {
	-- A blanket with lunch laid out around its edge.
	picnic_spread = kit("picnic_spread", 4, 4, {
		e("picnic_blanket", 0, 0, 0),
		e("takeout_box", 3.2, -1, 20),
		e("soda_can", -3, 1.5, 0),
		e("pizza_slice", 3, 2.5, 200),
		e("basketball", -3.2, -2, 0),
		e("water_bottle", 0.5, 3.4, 90),
		e("donut", -1, -3.2, 0),
	}),
	-- Two tables with cups beside them and a planter behind.
	cafe_terrace = kit("cafe_terrace", 7, 6, {
		e("picnic_table", -3.5, 0, 0),
		e("picnic_table", 3.5, 0, 0),
		e("coffee_cup", -4, 4.2, 0),
		e("donut", -2, 4.4, 0),
		e("coffee_cup", 4, 4.2, 0),
		e("potted_palm", -6.5, -4.6, 0),
		e("potted_palm", 6.5, -4.6, 0),
		e("wheelie_bin", 0, -5, 180),
	}),
	-- A shelter with a bench, a paper box and litter. The bench faces the street (-z side of the kit).
	bus_stop = kit("bus_stop", 10, 8, {
		e("bus_shelter", -3.5, 0, 0),
		e("bench", 5.5, 0, 0),
		e("newspaper_box", 6, 5.5, 180),
		e("soda_can", -2, 6, 0),
		e("bottle_cap", 1, 6, 0),
		e("parking_meter", -3.5, -7, 0),
	}),
	-- Crates in two rows with a cart behind.
	fruit_stall = kit("fruit_stall", 5, 5, {
		e("fruit_crate", -2.6, 0, 0),
		e("fruit_crate", 0, 0, 0),
		e("fruit_crate", 2.6, 0, 0),
		e("fruit_crate", -1.3, 2.8, 0),
		e("fruit_crate", 1.3, 2.8, 0),
		e("shopping_cart", 0, -4.5, 90),
		e("flower_pot", 4.4, 3.5, 0),
	}),
	-- Two bicycles with a scooter and a skateboard between them.
	bike_rack = kit("bike_rack", 7, 4, {
		e("bicycle", -5, 0, 90),
		e("bicycle", 5, 0, 90),
		e("e_scooter", 0, 0, 90),
		e("skateboard", 0, 3.6, 0),
		e("bottle_cap", 0, -3.2, 0),
	}),
	-- Barriers and cones around a pallet of materials.
	road_works = kit("road_works", 8, 5, {
		e("road_barrier", -6, -4, 0),
		e("road_barrier", 0, -4, 0),
		e("road_barrier", 6, -4, 0),
		e("traffic_cone", -7.5, 0.5, 0),
		e("traffic_cone", 7.5, 0.5, 0),
		e("pallet_stack", 0, 2, 0),
		e("traffic_cone", -3.6, 4.5, 0),
		e("traffic_cone", 3.6, 4.5, 0),
	}),
	-- A driveway row: three cars side by side facing the street.
	car_park_rows = kit("car_park_rows", 16, 10, {
		e("hatchback", -15, 0, 0),
		e("taxi", 0, 0, 0),
		e("pickup_truck", 16, 0, 0),
		e("parking_meter", -7.5, 9.5, 0),
		e("parking_meter", 8, 9.5, 0),
	}),
	-- Things on a lawn, laid out by hand.
	yard_sale = kit("yard_sale", 6, 5, {
		e("acoustic_guitar", -4.5, -1, 0),
		e("suitcase", 0, -1, 30),
		e("boombox_speaker", 4.5, -1, 0),
		e("skateboard", -4, 3.2, 90),
		e("lost_sneaker", -1.2, 3.4, 40),
		e("keyboard", 1.6, 3.4, 0),
		e("rubber_duck_sunglasses", 4.5, 3.2, 0),
		e("spinning_office_chair", 0, -5, 0),
	}),
	-- Pots in a tight bed around one big plant.
	flower_bed = kit("flower_bed", 4, 4, {
		e("potted_palm", 0, 0, 0),
		e("flower_pot", -3, -2.4, 0),
		e("flower_pot", 3, -2.4, 0),
		e("flower_pot", -3, 2.4, 0),
		e("flower_pot", 3, 2.4, 0),
		e("flower_pot", 0, 3.6, 0),
		e("flower_pot", 0, -3.6, 0),
	}),
	-- Two banks, a bin, and the bottles that missed.
	recycling_point = kit("recycling_point", 7, 5, {
		e("recycling_bank", -4, 0, 0),
		e("recycling_bank", 4, 0, 0),
		e("wheelie_bin", 0, 4.4, 180),
		e("soda_can", -2, -3.6, 0),
		e("water_bottle", 2.4, -3.6, 90),
		e("aa_battery", 0, -4.4, 0),
	}),
}

return { order = order, kits = kits }
