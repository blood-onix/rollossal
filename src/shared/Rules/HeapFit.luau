--!strict
-- Where a stuck item sits on the ball so the heap never looks bigger than the ball (research R4).
-- Pure: no Roblox APIs, no clock, no randomness.

local HeapFit = {}

export type Params = {
	maxScale: number, -- longest side at most maxScale * D
	bound: number, -- the heap fits a box of bound * D (1.25 means 0.125 * D above the surface)
	newestBound: number, -- reach above the surface, in diameters, for the newest large catch
	embed: number, -- share of a thin item's thickness sunk into the ball
	grace: number, -- seconds the newest catch may use newestBound
}

export type Fit = {
	scale: number, -- multiply the item's dims by this
	long: number, -- scaled length along the surface (tangent)
	mid: number, -- scaled width along the surface
	thin: number, -- scaled thickness along the normal
	longAxis: number, -- index (1..3) of dims that lies along the surface
	midAxis: number,
	thinAxis: number, -- index of dims that points along the normal
	centerDistance: number, -- from the ball centre to the item centre, along the normal
	reach: number, -- how far the item's top sits above the ball surface
}

local function smoothstep(t: number): number
	local c = math.clamp(t, 0, 1)
	return c * c * (3 - 2 * c)
end

-- dims: {l, w, h}. newestAge: seconds since the newest large catch landed, nil for every other item.
function HeapFit.fit(dims: { number }, diameter: number, params: Params, newestAge: number?): Fit
	local order = { 1, 2, 3 }
	table.sort(order, function(a: number, b: number): boolean
		if dims[a] ~= dims[b] then
			return dims[a] > dims[b]
		end
		return a < b
	end)
	local longest = dims[order[1]]
	local scale = math.min(1, params.maxScale * diameter / longest)
	local thin = dims[order[3]] * scale

	local reachCap = (params.bound - 1) / 2 * diameter
	if newestAge ~= nil and newestAge < params.grace then
		local blend = 1 - smoothstep(newestAge / params.grace)
		reachCap += blend * (params.newestBound * diameter - reachCap)
	end
	local reach = math.min(reachCap, (1 - params.embed) * thin)
	return {
		scale = scale,
		long = longest * scale,
		mid = dims[order[2]] * scale,
		thin = thin,
		longAxis = order[1],
		midAxis = order[2],
		thinAxis = order[3],
		centerDistance = diameter / 2 + reach - thin / 2,
		reach = reach,
	}
end

return HeapFit
