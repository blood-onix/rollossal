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
	bumpCooldown = 2.0,
	-- A bump can only cost the ball down to this share of the biggest it has been this run.
	knockFloorRatio = 0.9,
	-- Park City: below this size a bump costs nothing, because the ball has only just started.
	knockMinDiameter = 4,
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
	absorbRateLimit = 40,
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
	clientSendBudget = 30,
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
	-- Toys on the map (ToyService, ToyRides). Heights are studs of rise; the layout's `up` values are scaled here.
	-- Rails (grind rails, ziplines, the rail yard tracks, the Sky Rail) are off: thin glowing lines with no hint of
	-- what they do or which size rides them. Pipes stay. Turn on again once a rail reads as a ride.
	toyRails = false,
	toyBoostSpeed = 75,
	toyBoostDash = 2,
	toyBoostFlight = 1.2,
	toyBounceApexFloor = 18,
	toyBounceApexScale = 3,
	toyBounceForwardScale = 2.5,
	toySpringApexScale = 1.6,
	toyPadVerticalReach = 2.5,
	toyPadCooldown = 0.8,
	toyCatapultCooldown = 3,
	-- A catapult throws only a ball sitting in its bucket: the bucket is this far behind the frame, and the ball's
	-- centre must be within the reach (plus a share of its diameter). A big slingshot doubles all three.
	toyCatapultBucket = 4.4,
	toyCatapultReach = 2.5,
	toyCatapultReachPerDiameter = 0.15,
	toyMinSizeScale = 0.5,
	toyMaxSizeScale = 1.5,
	toyRailReach = 2,
	toyRailAboveBall = 6,
	toyRailEndReach = 10,
	toyRailAlignment = 0.8,
	toyRailSpeedScale = 1.4,
	toyRailCooldown = 2.5,
	toyRailExitUp = 25,
	toyPipeReach = 4.5,
	toyPipeSpeedScale = 2.5,
	toyPipeExitUp = 70,
	toyPipeExitForward = 25,
	toyRideGuardSpeed = 120,
	toyFlightSpeedCap = 220,
	toyFlightGrace = 0.6,
	-- A size-tier jump sucks in everything edible around the ball for a moment.
	vacuumSeconds = 1.2,
	vacuumRadiusFactor = 3,
	vacuumRadiusFloor = 8,
	vacuumRadiusCeiling = 30,
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

	-- Fun slice (2026-11-10, owner: "one section of the map, fun in two modes"). All numbers are tuning.
	-- Play is fenced to one section of Park City: the north-east park quarter, its neighbourhood and the Plaza.
	Slice = {
		enabled = true,
		minX = -560,
		maxX = 560,
		minZ = -560,
		maxZ = 560,
		spawnSlots = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
		wallHeight = 220,
		-- Booster spots in the section's park (yaw in degrees; a spring pad throws along its facing).
		boosters = {
			{ kind = "dash", x = 380, z = -380 },
			{ kind = "dash", x = 110, z = -430 },
			{ kind = "dash", x = 330, z = -110 },
			{ kind = "magnet", x = 430, z = -260 },
			{ kind = "magnet", x = 280, z = -450 },
			{ kind = "magnet", x = 60, z = -330 },
			{ kind = "shield", x = 460, z = -80 },
			{ kind = "shield", x = 330, z = -330 },
			{ kind = "spring", x = 340, z = -220, yaw = 0 },
			{ kind = "slick_trail", x = 240, z = -400 },
			{ kind = "dash", x = 110, z = 430 },
			{ kind = "dash", x = 330, z = 110 },
			{ kind = "dash", x = 300, z = 480 },
			{ kind = "magnet", x = 430, z = 260 },
			{ kind = "magnet", x = 60, z = 330 },
			{ kind = "shield", x = 460, z = 80 },
			{ kind = "shield", x = 330, z = 330 },
			{ kind = "spring", x = 340, z = 220, yaw = 0 },
			{ kind = "slick_trail", x = 240, z = 400 },
			{ kind = "dash", x = -110, z = -430 },
			{ kind = "dash", x = -330, z = -110 },
			{ kind = "dash", x = -300, z = 480 },
			{ kind = "dash", x = -330, z = 110 },
			{ kind = "dash", x = -110, z = 430 },
			{ kind = "magnet", x = -430, z = -260 },
			{ kind = "magnet", x = -60, z = -330 },
			{ kind = "magnet", x = -60, z = 330 },
			{ kind = "shield", x = -280, z = -450 },
			{ kind = "shield", x = -330, z = 330 },
			{ kind = "spring", x = -340, z = -220, yaw = 0 },
			{ kind = "slick_trail", x = -240, z = -400 },
			{ kind = "slick_trail", x = -240, z = 400 },
		} :: { { kind: string, x: number, z: number, yaw: number? } },
	},
	-- Launch ramps (LaunchRamps): a ball rolling up one at minSpeed or more is thrown forward at forwardSpeed (or
	-- its own speed times speedGain, if more, up to maxForwardSpeed) and up at upSpeed plus upPerDiameter for each stud of its diameter.
	-- A ramp starts at x, z and climbs along yaw (degrees; 0 is +Z, 90 is +X). The launch fires on the part of the
	-- ramp past launchFrom of its length.
	Ramps = {
		enabled = true,
		length = 40,
		width = 24,
		height = 12,
		launchFrom = 0.6,
		launchHeadroom = 4,
		minSpeed = 10,
		forwardSpeed = 72,
		speedGain = 2,
		-- Kept under the server's speed ceiling for a launched ball (80).
		maxForwardSpeed = 76,
		upSpeed = 95,
		upPerDiameter = 0.6,
		flightSeconds = 2.5,
		cooldown = 2,
		-- Each ramp stands on park grass beside the Ring Road and throws along the park: clear of every road, path,
		-- kerb, pond and scene, with open grass where the ball comes down.
		spots = {
			{ x = -360, z = 190, yaw = 180 },
			{ x = 70, z = -340, yaw = 270 },
			{ x = -30, z = 340, yaw = 270 },
			{ x = 340, z = 130, yaw = 180 },
			{ x = -190, z = -340, yaw = 90 },
			{ x = 170, z = 320, yaw = 270 },
		},
	},
	-- Crown zone (MapEvents): a glowing circle that grows every ball standing in it by growPerSecond of its
	-- diameter each second. It appears firstAt seconds into the round and moves every moveSeconds.
	Hill = {
		enabled = true,
		radius = 22,
		growPerSecond = 0.045,
		interval = 0.5,
		firstAt = 20,
		moveSeconds = 45,
		-- Once a player stands in it the zone closes this many seconds later, then stays away for restSeconds.
		useSeconds = 4,
		restSeconds = 25,
		-- A ball this far above its own radius is flying over, not standing in the zone.
		headroom = 4,
		discTransparency = 0.6,
		beamTransparency = 0.55,
		spots = {
			{ x = -400, z = -240 },
			{ x = 280, z = -280 },
			{ x = -240, z = 360 },
			{ x = 320, z = 240 },
			{ x = -360, z = -40 },
			{ x = 40, z = 360 },
		},
	},
	-- Golden drop (MapEvents): a golden orb under a sky beam. The first ball to touch it grows by growShare of its
	-- diameter, or minGain studs if that is more. One drops firstAt seconds into the round and then every `every`
	-- seconds, and waits lifeSeconds on the ground to be taken.
	-- The Giant Oak shakes (MapEvents): every `every` seconds it drops food round its foot for each player within
	-- `radius`, sized for that player's ball, so the tree is worth a visit at any size. perPlayer pieces each,
	-- set down between ringMin and ringMax studs from the trunk.
	Shake = {
		enabled = true,
		x = -370,
		z = -370,
		firstAt = 12,
		every = 25,
		radius = 110,
		perPlayer = 7,
		ringMin = 34,
		ringMax = 62,
	},
	Golden = {
		enabled = true,
		firstAt = 35,
		every = 40,
		lifeSeconds = 30,
		-- The orb takes fallSeconds to float down from fallHeight; nobody can take it until it lands.
		fallSeconds = 5,
		-- A drop lands between these distances of some player when a spot in that band exists.
		playerMin = 60,
		playerMax = 220,
		fallHeight = 120,
		growShare = 0.12,
		minGain = 1.5,
		orbSize = 7,
		hover = 5,
		bob = 1,
		reach = 4,
		beamTransparency = 0.45,
		spots = {
			{ x = -480, z = -160 },
			{ x = -480, z = 80 },
			{ x = -320, z = 0 },
			{ x = -320, z = 320 },
			{ x = -240, z = -480 },
			{ x = -240, z = -320 },
			{ x = -80, z = -400 },
			{ x = 0, z = -320 },
			{ x = 0, z = 400 },
			{ x = 80, z = -480 },
			{ x = 80, z = 320 },
			{ x = 240, z = 480 },
			{ x = 320, z = 80 },
			{ x = 400, z = -80 },
			{ x = 400, z = 320 },
			{ x = 480, z = -320 },
			{ x = 480, z = 0 },
			{ x = 480, z = 400 },
		},
	},
	-- How long an event banner (crown zone moved, golden drop) stays on screen.
	eventBannerSeconds = 5,
	-- "Classic": biggest ball at the bell. "Feast": the same, and balls eat smaller balls once the grace ends.
	-- "Alternate": Feast, then Classic, then Feast, round by round.
	gameMode = "Alternate",
	feastGraceSeconds = 60,
	-- A ball eats another whose diameter is at most this share of its own.
	feastEatRatio = 0.75,
	-- The eater gains this share of the victim's volume; the victim keeps this share of its diameter.
	feastGainShare = 0.5,
	feastKeepShare = 0.6,
	feastShieldSeconds = 5,
	-- Eating takes bites: each touch takes a bite and throws the victim clear, and the last of feastBitesToSwallow
	-- bites that came within feastBiteWindow seconds of each other swallows it (it then comes back at a spawn).
	feastBiteKeep = 0.82,
	feastBitesToSwallow = 3,
	feastBiteWindow = 7,
	feastBiteShieldSeconds = 1.2,
	feastBiteKnockSpeed = 38,
	feastBiteKnockUp = 14,
	feastContactMargin = 1,
	feastContactShare = 0.08,
	-- A ball with a hunter this close (in hunter diameters, never under the floor) rolls faster, so it can get away.
	feastFleeMultiplier = 1.3,
	feastFleeRadiusDiameters = 5,
	feastFleeRadiusFloor = 30,
	-- Touching a ball that is too big to bite (and too small to bite you) bounces your ball off it at this speed;
	-- the "Too big!" note shows for feastEvenNoteSeconds and cannot repeat sooner than feastEvenCooldown.
	feastEvenBounceSpeed = 22,
	feastEvenBounceUp = 6,
	feastEvenNoteSeconds = 1,
	feastEvenCooldown = 1.2,
	feastEvenContactMargin = 0.6,
	-- Food flow (FlowService, Rules/Flow): keeps food a ball can eat within a ring around it. "need" is the diameter
	-- an object asks for. Light food (the smallest two tiers) regrows behind the ball; bigger objects are brought in
	-- from the parts of the map nobody is using and from what has just been eaten.
	Flow = {
		enabled = true,
		interval = 1,
		maxDiameter = 45,
		radiusBase = 25,
		radiusPerDiameter = 6,
		radiusMin = 30,
		radiusMax = 170,
		-- An object counts when its need is between this share of the ball's diameter and the diameter itself.
		worthShare = 0.4,
		-- Pieces of worthwhile food the ring should hold, and how many may arrive per ball per tick.
		target = 6,
		perTick = 1,
		-- A ball under smallDiameter eats a piece a second or more, so its ring holds more and fills faster.
		smallDiameter = 8,
		smallTarget = 10,
		smallPerTick = 3,
		-- A small ball's pieces are close to the biggest it can eat, so each one is a visible step up.
		smallNeedLow = 0.65,
		smallNeedHigh = 1,
		-- A new piece asks for a diameter between these shares of the ball; a skew under 1 leans to the big end.
		needLow = 0.4,
		needHigh = 0.8,
		needSkew = 1,
		needTolerance = 0.25,
		-- Pieces land between this share of the radius and the radius, within this angle of the ball's heading.
		nearShare = 0.3,
		spreadDegrees = 100,
		placeTries = 6,
		-- No piece lands closer to any ball than this many of that ball's diameters, plus the floor.
		clearDiameters = 2,
		clearFloor = 10,
		groundTolerance = 2.5,
		reuseAfterSeconds = 3,
		-- A piece the flow set down that no ball is within this distance of may be moved again.
		strayRadius = 200,
		-- Small food the flow can place. The map's own small food is fixed data, so without this stock nothing
		-- can be brought to a ball under about size 8. The pieces wait out of sight at stockOrigin, outside the
		-- section. kind = an object id; count = how many of it.
		stock = {
			{ kind = "acorn", count = 8 },
			{ kind = "pine_cone", count = 10 },
			{ kind = "tennis_ball", count = 12 },
			{ kind = "cup_small", count = 12 },
			{ kind = "tulip", count = 12 },
			{ kind = "trainer", count = 10 },
			{ kind = "apple", count = 12 },
			{ kind = "rubber_duck", count = 10 },
			{ kind = "cupcake", count = 10 },
			{ kind = "garden_gnome", count = 10 },
			{ kind = "present", count = 10 },
			{ kind = "picnic_basket", count = 8 },
			{ kind = "cool_box", count = 8 },
			{ kind = "football", count = 8 },
			{ kind = "deckchair", count = 8 },
			{ kind = "wheelie_bin", count = 8 },
			{ kind = "mailbox", count = 6 },
			{ kind = "bicycle", count = 6 },
			{ kind = "flower_planter", count = 6 },
		},
		stockOrigin = { x = -900, y = -80, z = 300 },
		stockSpacing = 10,
		stockPerRow = 15,
		-- Light food comes back this long after it was eaten, once every ball is this far away.
		lightSeconds = 8,
		lightKeepAway = 18,
		lightPerTick = 12,
	},

	-- Bot rivals: server-driven balls that fill the round.
	-- Eleven bots and a player: the 12 balls the map was sized for (docs/design/09-park-city-level.md, section 7).
	botCount = 11,
	botNames = {
		"Biscuit",
		"Noodle",
		"Pebble",
		"Waffle",
		"Pickle",
		"Mango",
		"Bubbles",
		"Tofu",
		"Peanut",
		"Dumpling",
		"Sprout",
		"Nacho",
	},
	-- Each bot rolls at a share of a player's speed, spread between these two, so a good player can beat them.
	botSpeedMin = 0.75,
	botSpeedMax = 1,
	-- A bot that falls behind is lifted to a pace curve, so no rival sits at the start size all round. Each bot's
	-- curve ends between these two sizes at the bell; a bot that eats well is above its curve and is left alone.
	botPaceFinishMin = 30,
	botPaceFinishMax = 80,
	botPaceExponent = 1.4,
	botPaceStep = 1.03,
	-- A bot bigger than its curve times botPaceCeiling, plus botPaceCeilingHead, eats no food until the curve
	-- catches up. At one minute that keeps the bots between about 5 and 16.
	botPaceCeiling = 1.3,
	botPaceCeilingHead = 1,
	-- Steering round what a bot cannot eat: it looks this many seconds of rolling ahead with a sphere this share of
	-- its own radius, tries these turns (degrees, either side) and holds the one that is clear for a moment. A
	-- surface whose normal points up more than botSteerSlopeNormal is a slope to roll up, not an obstacle.
	-- A bot this close to a golden drop races for it; a bot this close to the crown zone goes to stand in it.
	botOrbRadius = 100,
	-- Each bot notices a landed drop after its own delay between these two (seconds).
	botOrbDelayMin = 3,
	botOrbDelayMax = 8,
	botHillRadius = 140,
	botSteerLookSeconds = 0.4,
	botSteerRadiusShare = 0.8,
	botSteerAngles = { 35, 70, 110 },
	botSteerHoldSeconds = 0.3,
	botSteerSlopeNormal = 0.5,
	botAvoidSeconds = 8,
	botSweepSeconds = 0.1,
	botSweepReach = 3,
	botLightCell = 24,
	botSpawnRing = 7,
	-- Where bots start: spots in the section at least 120 studs from every player spawn. With more bots than spots
	-- the list repeats, spread by botSpawnRing.
	botSpawns = {
		{ x = 310, z = -330 },
		{ x = -310, z = 330 },
		{ x = 60, z = 420 },
		{ x = -60, z = -420 },
		{ x = 400, z = -40 },
		{ x = -400, z = -40 },
		{ x = 310, z = 330 },
		{ x = -310, z = -330 },
		{ x = 60, z = -420 },
		{ x = 80, z = 310 },
		{ x = 80, z = -310 },
		{ x = 300, z = -480 },
	},
	botSpawnDrop = 60,
	botKeepOutSeconds = 25,
	botKeepOutRadius = 60,
	botThinkSeconds = 0.35,
	botSeekRadius = 70,
	botSeekRadiusFloor = 40,
	botSeekRadiusPerDiameter = 4,
	botGarnishWorth = 0.05,
	botExploreSeconds = 3,
	botChaseRadius = 80,
	botStuckSeconds = 1.5,
	botStuckStuds = 2,
	botWanderSeconds = 1.2,
	-- Asteroid shower: once per round at a random moment in the window; each rock is announced by a ground ring.
	meteorWindowStart = 45,
	meteorWindowEnd = 170,
	meteorShowerSeconds = 18,
	meteorInterval = 0.45,
	meteorWarnSeconds = 1.6,
	meteorFallHeight = 160,
	meteorRadius = 7,
	meteorAimChance = 0.45,
	meteorAimSpread = 14,
	meteorShrinkShare = 0.12,
	meteorKnockSpeed = 45,
	leaderboardRows = 5,

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
		-- The map's pads, catapults, rails and pipes work.
		Toys = true,
		HeapFix = false,
		ReadableRules = false,
		-- Studio-only size tool. Must be off in anything published.
		DebugSize = false,
		-- Park City art (014): light objects draw through ObjectVisual (meshes and role-coloured stand-ins). Off draws
		-- the tier-coloured blocks of 012, for frame-rate triage on a phone.
		LightMeshes = true,
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
		-- Park City scene triangle ceilings (014 R-07): all Parts plus the light window, unculled and culled at a Tier 5
		-- ball. The owner pinned the current scene (2026-11-10: 1,107,221 and 416,921) so it cannot grow unnoticed;
		-- ParkCityBudget.test enforces them. The 12-ball benchmark held 60 fps in Studio; phones are not measured yet.
		parkCityTrianglesUnculled = 1110000 :: number?,
		parkCityTrianglesCulled = 420000 :: number?,
	},
	-- Weather emitter geometry (studs: the emission box above and around the camera; researcher R-08).
	weatherEmitterHeight = 30,
	weatherEmitterSize = 60,
}

return table.freeze(Config)
