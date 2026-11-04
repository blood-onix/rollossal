--!strict
-- Street rules: expands a hand-authored StreetDef (segments, junctions, spacing) into ground blocks and prop placements.
-- Pure: no Roblox APIs, no clock, no global random. Randomness is a local seeded Park-Miller generator, exact in doubles.
-- Rules modules do not require siblings, so the generator and the placement shape are repeated here.
--
-- Frame of a segment: `along` = (sin yaw, cos yaw) and `across` (the right-hand side) = (cos yaw, -sin yaw). A block with
-- the segment's yaw has its size.z along the street and size.x across it. A prop whose front is local -Z and whose yaw
-- is theta faces (-sin theta, -cos theta), so yaw + 90 faces the left of the street and yaw - 90 faces the right.

export type StreetIds = {
	tree: string,
	lamp: string,
	bin: string,
	bench: string,
	car: string,
	hydrant: string,
}
-- width is the carriageway; sidewalk is each pavement's width (at least 6); yaw is degrees and must match the
-- direction from (x0, z0) to (x1, z1).
export type StreetSegment = {
	id: string,
	x0: number,
	z0: number,
	x1: number,
	z1: number,
	width: number,
	sidewalk: number,
	yaw: number,
}
-- A cross street meeting a segment. reach (optional) is how far from the segment axis the cross carriageway runs.
export type Junction = { id: string, x: number, z: number, crossWidth: number, reach: number? }
export type StreetDef = {
	seed: number,
	segments: { StreetSegment },
	junctions: { Junction },
	ids: StreetIds,
	treeEvery: number,
	lampEvery: number,
	lampTreeClear: number,
	jitterPos: number,
	jitterYaw: number,
}
export type BlockDef = {
	id: string,
	kind: string,
	cframe: { x: number, y: number, z: number, yaw: number },
	size: { x: number, y: number, z: number },
	swatch: string,
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
export type StreetOut = { blocks: { BlockDef }, placements: { Placement } }

local MULTIPLIER = 48271
local MODULUS = 2147483647

local ROAD_TOP = 0.1
local PAVEMENT_TOP = 0.4
local MARKING_HEIGHT = 0.02
local KERB_WIDTH = 0.6
local MIN_SIDEWALK = 6
local DASH_LENGTH = 1
local DASH_WIDTH = 0.3
local ZEBRA_STRIPE = 1
local ZEBRA_DEPTH = 4
local ZEBRA_GAP_TO_CROSS = 1
local MARKING_CLEAR = 1
local TREE_OFFSET = 2 -- from the inner edge of the pavement
local LAMP_OFFSET = 1
local BENCH_OFFSET = 4
local HYDRANT_OFFSET = 4.8
local CORNER_PAD = 1.2
local TREE_JUNCTION_CLEAR = 2
local LAMP_JUNCTION_CLEAR = 4
local BENCH_JUNCTION_CLEAR = 6
local BENCH_EVERY = 54
local CAR_EVERY = 20
local CAR_LANE_INSET = 3.2
local CAR_JUNCTION_CLEAR = 13
local CAR_FILL = 0.6
local MAX_LAMP_SHIFT = 6
local YAW_TOLERANCE = 0.5
local ON_AXIS_TOLERANCE = 0.5

local SIDES = { { name = "r", sign = 1 }, { name = "l", sign = -1 } }
local ENDS = { { name = "s", direction = -1 }, { name = "n", direction = 1 } }
local CORNERS = {
	{ name = "sr", direction = -1, sign = 1 },
	{ name = "nr", direction = 1, sign = 1 },
	{ name = "sl", direction = -1, sign = -1 },
	{ name = "nl", direction = 1, sign = -1 },
}

local StreetRules = {}

type Frame = {
	x0: number,
	z0: number,
	ax: number,
	az: number,
	nx: number,
	nz: number,
	length: number,
	seg: StreetSegment,
}

local function at(f: Frame, s: number, off: number): (number, number)
	return f.x0 + s * f.ax + off * f.nx, f.z0 + s * f.az + off * f.nz
end

local function frameOf(seg: StreetSegment): Frame
	local dx, dz = seg.x1 - seg.x0, seg.z1 - seg.z0
	local length = math.sqrt(dx * dx + dz * dz)
	if length <= 0 then
		error(`StreetRules: segment {seg.id} has no length`)
	end
	if seg.sidewalk < MIN_SIDEWALK then
		error(`StreetRules: segment {seg.id} sidewalk {seg.sidewalk} is under {MIN_SIDEWALK} studs`)
	end
	local expected = math.deg(math.atan2(dx, dz))
	if math.abs((seg.yaw - expected + 180) % 360 - 180) > YAW_TOLERANCE then
		error(
			`StreetRules: segment {seg.id} yaw {seg.yaw} does not match its endpoints ({expected})`
		)
	end
	local yaw = math.rad(seg.yaw)
	return {
		x0 = seg.x0,
		z0 = seg.z0,
		ax = math.sin(yaw),
		az = math.cos(yaw),
		nx = math.cos(yaw),
		nz = -math.sin(yaw),
		length = length,
		seg = seg,
	}
end

type Cut = { s: number, half: number, junction: Junction }

-- The [from, to] pieces of 0 .. length left after removing the cut intervals (sorted, non-overlapping).
local function pieces(length: number, cuts: { Cut }): { { number } }
	local out = {}
	local cursor = 0
	for _, cut in cuts do
		local a, b = cut.s - cut.half, cut.s + cut.half
		if a < cursor - 1e-9 or b > length + 1e-9 then
			error(
				`StreetRules: junction {cut.junction.id} overlaps another junction or leaves the segment`
			)
		end
		if a - cursor > 1e-9 then
			table.insert(out, { cursor, a })
		end
		cursor = b
	end
	if length - cursor > 1e-9 then
		table.insert(out, { cursor, length })
	end
	return out
end

function StreetRules.expand(def: StreetDef): StreetOut
	local blocks: { BlockDef } = {}
	local placements: { Placement } = {}
	local state = def.seed % (MODULUS - 1) + 1

	local function draw(): number
		state = state * MULTIPLIER % MODULUS
		return state / MODULUS
	end

	local frames: { Frame } = {}
	for _, seg in def.segments do
		table.insert(frames, frameOf(seg))
	end

	-- Hand every junction to the segment whose axis it sits on.
	local cutsOf: { [number]: { Cut } } = {}
	for index in frames do
		cutsOf[index] = {}
	end
	for _, junction in def.junctions do
		local owner = nil
		local ownerS = 0
		for index, f in frames do
			local rx, rz = junction.x - f.x0, junction.z - f.z0
			local s = rx * f.ax + rz * f.az
			local off = rx * f.nx + rz * f.nz
			if math.abs(off) <= ON_AXIS_TOLERANCE and s > 0 and s < f.length then
				owner, ownerS = index, s
				break
			end
		end
		if owner == nil then
			error(`StreetRules: junction {junction.id} sits on no segment`)
		end
		table.insert(
			cutsOf[owner],
			{ s = ownerS, half = junction.crossWidth / 2, junction = junction }
		)
	end

	local function addBlock(
		f: Frame,
		id: string,
		s: number,
		off: number,
		across: number,
		along: number,
		y0: number,
		height: number,
		swatch: string,
		turn: number?
	)
		local x, z = at(f, s, off)
		table.insert(blocks, {
			id = id,
			kind = "Block",
			cframe = { x = x, y = y0 + height / 2, z = z, yaw = f.seg.yaw + (turn or 0) },
			size = { x = across, y = height, z = along },
			swatch = swatch,
		})
	end

	-- Draws three values per prop in a fixed order so the stream does not depend on the jitter settings.
	local function place(
		id: string,
		objectId: string,
		f: Frame,
		s: number,
		off: number,
		y: number,
		yawDegrees: number,
		movable: boolean
	)
		local jx = (draw() * 2 - 1) * def.jitterPos
		local jz = (draw() * 2 - 1) * def.jitterPos
		local jyaw = (draw() * 2 - 1) * def.jitterYaw
		local x, z = at(f, s, off)
		if movable then
			x += jx
			z += jz
		end
		table.insert(placements, {
			id = id,
			objectId = objectId,
			x = x,
			y = y,
			z = z,
			yaw = math.rad(yawDegrees + jyaw),
			spawnSlot = nil,
		})
	end

	for index, f in frames do
		local seg = f.seg
		local cuts = cutsOf[index]
		table.sort(cuts, function(a, b)
			return a.s < b.s
		end)
		local runs = pieces(f.length, cuts)
		local half = seg.width / 2
		local kerbOff = half + KERB_WIDTH / 2
		local walkOff = half + KERB_WIDTH + seg.sidewalk / 2
		local innerEdge = half + KERB_WIDTH

		-- Road.
		addBlock(f, `{seg.id}_road`, f.length / 2, 0, seg.width, f.length, 0, ROAD_TOP, "w-asphalt")

		-- Kerb band and pavement, one piece per run between junction cuts, on each side.
		for _, sideSpec in SIDES do
			local side, sign = sideSpec.name, sideSpec.sign
			for pieceIndex, run in runs do
				local mid, len = (run[1] + run[2]) / 2, run[2] - run[1]
				addBlock(
					f,
					`{seg.id}_kerb_{side}_{pieceIndex}`,
					mid,
					sign * kerbOff,
					KERB_WIDTH,
					len,
					0,
					PAVEMENT_TOP,
					"w-kerb"
				)
				addBlock(
					f,
					`{seg.id}_walk_{side}_{pieceIndex}`,
					mid,
					sign * walkOff,
					seg.sidewalk,
					len,
					0,
					PAVEMENT_TOP,
					"w-sidewalk"
				)
			end
		end

		-- Junction surfaces: road through the pavement gap, optional cross carriageway, and a crossing either side.
		for _, cut in cuts do
			local junction = cut.junction
			local gap = KERB_WIDTH + seg.sidewalk
			local outer = innerEdge + seg.sidewalk
			for _, sideSpec in SIDES do
				local side, sign = sideSpec.name, sideSpec.sign
				addBlock(
					f,
					`{seg.id}_{junction.id}_cut_{side}`,
					cut.s,
					sign * (half + gap / 2),
					gap,
					junction.crossWidth,
					0,
					ROAD_TOP,
					"w-asphalt"
				)
				local reach = junction.reach
				if reach ~= nil and reach - outer > 0.01 then
					addBlock(
						f,
						`{seg.id}_{junction.id}_cross_{side}`,
						cut.s,
						sign * (outer + reach) / 2,
						junction.crossWidth,
						reach - outer,
						0,
						ROAD_TOP,
						"w-asphalt",
						90
					)
				end
			end

			local stripes = math.floor((seg.width - 4) / 2) + 1
			for _, endSpec in ENDS do
				local end_, direction = endSpec.name, endSpec.direction
				local centre = cut.s + direction * (cut.half + ZEBRA_GAP_TO_CROSS + ZEBRA_DEPTH / 2)
				for i = 0, stripes - 1 do
					addBlock(
						f,
						`{seg.id}_{junction.id}_zebra_{end_}_{i + 1}`,
						centre,
						-(stripes - 1) + 2 * i,
						ZEBRA_STRIPE,
						ZEBRA_DEPTH,
						ROAD_TOP,
						MARKING_HEIGHT,
						"w-white"
					)
				end
			end
		end

		-- Centre line: 1 stud dash, 1 stud gap, skipped near a junction.
		for i = 0, math.floor(f.length / 2) - 1 do
			local s = DASH_LENGTH / 2 + 2 * i
			local clear = true
			for _, cut in cuts do
				if
					math.abs(s - cut.s)
					<= cut.half + ZEBRA_GAP_TO_CROSS + ZEBRA_DEPTH + MARKING_CLEAR
				then
					clear = false
				end
			end
			if clear then
				addBlock(
					f,
					`{seg.id}_dash_{i + 1}`,
					s,
					0,
					DASH_WIDTH,
					DASH_LENGTH,
					ROAD_TOP,
					MARKING_HEIGHT,
					"w-road-line"
				)
			end
		end

		local function nearJunction(s: number, extra: number): boolean
			for _, cut in cuts do
				if math.abs(s - cut.s) < cut.half + extra then
					return true
				end
			end
			return false
		end

		local treeOff = innerEdge + TREE_OFFSET
		local lampOff = innerEdge + LAMP_OFFSET
		local benchOff = innerEdge + BENCH_OFFSET

		-- Trees: even spacing, half a spacing in from each end, none inside a junction.
		local treeS: { number } = {}
		local s = def.treeEvery / 2
		while s <= f.length - def.treeEvery / 2 + 1e-9 do
			if not nearJunction(s, TREE_JUNCTION_CLEAR) then
				table.insert(treeS, s)
			end
			s += def.treeEvery
		end
		for k, ts in treeS do
			place(`{seg.id}_tree_r_{k}`, def.ids.tree, f, ts, treeOff, PAVEMENT_TOP, seg.yaw, false)
			place(
				`{seg.id}_tree_l_{k}`,
				def.ids.tree,
				f,
				ts,
				-treeOff,
				PAVEMENT_TOP,
				seg.yaw,
				false
			)
		end

		-- Lamps: nominal spacing, shifted one stud at a time (forward first) until clear of every trunk.
		local lampIndex = 0
		local nominal = def.lampEvery / 2
		while nominal <= f.length - def.lampEvery / 2 + 1e-9 do
			local chosen = nil
			for step = 0, MAX_LAMP_SHIFT * 2 do
				local shift = if step == 0
					then 0
					elseif step % 2 == 1 then (step + 1) // 2
					else -(step // 2)
				local candidate = nominal + shift
				local ok = candidate > 0
					and candidate < f.length
					and not nearJunction(candidate, LAMP_JUNCTION_CLEAR)
				if ok then
					for _, ts in treeS do
						local dx, dz = lampOff - treeOff, candidate - ts
						if math.sqrt(dx * dx + dz * dz) < def.lampTreeClear then
							ok = false
							break
						end
					end
				end
				if ok then
					chosen = candidate
					break
				end
			end
			if chosen ~= nil then
				lampIndex += 1
				place(
					`{seg.id}_lamp_r_{lampIndex}`,
					def.ids.lamp,
					f,
					chosen,
					lampOff,
					PAVEMENT_TOP,
					seg.yaw,
					false
				)
				place(
					`{seg.id}_lamp_l_{lampIndex}`,
					def.ids.lamp,
					f,
					chosen,
					-lampOff,
					PAVEMENT_TOP,
					seg.yaw,
					false
				)
			end
			nominal += def.lampEvery
		end

		-- Benches: every 54 studs, alternating sides, facing the carriageway.
		local k = 1
		while k * BENCH_EVERY <= f.length - 9 do
			local bs = k * BENCH_EVERY
			if not nearJunction(bs, BENCH_JUNCTION_CLEAR) then
				local right = k % 2 == 1
				place(
					`{seg.id}_bench_{k}`,
					def.ids.bench,
					f,
					bs,
					if right then benchOff else -benchOff,
					PAVEMENT_TOP,
					seg.yaw + (if right then 90 else -90),
					true
				)
			end
			k += 1
		end

		-- Parked cars: a slot every 20 studs per side, filled by the seed, parallel to the kerb, none at a junction.
		local slot = 0
		local cs = 10
		while cs <= f.length - 10 do
			slot += 1
			local blocked = false
			for _, cut in cuts do
				if math.abs(cs - cut.s) < cut.half + CAR_JUNCTION_CLEAR then
					blocked = true
				end
			end
			if not blocked then
				for _, sideSpec in SIDES do
					local side, sign = sideSpec.name, sideSpec.sign
					if draw() < CAR_FILL then
						place(
							`{seg.id}_car_{side}_{slot}`,
							def.ids.car,
							f,
							cs,
							sign * (half - CAR_LANE_INSET),
							ROAD_TOP,
							seg.yaw + (if sign == 1 then 180 else 0),
							true
						)
					end
				end
			end
			cs += CAR_EVERY
		end

		-- Corners: a bin at all four, a hydrant on two, everything facing the carriageway.
		for _, cut in cuts do
			local junction = cut.junction
			for _, spec in CORNERS do
				local corner, direction, sign = spec.name, spec.direction, spec.sign
				local cornerS = cut.s + direction * (cut.half + CORNER_PAD)
				local yaw = seg.yaw + (if sign == 1 then 90 else -90)
				place(
					`{junction.id}_bin_{corner}`,
					def.ids.bin,
					f,
					cornerS,
					sign * (innerEdge + LAMP_OFFSET),
					PAVEMENT_TOP,
					yaw,
					true
				)
				if corner == "sr" or corner == "nl" then
					place(
						`{junction.id}_hydrant_{corner}`,
						def.ids.hydrant,
						f,
						cornerS,
						sign * (innerEdge + HYDRANT_OFFSET),
						PAVEMENT_TOP,
						yaw,
						true
					)
				end
			end
		end
	end

	return { blocks = blocks, placements = placements }
end

return StreetRules
