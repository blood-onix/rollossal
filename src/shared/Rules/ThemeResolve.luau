--!strict
-- Turns *base world + theme id* into the resolved world the runtime uses: slots mapped to the theme's
-- objects, overlays added, hero variants applied, environment palette and lighting taken from the theme.
-- Pure: no Roblox APIs, no clock, no randomness, and no sibling requires — `expand` (Layout.expand) is
-- an argument, because Rules may not `require` scripts in the other runtimes (research R-06).
-- Types are structural copies of the WorldDef pieces in Content/GreyBoxRoom.luau; contract §2.

export type MixEntry = { objectId: string, weight: number }

export type Zone = {
	id: string,
	x: number,
	z: number,
	w: number,
	d: number,
	y: number,
	mix: { MixEntry },
	count: number,
	seed: number,
	spawnSlot: number?,
}

export type Placement = {
	id: string,
	objectId: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	spawnSlot: number?,
}

export type ObjectLike = {
	id: string,
	tier: number,
	size: number,
	coins: number,
	bookId: string,
	nameKey: string,
	icon: string,
	assetKey: string?,
	fallback: string?,
	shade: number?,
	role: string?,
}

export type VariantLike = { assetKey: string, nameKey: string?, size: number? }

export type BindingLike = {
	slots: { [string]: string },
	overlays: { zones: { Zone }, fixedPlacements: { Placement } }?,
	heroVariants: { [string]: VariantLike }?,
	objects: { ObjectLike }?,
	bookPage: any?,
}

export type ThemeLike = { id: string, palette: { [string]: { number } }, lighting: any }

export type WorldLike = {
	worldId: string,
	objects: { ObjectLike },
	zones: { Zone },
	fixedPlacements: { Placement },
	environment: { palette: { [string]: { number } } },
	themeBindings: { [string]: BindingLike }?,
}

export type Resolved = {
	themeId: string,
	zones: { Zone },
	fixedPlacements: { Placement },
	placements: { Placement },
	objects: { ObjectLike },
	environmentPalette: { [string]: { number } },
	lighting: any,
	slotPlacementIds: { [string]: boolean },
}

local ThemeResolve = {}

-- slot.small=1 … slot.landmark=5 (data-model.md §3.1).
local SLOT_TIERS: { [string]: number } = {
	["slot.small"] = 1,
	["slot.medium"] = 2,
	["slot.yard"] = 3,
	["slot.street"] = 4,
	["slot.landmark"] = 5,
}
ThemeResolve.SLOT_TIERS = SLOT_TIERS

-- A slot id starts with "slot." (zone mixes and fixed placements use the plain string ids).
function ThemeResolve.isSlot(objectId: string): boolean
	return string.sub(objectId, 1, 5) == "slot."
end

local function expectUnique(seen: { [string]: boolean }, id: string, label: string)
	if seen[id] then
		error(`ThemeResolve: duplicate id {label}`, 3)
	end
	seen[id] = true
end

local function errorAt(world: WorldLike, theme: ThemeLike, message: string)
	error(`ThemeResolve: world {world.worldId} with theme {theme.id}: {message}`, 2)
end

-- One zone per entry: the mix with slot ids replaced by their mapped object ids. A zone whose mix
-- mixes slots with non-slots is an error, because Layout would then move every other object in it when
-- the theme changes (R-06). New tables only: the input stays reusable for the next theme.
local function resolveZones(
	world: WorldLike,
	theme: ThemeLike,
	zones: { Zone },
	slots: { [string]: string },
	into: { Zone }
)
	for _, zone in zones do
		local replaced: { MixEntry } = table.clone(zone.mix)
		local anySlot, anyOther = false, false
		for index, entry in replaced do
			if ThemeResolve.isSlot(entry.objectId) then
				anySlot = true
				local mapped = slots[entry.objectId]
				if mapped == nil then
					errorAt(
						world,
						theme,
						`zone {zone.id} names slot {entry.objectId} with no themeBindings mapping`
					)
				end
				replaced[index] = { objectId = mapped, weight = entry.weight }
			else
				anyOther = true
			end
		end
		if anySlot and anyOther then
			errorAt(
				world,
				theme,
				`zone {zone.id} mixes slot and non-slot ids; a zone is one or the other`
			)
		end
		table.insert(into, table.clone(zone) :: any)
		local copy = into[#into]
		copy.mix = replaced
	end
end

-- One fixed placement per entry, with slot ids replaced and ids untouched.
local function resolveFixed(
	world: WorldLike,
	theme: ThemeLike,
	fixedPlacements: { Placement },
	slots: { [string]: string },
	into: { Placement }
)
	for _, placement in fixedPlacements do
		local objectId = placement.objectId
		if ThemeResolve.isSlot(objectId) then
			local mapped = slots[objectId]
			if mapped == nil then
				errorAt(
					world,
					theme,
					`placement {placement.id} uses slot {objectId} with no themeBindings mapping`
				)
			end
			objectId = mapped
		end
		table.insert(into, {
			id = placement.id,
			objectId = objectId,
			x = placement.x,
			y = placement.y,
			z = placement.z,
			yaw = placement.yaw,
			spawnSlot = placement.spawnSlot,
		})
	end
end

function ThemeResolve.resolve(
	world: WorldLike,
	theme: ThemeLike,
	expand: (zones: { Zone }, sizes: { [string]: number }) -> { Placement }
): Resolved
	local binding = if world.themeBindings ~= nil then world.themeBindings[theme.id] else nil
	if binding == nil then
		error(`ThemeResolve: world {world.worldId} has no binding for theme {theme.id}`, 2)
	end

	local lookup: { [string]: ObjectLike } = {}
	local lookupSeen: { [string]: boolean } = {}
	for _, object in world.objects do
		expectUnique(lookupSeen, object.id, object.id)
		lookup[object.id] = object
	end
	local bindingObjects: { ObjectLike } = binding.objects or {}
	for _, object in bindingObjects do
		if lookup[object.id] ~= nil then
			errorAt(
				world,
				theme,
				`theme-only object {object.id} clashes with a base or binding object`
			)
		end
		lookup[object.id] = object
	end

	-- Object list: the world's objects with hero variants applied, plus the binding's theme-only
	-- objects. A variant is a copy of its base object (data-model.md §3.1).
	local objects: { ObjectLike } = {}
	local baseIds: { [string]: boolean } = {}
	for _, object in world.objects do
		baseIds[object.id] = true
		local variant = if binding.heroVariants ~= nil then binding.heroVariants[object.id] else nil
		if variant == nil then
			table.insert(objects, object)
		else
			local copy = table.clone(object)
			copy.assetKey = variant.assetKey
			if variant.nameKey ~= nil then
				copy.nameKey = variant.nameKey :: string
			end
			if variant.size ~= nil then
				local drift = math.abs(variant.size :: number - object.size) / object.size
				if drift > 0.1000001 then
					errorAt(
						world,
						theme,
						`hero variant for {object.id} declares size {variant.size}, more than 10% off the base size`
					)
				end
			end
			-- The declared variant size stays art-only: the copy keeps the base size for gameplay.
			table.insert(objects, copy)
		end
	end
	for baseId in (binding.heroVariants or {}) :: { [string]: any } do
		if not baseIds[baseId] then
			errorAt(world, theme, `hero variant for {baseId} names no base object`)
		end
	end
	for _, object in bindingObjects do
		table.insert(objects, object)
	end

	local sizes: { [string]: number } = {}
	for _, object in objects do
		sizes[object.id] = object.size
	end

	-- Slot map: every slot id the world names is defined, mapped to an existing object of the
	-- slot's tier, and named in `binding.slots` (contract behaviour 2/4).
	local slotIds: { [string]: boolean } = {}
	for _, zone in world.zones do
		for _, entry in zone.mix do
			if ThemeResolve.isSlot(entry.objectId) then
				slotIds[entry.objectId] = true
			end
		end
	end
	for _, placement in world.fixedPlacements do
		if ThemeResolve.isSlot(placement.objectId) then
			slotIds[placement.objectId] = true
		end
	end
	local slots: { [string]: string } = {}
	for slotId in slotIds do
		local mapped = binding.slots[slotId]
		if mapped == nil then
			errorAt(world, theme, `slot {slotId} has no themeBindings mapping`)
		end
		local object = lookup[mapped]
		if object == nil then
			errorAt(world, theme, `slot {slotId} maps to unknown object {mapped}`)
		end
		local wantedTier = ThemeResolve.SLOT_TIERS[slotId]
		if object.tier ~= wantedTier then
			errorAt(
				world,
				theme,
				`slot {slotId} is tier {wantedTier} but maps to {mapped}, tier {object.tier}`
			)
		end
		slots[slotId] = mapped
	end

	-- Zones then fixed placements, base first and overlays after (contract behaviour 6).
	local resolvedZones: { Zone } = {}
	resolveZones(world, theme, world.zones, slots, resolvedZones)
	local overlays = binding.overlays
	local overlayZones: { Zone } = {}
	local overlayFixed: { Placement } = {}
	if overlays ~= nil then
		overlayZones = overlays.zones
		overlayFixed = overlays.fixedPlacements
	end

	local zoneIds: { [string]: boolean } = {}
	for _, zone in resolvedZones do
		expectUnique(zoneIds, zone.id, zone.id)
	end
	for _, zone in overlayZones do
		expectUnique(zoneIds, zone.id, zone.id)
		table.insert(resolvedZones, zone)
	end

	local baseFixed: { Placement } = {}
	resolveFixed(world, theme, world.fixedPlacements, slots, baseFixed)
	local placementIds: { [string]: boolean } = {}
	for _, placement in baseFixed do
		expectUnique(placementIds, placement.id, placement.id)
	end
	for _, placement in overlayFixed do
		expectUnique(placementIds, placement.id, placement.id)
	end

	-- One expand call over every zone, with the sizes of the resolved object list (behaviour 8). The
	-- output is reassembled so the order is: base zone placements, base fixed placements, overlay
	-- zone placements, overlay fixed placements (behaviour 6).
	local zonePlacements = expand(resolvedZones, sizes)
	local overlayZoneIds: { [string]: boolean } = {}
	for _, zone in overlayZones do
		overlayZoneIds[zone.id] = true
	end
	local baseZonePlacements: { Placement } = {}
	local overlayZonePlacements: { Placement } = {}
	for _, placement in zonePlacements do
		local zoneId = string.match(placement.id, "^(.-)_%d+$")
		if zoneId ~= nil and overlayZoneIds[zoneId] then
			table.insert(overlayZonePlacements, placement)
		else
			table.insert(baseZonePlacements, placement)
		end
	end
	local placements: { Placement } = {}
	for _, section in { baseZonePlacements, baseFixed, overlayZonePlacements, overlayFixed } do
		for _, placement in section do
			table.insert(placements, placement)
		end
	end

	-- Which placements came from slots: placements of slot-only zones plus slot fixed placements.
	local slotZoneIds: { [string]: boolean } = {}
	for _, zone in world.zones do
		local anySlot = false
		for _, entry in zone.mix do
			anySlot = anySlot or ThemeResolve.isSlot(entry.objectId)
		end
		if anySlot then
			slotZoneIds[zone.id] = true
		end
	end
	local slotPlacementIds: { [string]: boolean } = {}
	-- Expanded slot zones carry ids "<zoneId>_<n>"; slot fixed placements are named directly.
	for _, placement in placements do
		local zoneId = string.match(placement.id, "^(.-)_%d+$")
		if zoneId ~= nil and slotZoneIds[zoneId] then
			slotPlacementIds[placement.id] = true
		end
	end
	for _, placement in world.fixedPlacements do
		if ThemeResolve.isSlot(placement.objectId) then
			slotPlacementIds[placement.id] = true
		end
	end

	-- The environment palette: the world's base colours overlaid with the theme's (theme wins).
	local palette = table.clone(world.environment.palette)
	for name, rgb in theme.palette do
		palette[name] = rgb
	end

	return {
		themeId = theme.id,
		zones = resolvedZones,
		fixedPlacements = baseFixed,
		placements = placements,
		objects = objects,
		environmentPalette = palette,
		lighting = theme.lighting,
		slotPlacementIds = slotPlacementIds,
	}
end

return ThemeResolve
