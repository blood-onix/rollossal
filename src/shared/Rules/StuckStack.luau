--!strict
-- Bounded list of stuck entries. Every function returns new lists and never mutates its input.
-- Generic over the entry type, so this module does not know about StuckEntry.

local StuckStack = {}

local function copyRange<T>(list: { T }, first: number, last: number): { T }
	local result: { T } = {}
	for i = first, last do
		table.insert(result, list[i])
	end
	return result
end

function StuckStack.push<T>(stack: { T }, entry: T, cap: number): { T }
	local result = copyRange(stack, 1, #stack)
	table.insert(result, entry)
	local excess = #result - cap
	if excess > 0 then
		return copyRange(result, excess + 1, #result)
	end
	return result
end

-- Returns (remaining, removed). removed keeps the newest-last order of the original stack.
function StuckStack.popRecent<T>(stack: { T }, n: number): ({ T }, { T })
	local count = math.min(n, #stack)
	local cut = #stack - count
	return copyRange(stack, 1, cut), copyRange(stack, cut + 1, #stack)
end

function StuckStack.visibleTail<T>(stack: { T }, maxVisible: number): { T }
	local first = math.max(1, #stack - maxVisible + 1)
	return copyRange(stack, first, #stack)
end

return StuckStack
