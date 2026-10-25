--!strict
-- No English in scripts: a Text assignment in src/client or src/server may not carry a literal with two
-- or more consecutive letters. Symbol-only text goes through Icons (Constitution IX).

local fs = require("@lune/fs")
local harness = require("./harness")

local test, expect = harness.test, harness.expect

-- Returns the offending literal in `line`, or nil. Matches `Text = "..."`, `.Text = "..."` and the
-- `text = "..."` field UiKit takes.
local function findLiteral(line: string): string?
	for literal in string.gmatch(line, '[Tt]ext%s*=%s*"([^"]*)"') do
		if string.match(literal, "%a%a") then
			return literal
		end
	end
	return nil
end

test("guard: rejects a letter-bearing literal and accepts symbols and Icons", function()
	expect.equal(findLiteral('label.Text = "Roll again"'), "Roll again")
	expect.equal(findLiteral('text = "Go"'), "Go")
	expect.equal(findLiteral("label.Text = Icons.star"), nil)
	expect.equal(findLiteral('label.Text = "★"'), nil)
	expect.equal(findLiteral('label.Text = ""'), nil)
end)

test("src/client and src/server contain no letter-bearing Text literals", function()
	local scanned = 0
	for _, folder in { "src/client", "src/server" } do
		for _, name in fs.readDir(folder) do
			if string.match(name, "%.luau$") then
				scanned += 1
				local lineNumber = 0
				for line in string.gmatch(fs.readFile(`{folder}/{name}`) .. "\n", "([^\n]*)\n") do
					lineNumber += 1
					local literal = findLiteral(line)
					if literal then
						error(
							`{folder}/{name}:{lineNumber} has the literal "{literal}"; use Strings.luau`
						)
					end
				end
			end
		end
	end
	expect.truthy(scanned > 0)
end)

return {}
