--!strict
-- Ball heap rules (010, contracts/heap-rules.md): which stuck items stay on the outside of the ball, how much of the
-- base sphere they hide, the colour of the core under them and the shrink of a buried item. Pure: no Roblox APIs,
-- no clock, no randomness. The caller injects anything engine-shaped (item footprint, palette lookup).

export type HeapEntry = { key: string, id: string, size: number, tier: number, age: number }
-- cap: most items kept outside. protectTier: tiers at or above it are milestone catches and stay outside first.
export type HeapParams = { cap: number, protectTier: number }
export type HeapResult = { outer: { HeapEntry }, buried: { HeapEntry } }
export type Colour = { r: number, g: number, b: number }

local NEUTRAL = 0.5

local Heap = {}

-- Bigger and newer is better. age 0 is the newest catch.
function Heap.score(entry: HeapEntry): number
	return entry.size / (1 + entry.age)
end

local function better(a: HeapEntry, b: HeapEntry): boolean
	local sa, sb = Heap.score(a), Heap.score(b)
	if sa ~= sb then
		return sa > sb
	end
	return a.key < b.key
end

-- Splits entries into the outer shell (at most cap) and the buried rest. Protected tiers are filled first, best score
-- first; the remaining places go to the best-scoring others. Both lists are ordered best first. Input is not mutated.
function Heap.select(entries: { HeapEntry }, params: HeapParams): HeapResult
	local protected: { HeapEntry } = {}
	local others: { HeapEntry } = {}
	for _, entry in entries do
		if entry.tier >= params.protectTier then
			table.insert(protected, entry)
		else
			table.insert(others, entry)
		end
	end
	table.sort(protected, better)
	table.sort(others, better)

	local outer: { HeapEntry } = {}
	local buried: { HeapEntry } = {}
	for _, entry in protected do
		if #outer < params.cap then
			table.insert(outer, entry)
		else
			table.insert(buried, entry)
		end
	end
	for _, entry in others do
		if #outer < params.cap then
			table.insert(outer, entry)
		else
			table.insert(buried, entry)
		end
	end
	table.sort(outer, better)
	table.sort(buried, better)
	return { outer = outer, buried = buried }
end

-- Fraction of the base sphere's surface hidden, in [0, 1]. itemFootprint(entry) is the diameter of the patch the item
-- covers on the sphere at this ball size (the caller applies the (D / refD) ^ exponent scaling). Each patch is a disc;
-- overlap is ignored, so this is an upper bound that the Studio capture then checks.
function Heap.coverage(
	ballD: number,
	outer: { HeapEntry },
	itemFootprint: (HeapEntry) -> number
): number
	if ballD <= 0 then
		return 0
	end
	local sphere = math.pi * ballD * ballD
	local covered = 0
	for _, entry in outer do
		local d = itemFootprint(entry)
		covered += math.pi * (d / 2) * (d / 2)
	end
	return math.clamp(covered / sphere, 0, 1)
end

-- Mean colour (each channel 0..1) of the buried items. paletteOf is injected. No buried items gives neutral grey; the
-- caller leaves the core alone in that case.
function Heap.coreColor(buried: { HeapEntry }, paletteOf: (HeapEntry) -> Colour): Colour
	local count = #buried
	if count == 0 then
		return { r = NEUTRAL, g = NEUTRAL, b = NEUTRAL }
	end
	local r, g, b = 0, 0, 0
	for _, entry in buried do
		local c = paletteOf(entry)
		r += c.r
		g += c.g
		b += c.b
	end
	return { r = r / count, g = g / count, b = b / count }
end

-- Linear 0..1 shrink of a buried item (no pop). A zero duration is finished at once.
function Heap.buryProgress(elapsed: number, duration: number): number
	if duration <= 0 then
		return 1
	end
	return math.clamp(elapsed / duration, 0, 1)
end

return Heap
