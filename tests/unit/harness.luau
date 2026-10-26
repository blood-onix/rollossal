--!strict
-- Minimal test harness for Lune. No external library (Constitution XII).

local process = require("@lune/process")

local harness = {}

local passed = 0
local failures: { string } = {}

local function fail(message: string, level: number)
	error(message, level + 1)
end

local expect = {}

function expect.equal<T>(actual: T, expected: T, label: string?)
	if actual ~= expected then
		local prefix = if label then `{label}: ` else ""
		fail(`{prefix}expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

function expect.near(actual: number, expected: number, tolerance: number)
	if math.abs(actual - expected) > tolerance then
		fail(`expected {expected} +/- {tolerance}, got {actual}`, 2)
	end
end

function expect.same<T>(actual: { T }, expected: { T })
	local same = #actual == #expected
	if same then
		for i, value in expected do
			if actual[i] ~= value then
				same = false
				break
			end
		end
	end
	if not same then
		fail(
			`expected list {table.concat(expected :: any, ", ")}, got {table.concat(
				actual :: any,
				", "
			)}`,
			2
		)
	end
end

function expect.truthy(value: unknown)
	if not value then
		fail(`expected a truthy value, got {tostring(value)}`, 2)
	end
end

function expect.falsy(value: unknown)
	if value then
		fail(`expected a falsy value, got {tostring(value)}`, 2)
	end
end

harness.expect = expect

function harness.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print(`PASS {name}`)
	else
		table.insert(failures, `FAIL {name}: {tostring(err)}`)
		print(`FAIL {name}: {tostring(err)}`)
	end
end

function harness.summary()
	print(`{passed} passed, {#failures} failed`)
	if #failures > 0 then
		process.exit(1)
	end
end

return harness
