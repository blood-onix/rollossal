--!strict
-- Every tuning number, flag and budget. Read-only. No magic numbers elsewhere (FR-012).
-- Values and sources: specs/001-grey-box-prototype/contracts/config-and-content.md

local Config = {
	-- Gameplay
	startDiameter = 2,
	absorbRatio = 0.4,
	growthK = 0.6,
	maxVisibleStuck = 30,
	maxTrackedStuck = 120,
	knockOffCount = 3,
	bumpSpeedThreshold = 15,
	bumpSpeedWindow = 0.35,
	bumpCooldown = 1.0,
	respawnDelay = 15,
	scatterDistance = 6,
	scatterGrace = 1.0,

	-- Anti-exploit
	absorbRateLimit = 10,
	rateLimitWindow = 1,
	absorbDistanceTolerance = 6.0,
	maxServerBallSpeed = 56,
	displacementSlack = 4,
	fallRespawnY = -50,
	respawnBallCooldown = 3,

	-- Movement, camera, jump
	speedExponent = 0.5,
	baseSpeed = 18,
	speedCap = 32,
	cameraMultiplier = 4,
	cameraMinDistance = 8,
	cameraMaxDistance = 80,
	cameraSmoothing = 4,
	jumpImpulse = 24,
	groundProbeExtra = 0.3,
	growTime = 0.25,
	clientContactMargin = 0.3,
	clientSendBudget = 8,
	rollTorqueGain = 60,
	rollForceGain = 6,
	stuckVisualMode = "Weld",
	stuckEmbed = 0.35,

	-- Run loop (specs/002-run-loop/data-model.md §1)
	runDurationSeconds = 240,
	rollAgainDelaySeconds = 3,
	starThresholds = { 20, 45, 80 },
	friendBonusRate = 0.20,
	friendBoostRate = 0.25,
	pickupPopDuration = 1.0,
	tierBannerDuration = 2.5,
	knockOffShakeDuration = 0.35,
	knockOffShakeMagnitude = 0.6,
	pickupPitchStep = 0.08,
	minTextSize = 18,
	minTouchTarget = 96,
	uiReferenceShortSide = 720,

	-- Flags (AvatarPusher, BigBallMode and RewardedAds exist, unused, off)
	Flags = {
		AvatarPusher = false,
		BigBallMode = false,
		RewardedAds = false,
		RunLoop = true,
	},

	-- Budgets. meshTriangles is indexed by tier.
	Budgets = {
		maxActivePartsPerServer = 500,
		meshTriangles = { 300, 300, 800, 2500, 2500 },
	},
}

return table.freeze(Config)
