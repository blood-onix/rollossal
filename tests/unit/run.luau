--!strict
-- Runs every *.test.luau suite in this folder. Each suite registers its tests when required.
-- harness.summary() prints the totals and exits non-zero if any test failed.

local fs = require("@lune/fs")
local harness = require("./harness")

local suites: { string } = {}
for _, name in fs.readDir("tests/unit") do
	if string.match(name, "%.test%.luau$") then
		table.insert(suites, name)
	end
end
table.sort(suites)

for _, name in suites do
	print(`--- {name}`)
	require("./" .. string.gsub(name, "%.luau$", ""))
end

harness.summary()
