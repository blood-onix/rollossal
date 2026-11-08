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
	-- Too-big objects (by id) that a ball can bump without losing anything: nothing is knocked off. Hedge pieces make
	-- up the Park City maze, and the Roof Run buildings have a flat top the ball rolls on.
	softObstacles = {
		hedge_piece = true,
		roof_building_1 = true,
		roof_building_2 = true,
		roof_building_3 = true,
		roof_building_4 = true,
		roof_building_5 = true,
		roof_building_6 = true,
		roof_building_7 = true,
		roof_building_8 = true,
	} :: { [string]: boolean },
	scatterDistance = 6,
	scatterGrace = 1.0,

	-- Park City map (specs/012-park-city-map). Starting points; tuning is owner work.
	heapNewestGrace = 3,
	heapFitMaxScale = 0.45,
	heapFitBound = 1.25,
	heapFitNewestBound = 0.25,
	bobCount = 24,
	bobRadiusDiameters = 4,
	wobbleRadiusDiameters = 6,
	lightPoolCap = 450,
	lightDrawRadius = 120,
	lightCellSize = 64,
	lightRefreshSeconds = 0.2,
	lightRefreshStuds = 10,
	lightDeltaSeconds = 0.25,

	-- Snow Village world (specs/004-snow-village/contracts/world-content.md)
	respawnDelayMin = 60,
	respawnDelayMax = 120,
	respawnOutOfSightRadius = 45,
	respawnViewDistance = 120,
	respawnViewCos = 0.5,
	respawnHeadingMinSpeed = 2,
	respawnForceAfterSeconds = 180,
	cullTierDelta = 2,
	spawnClusterRadius = 45,
	streamRequestTimeout = 5,

	-- Anti-exploit
	absorbRateLimit = 10,
	rateLimitWindow = 1,
	absorbDistanceTolerance = 6.0,
	-- A bump needs the ball to be within this many studs of the object's box (not of its centre plus half its longest side).
	bumpContactTolerance = 2.5,
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
	cameraMaxDistance = 320,
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

	-- Mechanics pass (specs/006-jump-boosters-traps/research.md R-18). All values are provisional playtest inputs.
	-- Jump
	jumpClearRatio = 0.6,
	jumpHoldClearRatio = 0.85,
	minJumpClearHeight = 1.6,
	jumpHoldMaxSeconds = 0.25,
	jumpCooldown = 0.3,
	landingMinSpeed = 12,
	landingSquashScale = 0.8,
	landingSquashDuration = 0.15,
	-- Vertical guard
	verticalSlack = 1.25,
	airEnergyAllowance = 1.0,
	maxSlopeRatio = 0.5,
	-- Speed
	dashSpeedMultiplier = 2.0,
	boostSpeedCap = 80,
	boostDecayGrace = 0.5,
	-- Claiming
	boosterRadius = 2.5,
	boosterRespawnDelay = 20,
	boosterClaimRateLimit = 4,
	springCooldown = 2,
	-- Durations (seconds)
	dashDuration = 3,
	magnetDuration = 6,
	shieldDuration = 15,
	slickTrailDuration = 8,
	-- Magnet
	magnetRadiusFactor = 3.0,
	magnetPullSpeed = 14,
	magnetMaxPulled = 24,
	magnetScanInterval = 0.1,
	-- Spring
	springVerticalSpeed = 70,
	springForwardSpeed = 40,
	springFlightDuration = 1.5,
	-- Slick trail
	slickTrailSpacing = 4,
	slickTrailMaxPatches = 8,
	slickTrailPatchLifetime = 5,
	slickTrailPoolSize = 48,
	-- Traps
	slickTurnMultiplier = 0.25,
	slickLingerSeconds = 0.6,
	slowSpeedMultiplier = 0.5,
	slowLingerSeconds = 0.5,
	bumperBounceSpeed = 28,
	sweeperSpeed = 10,
	sweeperBounceSpeed = 34,
	hazardContactMargin = 0.5,
	-- Ball-to-ball bumps
	ballBumpSizeRatio = 1.25,
	ballBumpImmunitySeconds = 3.0,
	ballBumpContactMargin = 0.5,

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

	-- Saving and economy (specs/003-saving-and-economy/contracts/content-and-config.md)
	dataStoreName = "PlayerProfiles_v1",
	playerKeyPrefix = "Player_",
	useMockDataStoreInStudio = true,
	runStartUiLockSeconds = 5,
	settingsRateLimit = 20,
	settingsSendDelay = 0.3,
	minUtilityTouchTarget = 64,
	noticeSeconds = 2,
	debugFpsWarmupSeconds = 5,
	Settings = {
		musicVolume = { default = 0.4, min = 0, max = 1 },
		effectsVolume = { default = 0.8, min = 0, max = 1 },
		cameraSensitivity = { default = 1.0, min = 0.5, max = 2.0 },
		reduceMotionDefault = false,
		languageDefault = "auto",
		languages = { "auto", "en-us", "es-es" },
	},
	DefaultWorldsUnlocked = { greybox = true, snow_village = true, downtown = true },

	-- Flags (AvatarPusher, BigBallMode and RewardedAds exist, unused, off)
	Flags = {
		AvatarPusher = false,
		BigBallMode = false,
		RewardedAds = false,
		RunLoop = true,
		Saving = true,
		-- Owner-only FPS overlay (FpsReadout); shown to the experience creator only. Turn off before a public launch.
		DebugFps = true,
		Shop = false,
		SnowVillage = true,
		-- Downtown (007): the launch world. Off falls back to Snow Village, then the grey-box room.
		Downtown = true,
		-- Theme system (005). On: the active theme's lighting, weather and music apply. Off: the theme's
		-- palette, slots and textures still apply (the base zones need them), with no lighting, weather or music.
		ThemeSystem = true,
		-- Mechanics pass (006). Each mechanic is live only when its master flag and its own flag are true.
		-- ScaledJump off restores the 001 hop (jumpImpulse).
		ScaledJump = true,
		Boosters = true,
		BoosterDash = true,
		BoosterMagnet = true,
		BoosterSpring = true,
		BoosterShield = true,
		BoosterSlickTrail = true,
		Traps = true,
		TrapSlick = true,
		TrapBumper = true,
		TrapSlow = true,
		TrapSweeper = true,
		BallToBallBumps = true,
		-- Park City map (012). All off until the owner approves. ParkCity implies HeapFix.
		ParkCity = true,
		HeapFix = false,
		ReadableRules = false,
		-- Studio-only size tool. Must be off in anything published.
		DebugSize = false,
	},

	-- Studio-only: Debug.spawnSlot 0 is off. A number from 1 to the world's spawn count puts every new ball and every respawn on
	-- that spawn slot (Park City has 12; the maze is next to 10, 11 and 12). Must be 0 in anything published.
	Debug = {
		spawnSlot = 0,
		-- Studio-only: true mutes the music and cuts the sound effects to quietEffectsVolume. Must be false in anything
		-- published.
		quietAudio = false,
		quietEffectsVolume = 0.2,
	},

	-- Budgets. meshTriangles is indexed by tier. Theme budgets: weather particles, dressing slot share
	-- and the default placement cap (snow village sets 1700; data-model.md §7 and research R-11).
	Budgets = {
		maxActivePartsPerServer = 2000,
		meshTriangles = { 500, 700, 1500, 3500, 5000 },
		-- Park City and readable Downtown have six tiers; Tier 6 (Skyline) reuses the top budget (012 T009).
		meshTrianglesSix = { 500, 700, 1500, 3500, 5000, 5000 },
		maxWeatherParticles = 40,
		maxDressingSlotShare = 0.15,
		defaultMaxPlacements = 1500,
		-- Billboard designs packed in the fronts and signs atlas (constitution XI; 013 D1).
		billboardTextures = 8,
	},
	-- Weather emitter geometry (studs: the emission box above and around the camera; researcher R-08).
	weatherEmitterHeight = 30,
	weatherEmitterSize = 60,
}

return table.freeze(Config)
