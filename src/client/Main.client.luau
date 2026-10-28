--!strict
-- Starts the client controllers. Each one waits for its own server-created instances.

local CameraController = require(script.Parent.CameraController)
local StuckVisuals = require(script.Parent.StuckVisuals)
local WorldCuller = require(script.Parent.WorldCuller)
local BallController = require(script.Parent.BallController)
local RunClient = require(script.Parent.RunClient)
local Hud = require(script.Parent.Hud)
local ResultsUi = require(script.Parent.ResultsUi)
local HubUi = require(script.Parent.HubUi)
local Feedback = require(script.Parent.Feedback)
local FpsReadout = require(script.Parent.FpsReadout)

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

CameraController.start()
StuckVisuals.start()
WorldCuller.start()
BallController.start()
RunClient.start()
Hud.start()
ResultsUi.start()
HubUi.start()
Feedback.start()
FpsReadout.start()

if Config.Flags.Saving then
	local ProfileClient = require(script.Parent.ProfileClient)
	local TopBar = require(script.Parent.TopBar)
	ProfileClient.start()
	TopBar.start()
	local BookUi = require(script.Parent.BookUi)
	BookUi.start()
	TopBar.bind("book", BookUi.toggle)
	local SettingsUi = require(script.Parent.SettingsUi)
	SettingsUi.start()
	TopBar.bind("settings", SettingsUi.toggle)
	-- One panel at a time; the Book also closes when a new run starts, Settings stays open.
	BookUi.onOpen(SettingsUi.close)
	SettingsUi.onOpen(BookUi.close)
	TopBar.onRunStart(BookUi.close)
end
