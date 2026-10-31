--!strict
-- Booster and trap rows (006, contracts/content-and-config.md). Data only: no requires, no Roblox APIs.
-- Each row carries a footprint in studs and per-theme dressing (a palette role, a Strings key, an Icons key).
-- Colour roles are playtest-adjustable data. Nothing here is sold: no price or product field.

export type Dressing = { colourRole: string, nameKey: string, iconKey: string }
export type BoosterDef = {
	subKind: string,
	flag: string,
	consumable: boolean,
	durationKey: string?,
	footprint: { w: number, d: number },
	dressing: { [string]: Dressing },
}
export type TrapDef = {
	subKind: string,
	flag: string,
	surface: boolean,
	knocks: boolean,
	footprint: { w: number, d: number },
	dressing: { [string]: Dressing },
}

local function same(role: string, nameKey: string, iconKey: string): { [string]: Dressing }
	local dressing: Dressing = { colourRole = role, nameKey = nameKey, iconKey = iconKey }
	return { winter = dressing, city = dressing }
end

local boosters: { BoosterDef } = {
	{
		subKind = "dash",
		flag = "BoosterDash",
		consumable = true,
		durationKey = "dashDuration",
		footprint = { w = 5, d = 5 },
		dressing = same("w-accent-red", "world.booster.dash", "dash"),
	},
	{
		subKind = "magnet",
		flag = "BoosterMagnet",
		consumable = true,
		durationKey = "magnetDuration",
		footprint = { w = 5, d = 5 },
		dressing = same("w-metal", "world.booster.magnet", "magnet"),
	},
	{
		subKind = "spring",
		flag = "BoosterSpring",
		consumable = false,
		durationKey = nil,
		footprint = { w = 8, d = 8 },
		dressing = {
			winter = {
				colourRole = "w-season",
				nameKey = "world.booster.spring",
				iconKey = "spring",
			},
			city = { colourRole = "w-sand", nameKey = "world.booster.spring", iconKey = "spring" },
		},
	},
	{
		subKind = "shield",
		flag = "BoosterShield",
		consumable = true,
		durationKey = "shieldDuration",
		footprint = { w = 5, d = 5 },
		dressing = same("w-glow", "world.booster.shield", "shield"),
	},
	{
		subKind = "slick_trail",
		flag = "BoosterSlickTrail",
		consumable = true,
		durationKey = "slickTrailDuration",
		footprint = { w = 5, d = 5 },
		dressing = same("w-water", "world.booster.slick_trail", "slick"),
	},
}

local traps: { TrapDef } = {
	{
		subKind = "slick",
		flag = "TrapSlick",
		surface = true,
		knocks = false,
		footprint = { w = 14, d = 14 },
		dressing = {
			winter = {
				colourRole = "w-water",
				nameKey = "world.trap.slick.winter",
				iconKey = "slick",
			},
			city = { colourRole = "w-water", nameKey = "world.trap.slick.city", iconKey = "slick" },
		},
	},
	{
		subKind = "bumper",
		flag = "TrapBumper",
		surface = false,
		knocks = true,
		footprint = { w = 4, d = 4 },
		dressing = {
			winter = {
				colourRole = "w-season",
				nameKey = "world.trap.bumper.winter",
				iconKey = "bumper",
			},
			city = {
				colourRole = "w-accent-red",
				nameKey = "world.trap.bumper.city",
				iconKey = "bumper",
			},
		},
	},
	{
		subKind = "slow",
		flag = "TrapSlow",
		surface = true,
		knocks = false,
		footprint = { w = 14, d = 14 },
		dressing = {
			winter = {
				colourRole = "w-season",
				nameKey = "world.trap.slow.winter",
				iconKey = "slow",
			},
			city = { colourRole = "w-sand", nameKey = "world.trap.slow.city", iconKey = "slow" },
		},
	},
	{
		subKind = "sweeper",
		flag = "TrapSweeper",
		surface = false,
		knocks = true,
		footprint = { w = 10, d = 6 },
		dressing = {
			winter = {
				colourRole = "w-metal",
				nameKey = "world.trap.sweeper.winter",
				iconKey = "sweeper",
			},
			city = {
				colourRole = "w-metal",
				nameKey = "world.trap.sweeper.city",
				iconKey = "sweeper",
			},
		},
	},
}

return { boosters = boosters, traps = traps }
