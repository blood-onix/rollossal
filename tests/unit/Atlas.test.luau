--!strict
-- Offline checks for the generated atlases (specs/005-theme-art-pipeline/contracts/art-pipeline.md §2).
-- The generator itself is stdlib Python (art/scripts/palette.py); scripts/check.sh reruns it with --check.
-- This suite checks the committed artefacts structurally: six 1,024 x 1,024 PNGs and the pixel-hash
-- manifest that pins their determinism.

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local harness = require("./harness")

local test, expect = harness.test, harness.expect

local THEME_IDS = { "city", "winter", "spring", "autumn", "toon", "neon" }

local function artPath(relative: string): string
	return "art/" .. relative
end

test("Atlas: all six theme PNGs exist, are 1024x1024 8-bit RGB and non-empty", function()
	for _, id in THEME_IDS do
		local path = artPath(`atlases/{id}.png`)
		expect.truthy(fs.isFile(path), `{path} missing (run python3 art/scripts/palette.py)`)
		local blob = fs.readFile(path)
		expect.truthy(#blob > 44, `{path} is not a PNG`)
		expect.equal(string.sub(blob, 1, 8), "\137PNG\r\n\26\n", `{path}: not a PNG signature`)
		-- IHDR: length 13 at offset 8, kind "IHDR", then width (bytes 16..19) and height (20..23).
		expect.equal(string.sub(blob, 13, 16), "IHDR", `{path}: no IHDR at offset 12`)
		local width = string.unpack(">I4", blob, 17)
		local height = string.unpack(">I4", blob, 21)
		expect.equal(width, 1024, `{path}: width`)
		expect.equal(height, 1024, `{path}: height`)
		local bitDepth, colourType = string.unpack("BB", blob, 25)
		expect.equal(bitDepth, 8, `{path}: bit depth`)
		expect.equal(colourType, 2, `{path}: colour type (RGB, no alpha or PBR transparency)`)
	end
end)

test("Atlas: atlas.json lists exactly the six themes with a 256-bit pixel hash", function()
	local manifest = serde.decode("json", fs.readFile(artPath("atlases/atlas.json")))
	expect.equal(manifest.version, 2)
	expect.equal(manifest.size, 1024)
	local ids = {}
	for id in manifest.themes do
		table.insert(ids, id)
	end
	local sorted = table.clone(THEME_IDS)
	table.sort(ids)
	table.sort(sorted)
	expect.same(ids, sorted)
	for _, id in THEME_IDS do
		local hash = manifest.themes[id].pixelSha256
		expect.truthy(type(hash) == "string" and #hash == 64, `{id}: 64-hex pixelSha256`)
		expect.truthy((string.match(hash, "^%x+$")), `{id}: hash is hex`)
		-- Two different themes must not share a pixel image.
		for _, other in THEME_IDS do
			if other ~= id then
				expect.falsy(
					manifest.themes[other].pixelSha256 == hash,
					`{id} and {other} share pixels`
				)
			end
		end
	end
end)

test("Atlas: art/palette.png is a byte copy of the winter atlas (the launch theme)", function()
	local winter = fs.readFile(artPath("atlases/winter.png"))
	local palette = fs.readFile(artPath("palette.png"))
	expect.equal(#palette, #winter)
	expect.truthy(palette == winter)
end)
