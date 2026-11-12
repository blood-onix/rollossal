--!strict
-- Rival UI: a name tag over every other ball, the size leaderboard on the left, the mode banner under the star
-- row, and the Feast feed (who ate whom, with a splat or a chomp when it is you). Client only: it reads the
-- replicated balls and round attributes and the FeastEvent remote; the server still decides every eat.
-- All player-facing text goes through Localizer.t.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Localizer = require(Shared.Localization.Localizer)
local Feast = require(Shared.Rules.Feast)
local RunClient = require(script.Parent.RunClient)
local UiKit = require(script.Parent.UiKit)

local CROWN = "👑"
local TAG_WIDTH = 160
local TAG_HEIGHT = 56
local TAG_TEXT_SIZE = 20
local TAG_MAX_DISTANCE = 400
local TAG_LIFT = 1.5
local TAG_SECONDS = 0.2
local NOTE_TEXT_SIZE = 28
local OUTLINE_FILL = 0.8
local BOARD_SECONDS = 0.5
local BANNER_SECONDS = 0.25
local BOARD_LEFT = 8
local BOARD_TOP = 300
local ROW_WIDTH = 200
local ROW_HEIGHT = 24
local BANNER_TOP = 96
local BANNER_WIDTH = 420
local BANNER_HEIGHT = 30
local BANNER_TEXT_SIZE = 22
local FEED_TOP = 130
local FEED_WIDTH = 480
local FEED_HEIGHT = 30
local FEED_SECONDS = 2.5
local SPLAT_SECONDS = 1.5
local SPLAT_TEXT_SIZE = 64
local CHOMP_SECONDS = 1
local CHOMP_TEXT_SIZE = 48
local BIG_WIDTH = 600
local BIG_HEIGHT = 90

local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 80, 70)
local GREEN = Color3.fromRGB(110, 230, 120)
local GOLD = Color3.fromRGB(255, 214, 90)
local ORANGE = Color3.fromRGB(255, 170, 30)

type Ball = {
	part: BasePart,
	userId: number,
	name: string,
	diameter: number,
}

type Tag = {
	gui: BillboardGui,
	label: TextLabel,
	part: BasePart,
	linked: RBXScriptConnection?,
	outline: Highlight,
	-- Server time until which the tag shows the "Too big!" note instead of the name.
	noteUntil: number,
}

local RivalUi = {}

local function diameterOf(part: BasePart): number
	local value = part:GetAttribute("Diameter")
	return if typeof(value) == "number" then value else 0
end

local function nameOf(part: BasePart): string
	local value = part:GetAttribute("DisplayName")
	return if typeof(value) == "string" then value else ""
end

local function formatSize(diameter: number): string
	return string.format("%.1f", diameter)
end

-- ShowerEndsAt and FeastOpensAt are server times; 0 or a missing attribute reads as "not set".
local function feastOpensAt(): number
	local value = Workspace:GetAttribute("FeastOpensAt")
	return if typeof(value) == "number" then value else 0
end

local function feastOpen(now: number): boolean
	local opensAt = feastOpensAt()
	return Workspace:GetAttribute("RoundMode") == "Feast" and opensAt > 0 and now >= opensAt
end

-- What can happen between a rival and the local ball while Feast eating is open: "danger" (it can bite you),
-- "food" (you can bite it), "even" (neither), or "none" when eating is closed.
local function relation(theirs: number, mine: number, open: boolean): string
	if not open or mine <= 0 then
		return "none"
	end
	if Feast.canEat(theirs, mine, Config.feastEatRatio) then
		return "danger"
	end
	if Feast.canEat(mine, theirs, Config.feastEatRatio) then
		return "food"
	end
	return "even"
end

local RELATION_COLOUR: { [string]: Color3 } = {
	none = WHITE,
	danger = RED,
	food = GREEN,
	even = WHITE,
}

function RivalUi.start()
	local player = Players.LocalPlayer
	local localId = player.UserId
	local ownName = `Ball_{localId}`
	local ballsFolder = Workspace:WaitForChild("Balls") :: Folder
	local gui = UiKit.screen("RivalUi")

	local hud = Instance.new("Frame")
	hud.Name = "RivalHud"
	hud.BackgroundTransparency = 1
	hud.Size = UDim2.fromScale(1, 1)
	hud.Parent = gui

	local function reduceMotion(): boolean
		return player:GetAttribute("ReduceMotion") == true
	end

	-- Every ball, biggest first; ties go to the lower user id so the order is stable.
	local function sortedBalls(): { Ball }
		local list: { Ball } = {}
		for _, child in ballsFolder:GetChildren() do
			local digits = string.match(child.Name, "^Ball_(%-?%d+)$")
			if digits ~= nil and child:IsA("BasePart") then
				table.insert(list, {
					part = child :: BasePart,
					userId = tonumber(digits) or 0,
					name = nameOf(child :: BasePart),
					diameter = diameterOf(child :: BasePart),
				})
			end
		end
		table.sort(list, function(a: Ball, b: Ball): boolean
			if a.diameter ~= b.diameter then
				return a.diameter > b.diameter
			end
			return a.userId < b.userId
		end)
		return list
	end

	local function ownDiameter(list: { Ball }): number
		for _, ball in list do
			if ball.userId == localId then
				return ball.diameter
			end
		end
		return 0
	end

	-- Name tags: one per rival ball, lifted above its diameter.
	local tags: { [BasePart]: Tag } = {}

	local function refreshOffset(tag: Tag)
		tag.gui.StudsOffsetWorldSpace = Vector3.new(0, diameterOf(tag.part) / 2 + TAG_LIFT, 0)
	end

	local function addTag(part: BasePart)
		if
			part.Name == ownName
			or tags[part] ~= nil
			or string.match(part.Name, "^Ball_%-?%d+$") == nil
		then
			return
		end
		local tagGui = Instance.new("BillboardGui")
		tagGui.Name = "RivalTag"
		tagGui.Adornee = part
		tagGui.AlwaysOnTop = true
		tagGui.LightInfluence = 0
		tagGui.ResetOnSpawn = false
		tagGui.Size = UDim2.fromOffset(TAG_WIDTH, TAG_HEIGHT)
		tagGui.MaxDistance = TAG_MAX_DISTANCE
		tagGui.Parent = part
		local label = UiKit.label({
			parent = tagGui,
			name = "Label",
			text = "",
			size = UDim2.fromScale(1, 1),
			position = UDim2.fromScale(0, 0),
			heading = true,
			textSize = TAG_TEXT_SIZE,
		})
		-- The outline is the answer a player sees from across the map: red, green or white round the ball itself.
		local outline = Instance.new("Highlight")
		outline.Name = "RivalOutline"
		outline.Adornee = part
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.FillTransparency = 1
		outline.OutlineTransparency = 0
		outline.Enabled = false
		outline.Parent = part
		local tag: Tag = {
			gui = tagGui,
			label = label,
			part = part,
			linked = nil,
			outline = outline,
			noteUntil = 0,
		}
		refreshOffset(tag)
		tag.linked = part:GetAttributeChangedSignal("Diameter"):Connect(function()
			refreshOffset(tag)
		end)
		tags[part] = tag
	end

	local function removeTag(part: BasePart)
		local tag = tags[part]
		if tag == nil then
			return
		end
		if tag.linked then
			tag.linked:Disconnect()
		end
		tag.gui:Destroy()
		tag.outline:Destroy()
		tags[part] = nil
	end

	local function refreshTags(list: { Ball }, now: number)
		local mine = ownDiameter(list)
		local open = feastOpen(now)
		local leader = list[1]
		for part, tag in tags do
			local theirs = diameterOf(part)
			local kind = relation(theirs, mine, open)
			local colour = RELATION_COLOUR[kind]
			tag.outline.Enabled = kind ~= "none"
			tag.outline.OutlineColor = colour
			tag.outline.FillColor = colour
			tag.outline.FillTransparency = if kind == "even" then 1 else OUTLINE_FILL
			if now < tag.noteUntil then
				tag.label.Text = Localizer.t("ui.rival.too_big")
				tag.label.TextSize = NOTE_TEXT_SIZE
				tag.label.TextColor3 = WHITE
				continue
			end
			-- An even match shows the size the bigger of the two must reach to bite the other.
			local line = if kind == "even"
				then Localizer.t("ui.rival.need", {
					name = nameOf(part),
					size = formatSize(theirs),
					need = formatSize(
						math.ceil(math.min(theirs, mine) / Config.feastEatRatio * 10) / 10
					),
				})
				else Localizer.t("ui.rival.tag", {
					name = nameOf(part),
					size = formatSize(theirs),
				})
			if leader ~= nil and leader.part == part then
				line = CROWN .. " " .. line
			end
			tag.label.Text = line
			tag.label.TextSize = TAG_TEXT_SIZE
			tag.label.TextColor3 = colour
		end
	end

	-- A failed bite says so: touching an even match bounces the local ball off it and the tag reads "Too big!".
	-- The client owns its ball, so the bounce is applied here.
	local bounceAt = 0
	local function checkEvenTouch(now: number)
		if now < bounceAt or not feastOpen(now) then
			return
		end
		local own = ballsFolder:FindFirstChild(ownName)
		if own == nil or not own:IsA("BasePart") then
			return
		end
		local mine = diameterOf(own)
		for part, tag in tags do
			local theirs = diameterOf(part)
			if relation(theirs, mine, true) ~= "even" then
				continue
			end
			local offset = own.Position - part.Position
			local reach = own.Size.X / 2 + part.Size.X / 2 + Config.feastEvenContactMargin
			if offset.Magnitude > reach then
				continue
			end
			bounceAt = now + Config.feastEvenCooldown
			tag.noteUntil = now + Config.feastEvenNoteSeconds
			local away = Vector3.new(offset.X, 0, offset.Z)
			local direction = if away.Magnitude > 1e-3 then away.Unit else Vector3.xAxis
			own.AssemblyLinearVelocity = direction * Config.feastEvenBounceSpeed
				+ Vector3.new(0, Config.feastEvenBounceUp, 0)
			return
		end
	end

	-- Leaderboard, left edge. The last row shows the player's own rank when they are below the visible rows.
	local boardRows: { TextLabel } = {}
	for index = 1, Config.leaderboardRows do
		boardRows[index] = UiKit.label({
			parent = hud,
			name = `Rank{index}`,
			text = "",
			size = UDim2.fromOffset(ROW_WIDTH, ROW_HEIGHT),
			position = UDim2.fromOffset(BOARD_LEFT, BOARD_TOP + (index - 1) * ROW_HEIGHT),
			xAlign = Enum.TextXAlignment.Left,
		})
	end

	local function refreshBoard(list: { Ball })
		local lastRow = #boardRows
		local selfRank: number? = nil
		for index, ball in list do
			if ball.userId == localId then
				selfRank = index
			end
		end
		for index, row in boardRows do
			local rank = index
			if selfRank ~= nil and selfRank > lastRow and index == lastRow then
				rank = selfRank
			end
			local ball = list[rank]
			if ball == nil then
				row.Visible = false
				continue
			end
			row.Visible = true
			row.Text = Localizer.t("ui.rival.row", {
				rank = rank,
				name = ball.name,
				size = formatSize(ball.diameter),
			})
			row.TextColor3 = if ball.userId == localId then GOLD else WHITE
		end
	end

	-- Mode banner under the star row: Classic, Feast countdown, Feast open, or the shower event.
	local modeBanner = UiKit.label({
		parent = hud,
		name = "ModeBanner",
		text = "",
		size = UDim2.fromOffset(BANNER_WIDTH, BANNER_HEIGHT),
		position = UDim2.new(0.5, 0, 0, BANNER_TOP),
		anchor = Vector2.new(0.5, 0),
		textSize = BANNER_TEXT_SIZE,
		heading = true,
	})

	local function refreshBanner(now: number)
		local showerEnds = Workspace:GetAttribute("ShowerEndsAt")
		local eventKey = Workspace:GetAttribute("EventKey")
		local eventUntil = Workspace:GetAttribute("EventUntil")
		if typeof(eventKey) == "string" and typeof(eventUntil) == "number" and now < eventUntil then
			modeBanner.Text = Localizer.t(eventKey)
			modeBanner.TextColor3 = GOLD
		elseif typeof(showerEnds) == "number" and now < showerEnds then
			modeBanner.Text = Localizer.t("ui.event.shower")
			modeBanner.TextColor3 = ORANGE
		elseif Workspace:GetAttribute("RoundMode") ~= "Feast" then
			modeBanner.Text = Localizer.t("ui.mode.classic")
			modeBanner.TextColor3 = WHITE
		elseif feastOpen(now) then
			modeBanner.Text = Localizer.t("ui.mode.feast_open")
			modeBanner.TextColor3 = RED
		else
			local seconds = math.max(0, math.ceil(feastOpensAt() - now))
			modeBanner.Text = Localizer.t("ui.mode.feast_soon", { seconds = seconds })
			modeBanner.TextColor3 = WHITE
		end
	end

	-- Feast feed: one line for every eat, plus a splat or a chomp when the local player is involved.
	local feedLabel = UiKit.label({
		parent = hud,
		name = "FeastFeed",
		text = "",
		size = UDim2.fromOffset(FEED_WIDTH, FEED_HEIGHT),
		position = UDim2.new(0.5, 0, 0, FEED_TOP),
		anchor = Vector2.new(0.5, 0),
	})
	feedLabel.Visible = false
	local splatLabel = UiKit.label({
		parent = hud,
		name = "Splat",
		text = "",
		size = UDim2.fromOffset(BIG_WIDTH, BIG_HEIGHT),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		textSize = SPLAT_TEXT_SIZE,
		heading = true,
	})
	splatLabel.TextColor3 = RED
	splatLabel.Visible = false
	local chompLabel = UiKit.label({
		parent = hud,
		name = "Chomp",
		text = "",
		size = UDim2.fromOffset(BIG_WIDTH, BIG_HEIGHT),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		textSize = CHOMP_TEXT_SIZE,
		heading = true,
	})
	chompLabel.TextColor3 = GREEN
	chompLabel.Visible = false

	-- Shows a label for `seconds`, then fades it (or just hides it under ReduceMotion). A newer call replaces it.
	local tokens: { [TextLabel]: number } = {}
	local running: { [TextLabel]: { Tween } } = {}
	local function flash(label: TextLabel, text: string, seconds: number)
		local token = (tokens[label] or 0) + 1
		tokens[label] = token
		local previous = running[label]
		if previous then
			for _, tween in previous do
				tween:Cancel()
			end
		end
		local tweens: { Tween } = {}
		running[label] = tweens

		label.Text = text
		label.TextTransparency = 0
		label.Visible = true
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
		if not reduceMotion() then
			local info = TweenInfo.new(seconds)
			local fade = TweenService:Create(label, info, { TextTransparency = 1 })
			table.insert(tweens, fade)
			fade:Play()
			if stroke then
				local strokeFade = TweenService:Create(stroke, info, { Transparency = 1 })
				table.insert(tweens, strokeFade)
				strokeFade:Play()
			end
		end
		task.delay(seconds, function()
			if tokens[label] == token then
				label.Visible = false
			end
		end)
	end

	local feastEvent =
		ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FeastEvent") :: RemoteEvent
	feastEvent.OnClientEvent:Connect(
		function(eaterId: any, victimId: any, eaterName: any, victimName: any)
			if
				typeof(eaterId) ~= "number"
				or typeof(victimId) ~= "number"
				or typeof(eaterName) ~= "string"
				or typeof(victimName) ~= "string"
			then
				return
			end
			flash(
				feedLabel,
				Localizer.t("ui.feast.feed", { eater = eaterName, victim = victimName }),
				FEED_SECONDS
			)
			if victimId == localId then
				flash(splatLabel, Localizer.t("ui.feast.splat"), SPLAT_SECONDS)
			end
			if eaterId == localId then
				flash(chompLabel, Localizer.t("ui.feast.chomp"), CHOMP_SECONDS)
			end
		end
	)

	-- Panels B, C and D are only for an active run; the name tags stay visible.
	local function refreshVisible()
		hud.Visible = RunClient.state() == "Active"
	end
	RunClient.stateChanged:Connect(refreshVisible)
	refreshVisible()

	ballsFolder.ChildAdded:Connect(function(child: Instance)
		if child:IsA("BasePart") then
			addTag(child :: BasePart)
		end
	end)
	ballsFolder.ChildRemoved:Connect(function(child: Instance)
		if child:IsA("BasePart") then
			removeTag(child :: BasePart)
		end
	end)
	for _, child in ballsFolder:GetChildren() do
		if child:IsA("BasePart") then
			addTag(child :: BasePart)
		end
	end

	-- One Heartbeat drives every periodic refresh: tags 5 times a second, the banner 4 times and the board 2.
	local tagClock, boardClock, bannerClock = 0, 0, 0
	RunService.Heartbeat:Connect(function(dt: number)
		tagClock += dt
		boardClock += dt
		bannerClock += dt
		local now = Workspace:GetServerTimeNow()
		checkEvenTouch(now)
		if tagClock >= TAG_SECONDS then
			tagClock = 0
			refreshTags(sortedBalls(), now)
		end
		if RunClient.state() ~= "Active" then
			return
		end
		if boardClock >= BOARD_SECONDS then
			boardClock = 0
			refreshBoard(sortedBalls())
		end
		if bannerClock >= BANNER_SECONDS then
			bannerClock = 0
			refreshBanner(now)
		end
	end)
end

return RivalUi
