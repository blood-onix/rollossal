--!strict
-- Expected values are hand-computed from contracts/rules-api.md §RateLimit.

local harness = require("./harness")
local RateLimit = require("../../src/shared/Rules/RateLimit")

local test, expect = harness.test, harness.expect

test("allow: first 10 calls at 0.05 s steps are allowed with limit 10", function()
	local stamps: { number } = {}
	for i = 0, 9 do
		local ok
		ok, stamps = RateLimit.allow(stamps, 100.0 + i * 0.05, 10, 1)
		expect.equal(ok, true)
	end
	expect.equal(#stamps, 10)
end)

test("allow: 11th call at 100.5 is refused", function()
	local stamps: { number } = {}
	for i = 0, 9 do
		local _
		_, stamps = RateLimit.allow(stamps, 100.0 + i * 0.05, 10, 1)
	end
	local ok
	ok, stamps = RateLimit.allow(stamps, 100.5, 10, 1)
	expect.equal(ok, false)
end)

test("allow: refused call appends nothing", function()
	local stamps: { number } = {}
	for i = 0, 9 do
		local _
		_, stamps = RateLimit.allow(stamps, 100.0 + i * 0.05, 10, 1)
	end
	local _, after = RateLimit.allow(stamps, 100.5, 10, 1)
	expect.equal(#after, 10)
end)

test("allow: call at 101.06 is allowed after the oldest entries age out", function()
	local stamps: { number } = {}
	for i = 0, 9 do
		local _
		_, stamps = RateLimit.allow(stamps, 100.0 + i * 0.05, 10, 1)
	end
	local ok = RateLimit.allow(stamps, 101.06, 10, 1)
	expect.equal(ok, true)
end)

test("allow: entry at exactly now - window is dropped", function()
	local ok, after = RateLimit.allow({ 100.0 }, 101.0, 1, 1)
	expect.equal(ok, true)
	expect.equal(#after, 1)
end)

return {}
