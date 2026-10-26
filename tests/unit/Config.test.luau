--!strict
-- Sanity checks on src/shared/Config.luau (data-model §1). Expected values are written out by hand.

local harness = require("./harness")
local Config = require("../../src/shared/Config")

local test, expect = harness.test, harness.expect

-- Walks every number in the table and reports any that is not finite, or that is zero
-- when zero is not allowed. Returns the first offending key path, or nil.
local function findBadNumber(value: unknown, path: string): string?
	if type(value) == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return path
		end
		return nil
	elseif type(value) == "table" then
		for key, child in value :: { [string]: unknown } do
			local bad = findBadNumber(child, `{path}.{tostring(key)}`)
			if bad then
				return bad
			end
		end
	end
	return nil
end

test("Config: every number is finite", function()
	expect.equal(findBadNumber(Config, "Config"), nil)
end)

test("Config: every positive number is greater than zero except fallRespawnY", function()
	for key, value in Config :: { [string]: unknown } do
		if type(value) == "number" and key ~= "fallRespawnY" then
			expect.truthy(value > 0)
		end
	end
	expect.truthy(Config.fallRespawnY < 0)
	expect.equal(Config.fallRespawnY, -50)
end)

test("Config: camera min distance is at most max distance", function()
	expect.truthy(Config.cameraMinDistance <= Config.cameraMaxDistance)
end)

test("Config: base speed is at most the speed cap", function()
	expect.truthy(Config.baseSpeed <= Config.speedCap)
end)

test("Config: speed cap is below the server speed limit", function()
	expect.truthy(Config.speedCap < Config.maxServerBallSpeed)
	expect.equal(Config.maxServerBallSpeed, 56)
end)

test("Config: start diameter is at least 2", function()
	expect.truthy(Config.startDiameter >= 2)
	expect.equal(Config.startDiameter, 2)
end)

test("Config: knock-off count is at least 1", function()
	expect.truthy(Config.knockOffCount >= 1)
end)

test("Config: visible stuck is at most tracked stuck", function()
	expect.truthy(Config.maxVisibleStuck <= Config.maxTrackedStuck)
	expect.equal(Config.maxVisibleStuck, 30)
end)

test("Config: stuck visual mode is Weld or Follower", function()
	expect.truthy(Config.stuckVisualMode == "Weld" or Config.stuckVisualMode == "Follower")
end)

test("Config: the three feature flags exist and are off", function()
	expect.equal(Config.Flags.AvatarPusher, false)
	expect.equal(Config.Flags.BigBallMode, false)
	expect.equal(Config.Flags.RewardedAds, false)
end)

test("Config: star thresholds ascend, are positive and number 3", function()
	local thresholds = Config.starThresholds
	expect.equal(#thresholds, 3)
	expect.truthy(thresholds[1] > 0)
	for i = 2, #thresholds do
		expect.truthy(thresholds[i] > thresholds[i - 1])
	end
end)

test("Config: the run loop flag is a boolean", function()
	expect.equal(type(Config.Flags.RunLoop), "boolean")
end)

test("Config: mesh triangle budgets per tier are 300, 300, 800, 2500, 2500", function()
	local expected = { 300, 300, 800, 2500, 2500 }
	local actual = Config.Budgets.meshTriangles
	expect.equal(#actual, 5)
	for tier, value in expected do
		expect.equal(actual[tier], value)
	end
end)

test("Config: data store name, key prefix and run-start lock are the approved values", function()
	expect.equal(Config.dataStoreName, "PlayerProfiles_v1")
	expect.equal(Config.playerKeyPrefix, "Player_")
	expect.equal(Config.runStartUiLockSeconds, 5)
	expect.equal(Config.useMockDataStoreInStudio, true)
end)

test("Config: settings rate limit, send delay and notice length", function()
	expect.equal(Config.settingsRateLimit, 20)
	expect.equal(Config.settingsSendDelay, 0.3)
	expect.equal(Config.noticeSeconds, 2)
end)

test("Config.Settings: each default lies inside its range and min is below max", function()
	local fields = {
		Config.Settings.musicVolume,
		Config.Settings.effectsVolume,
		Config.Settings.cameraSensitivity,
	}
	for _, field in fields do
		expect.truthy(field.min < field.max)
		expect.truthy(field.default >= field.min)
		expect.truthy(field.default <= field.max)
	end
	expect.equal(Config.Settings.musicVolume.max, 1)
	expect.equal(Config.Settings.cameraSensitivity.min, 0.5)
	expect.equal(Config.Settings.cameraSensitivity.max, 2.0)
end)

test("Config.Settings: languages are auto, en-us, es-es and the default is one of them", function()
	local languages = Config.Settings.languages
	expect.equal(#languages, 3)
	expect.equal(languages[1], "auto")
	expect.equal(languages[2], "en-us")
	expect.equal(languages[3], "es-es")
	expect.truthy(table.find(languages, Config.Settings.languageDefault) ~= nil)
	expect.equal(Config.Settings.reduceMotionDefault, false)
end)

test(
	"Config: utility touch target is between the text size and the primary touch target",
	function()
		expect.truthy(Config.minUtilityTouchTarget < Config.minTouchTarget)
		expect.truthy(Config.minUtilityTouchTarget >= Config.minTextSize)
		expect.equal(Config.minUtilityTouchTarget, 64)
	end
)

test("Config: default unlocked worlds are greybox and snow_village", function()
	expect.equal(Config.DefaultWorldsUnlocked.greybox, true)
	expect.equal(Config.DefaultWorldsUnlocked.snow_village, true)
end)

test("Config: Snow Village respawn, sight and culling values", function()
	expect.equal(Config.respawnDelayMin, 60)
	expect.equal(Config.respawnDelayMax, 120)
	expect.truthy(Config.respawnDelayMin <= Config.respawnDelayMax)
	expect.equal(Config.respawnOutOfSightRadius, 45)
	expect.equal(Config.respawnViewDistance, 120)
	expect.truthy(Config.respawnOutOfSightRadius <= Config.respawnViewDistance)
	expect.equal(Config.respawnViewCos, 0.5)
	expect.truthy(Config.respawnViewCos > 0 and Config.respawnViewCos < 1)
	expect.equal(Config.respawnHeadingMinSpeed, 2)
	expect.equal(Config.respawnForceAfterSeconds, 180)
	expect.truthy(Config.respawnForceAfterSeconds > Config.respawnDelayMax)
	expect.equal(Config.cullTierDelta, 2)
	expect.equal(Config.spawnClusterRadius, 45)
	expect.equal(Config.streamRequestTimeout, 5)
end)

test("Config: the obsolete respawnDelay is gone", function()
	expect.equal((Config :: { [string]: unknown }).respawnDelay, nil)
end)

test("Config: Snow Village flag is on and the part budget is 2000", function()
	expect.equal(Config.Flags.SnowVillage, true)
	expect.equal(Config.Budgets.maxActivePartsPerServer, 2000)
end)

test("Config: Saving flag is on and Shop flag is off", function()
	expect.equal(Config.Flags.Saving, true)
	expect.equal(Config.Flags.Shop, false)
end)

return {}
