--!strict
-- Icon id to glyph. Data only: placeholder glyphs until real icon assets exist.

local Icons: { [string]: string } = {
	star = "★",
	star_empty = "☆",
	clock = "⏱",
	coin = "●",
	cube = "■",
	arrow = "▲",
	book = "▤",
	-- "↻" has no glyph in FredokaOne or GothamMedium; the emoji renders in both.
	retry = "🔁",
	home = "⌂",
	play = "▶",
	-- Feature 003 (contracts/content-and-config.md §Icons); glyph checks happen in a Studio capture.
	gear = "⚙",
	shop = "🛒",
	lock = "🔒",
	unknown = "❓",
	prev = "◀",
	next = "▶",
	-- "✕" is blank in FredokaOne and a box in GothamMedium; "✔" renders dark grey on the dark panels.
	close = "❌",
	check = "✅",
}

return Icons
