--!strict
-- Starts the client controllers. Each one waits for its own server-created instances.

local CameraController = require(script.Parent.CameraController)
local StuckVisuals = require(script.Parent.StuckVisuals)
local BallController = require(script.Parent.BallController)

CameraController.start()
StuckVisuals.start()
BallController.start()
