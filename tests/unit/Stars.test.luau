--!strict
-- Expected values are written out by hand from contracts/rules-api.md (Stars table).

local harness = require("./harness")
local Stars = require("../../src/shared/Rules/Stars")

local test, expect = harness.test, harness.expect

local production = { 20, 45, 80 }
local greyBox = { 3, 4, 5 }

test("stars: production thresholds 20, 45, 80", function()
	expect.equal(Stars.stars(19.99, production), 0)
	expect.equal(Stars.stars(20, production), 1)
	expect.equal(Stars.stars(44.99, production), 1)
	expect.equal(Stars.stars(45, production), 2)
	expect.equal(Stars.stars(79.99, production), 2)
	expect.equal(Stars.stars(80, production), 3)
end)

test("stars: grey-box thresholds 3, 4, 5", function()
	expect.equal(Stars.stars(2.99, greyBox), 0)
	expect.equal(Stars.stars(3, greyBox), 1)
	expect.equal(Stars.stars(4, greyBox), 2)
	expect.equal(Stars.stars(5, greyBox), 3)
	expect.equal(Stars.stars(1000, greyBox), 3)
end)

test("stars: no thresholds gives 0", function()
	expect.equal(Stars.stars(7, {}), 0)
end)

return {}
