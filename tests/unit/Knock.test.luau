--!strict
-- Hand-computed values (contracts/rules-api.md, data-model.md "Knock-off decision").

local harness = require("./harness")
local Knock = require("../../src/shared/Rules/Knock")

local test, expect = harness.test, harness.expect

local function input(overrides: { [string]: number }): Knock.DecideInput
	local base = {
		now = 100,
		stuckCount = 3,
		shieldUntil = 0,
		immuneUntil = 0,
		lastBumpAt = 0,
		bumpCooldown = 1,
	}
	for key, value in overrides do
		(base :: any)[key] = value
	end
	return base
end

test("decide: a plain hit on a ball with stuck objects knocks", function()
	expect.equal(Knock.decide(input({})), "Knock")
end)

test("decide: nothing stuck and no shield", function()
	expect.equal(Knock.decide(input({ stuckCount = 0 })), "NothingStuck")
end)

test("decide: inside the cooldown", function()
	expect.equal(Knock.decide(input({ lastBumpAt = 99.5 })), "Cooldown")
	expect.equal(Knock.decide(input({ lastBumpAt = 99 })), "Knock")
end)

test("decide: a shield absorbs, even with nothing stuck", function()
	expect.equal(Knock.decide(input({ shieldUntil = 110 })), "ShieldAbsorbed")
	expect.equal(Knock.decide(input({ shieldUntil = 110, stuckCount = 0 })), "ShieldAbsorbed")
	expect.equal(Knock.decide(input({ shieldUntil = 100 })), "Knock")
end)

test("decide: immunity beats everything", function()
	expect.equal(
		Knock.decide(
			input({ immuneUntil = 103, shieldUntil = 110, lastBumpAt = 99.9, stuckCount = 0 })
		),
		"Immune"
	)
	expect.equal(Knock.decide(input({ immuneUntil = 100 })), "Knock")
end)

test("decide: cooldown beats the shield", function()
	expect.equal(Knock.decide(input({ shieldUntil = 110, lastBumpAt = 99.5 })), "Cooldown")
end)

test("ballBump: size ratio and closing threshold", function()
	expect.truthy(Knock.ballBump(5, 4, 20, 1.25, 15))
	expect.falsy(Knock.ballBump(5, 4.1, 20, 1.25, 15))
	expect.falsy(Knock.ballBump(5, 4, 14.9, 1.25, 15))
	expect.truthy(Knock.ballBump(5, 4, 15, 1.25, 15))
end)

test("closingSpeed: a retreating ball reduces it, an approaching one does not", function()
	expect.near(Knock.closingSpeed(30, -5), 30, 1e-9)
	expect.near(Knock.closingSpeed(30, 12), 18, 1e-9)
	expect.near(Knock.closingSpeed(10, 12), 0, 1e-9)
end)
