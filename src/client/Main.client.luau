--!strict
-- Starts the client controllers. Each one waits for its own server-created instances.

local CameraController = require(script.Parent.CameraController)
local StuckVisuals = require(script.Parent.StuckVisuals)
local BallController = require(script.Parent.BallController)
local RunClient = require(script.Parent.RunClient)
local Hud = require(script.Parent.Hud)
local ResultsUi = require(script.Parent.ResultsUi)
local HubUi = require(script.Parent.HubUi)
local Feedback = require(script.Parent.Feedback)

CameraController.start()
StuckVisuals.start()
BallController.start()
RunClient.start()
Hud.start()
ResultsUi.start()
HubUi.start()
Feedback.start()
