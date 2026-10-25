--!strict
-- Icon id to glyph. Data only: placeholder glyphs until real icon assets exist (research R9).

local Icons: { [string]: string } = {
	star = "★",
	star_empty = "☆",
	clock = "⏱",
	coin = "●",
	cube = "■",
	arrow = "▲",
	book = "▤",
	-- "↻" has no glyph in FredokaOne or GothamMedium (T038 capture); the emoji renders in both.
	retry = "🔁",
	home = "⌂",
	play = "▶",
}

return Icons
