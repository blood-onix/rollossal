--!strict
-- The Config values Rules/Jump needs, as one table. Rules take their numbers as arguments (purity), so the
-- server guard and the client jump build the same table from here.

local Config = require(script.Parent.Config)
local Jump = require(script.Parent.Rules.Jump)

local tuning: Jump.JumpTuning = table.freeze({
	clearRatio = Config.jumpClearRatio,
	holdClearRatio = Config.jumpHoldClearRatio,
	minClear = Config.minJumpClearHeight,
	holdMaxSeconds = Config.jumpHoldMaxSeconds,
	verticalSlack = Config.verticalSlack,
	airEnergyAllowance = Config.airEnergyAllowance,
	maxSlopeRatio = Config.maxSlopeRatio,
})

return tuning
