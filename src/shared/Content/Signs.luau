--!strict
-- Shop-front sign slots and billboard slots for the Main-Street slice (010, contracts/signs-and-billboards.md).
-- Data only: no Roblox APIs and no requires. Shop names are invented proper nouns (no real brands, no text that needs
-- localising). Yaw is degrees; a plate with yaw 90 faces -x, 270 faces +x, 0 faces -z (the same convention as props).
--
-- Facade ids and positions come from Content/Worlds/MainStreetSlice.luau: 7 facades per side, each 24 studs of
-- frontage, building face at |x| = 31.6 (behind a 10-stud forecourt). Right-hand side (x > 0) is `r`, left-hand side
-- (x < 0) is `l`. Changing a name, a region or a billboard image is a data edit here and nothing else.

export type SignSlot = {
	id: string,
	facadeId: string,
	shopName: string,
	atlasRegion: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
}
export type BillboardSlot = {
	id: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	imageAsset: string,
	sponsored: boolean,
}

-- Cells of the one shared facade/sign atlas (Assets.facadeAtlas), and the flat plate colour used while its id is "".
local regions: { string } = {
	"bakery",
	"cafe",
	"books",
	"bikes",
	"florist",
	"toys",
	"hardware",
	"music",
}
local regionSwatch: { [string]: string } = {
	bakery = "w-accent-orange",
	cafe = "w-accent-teal",
	books = "w-accent-blue",
	bikes = "w-accent-red",
	florist = "w-accent-pink",
	toys = "w-accent-yellow",
	hardware = "w-metal-dark",
	music = "w-wall-c",
}
-- Flat plate colour of each billboard image key while Assets.billboards holds "".
local imageSwatch: { [string]: string } = {
	b1 = "w-accent-red",
	b2 = "w-accent-blue",
	b3 = "w-accent-yellow",
	b4 = "w-accent-pink",
	b5 = "w-accent-teal",
	b6 = "w-accent-orange",
}

local FACE_X = 31.45 -- just in front of the building face at 31.6
local SIGN_Y = 10

local function sign(
	side: string,
	index: number,
	z: number,
	shopName: string,
	atlasRegion: string
): SignSlot
	local right = side == "r"
	return {
		id = `sign_{side}_{index}`,
		facadeId = `ms_fac_{side}_{index}`,
		shopName = shopName,
		atlasRegion = atlasRegion,
		x = if right then FACE_X else -FACE_X,
		y = SIGN_Y,
		z = z,
		yaw = if right then 90 else 270,
	}
end

-- Facade centres along z, in order: -48, -24 | 36, 60, 84 | 134, 158 (the gaps at z = 10 and 110 are cross streets).
local signSlots: { SignSlot } = {
	sign("r", 1, -48, "Marlow's Bakery", "bakery"),
	sign("r", 2, -24, "Tilly's Tea Room", "cafe"),
	sign("r", 3, 36, "Quill & Ink Books", "books"),
	sign("r", 4, 60, "Brightside Bikes", "bikes"),
	sign("r", 5, 84, "Fernwood Flowers", "florist"),
	sign("r", 6, 134, "Nook Toy Shop", "toys"),
	sign("r", 7, 158, "Nuts & Bolts Hardware", "hardware"),
	sign("l", 1, -48, "The Daily Bun", "bakery"),
	sign("l", 2, -24, "Copper Kettle Cafe", "cafe"),
	sign("l", 3, 36, "Maple Music", "music"),
	sign("l", 4, 60, "Pedal & Spoke", "bikes"),
	sign("l", 5, 84, "Petal Pot Florist", "florist"),
	sign("l", 6, 134, "Button & Bear Toys", "toys"),
	sign("l", 7, 158, "Lantern Hardware", "hardware"),
}

-- Six billboard textures at most (Config.billboardTextureCap). Four stand on the side towers of the main street (face
-- at |x| = 82, looking at the street), two on the backdrop towers at the end of it (face at z = 241, looking back).
local function board(
	id: string,
	x: number,
	y: number,
	z: number,
	yaw: number,
	imageAsset: string
): BillboardSlot
	return { id = id, x = x, y = y, z = z, yaw = yaw, imageAsset = imageAsset, sponsored = false }
end

local billboards: { BillboardSlot } = {
	board("bb_1", 81.85, 40, 45, 90, "b1"),
	board("bb_2", -81.85, 40, 75, 270, "b2"),
	board("bb_3", 81.85, 40, 135, 90, "b3"),
	board("bb_4", -81.85, 40, -30, 270, "b4"),
	board("bb_5", -30, 45, 240.85, 0, "b5"),
	board("bb_6", 30, 45, 240.85, 0, "b6"),
}

return {
	regions = regions,
	regionSwatch = regionSwatch,
	imageSwatch = imageSwatch,
	signSlots = signSlots,
	billboards = billboards,
}
