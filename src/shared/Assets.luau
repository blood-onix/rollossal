--!strict
-- The only file that may hold a SoundId or a mesh or texture id (Constitution XI).
-- Sounds are engine-bundled placeholders, except the looping music track. Contract: specs/002-run-loop/contracts/content-and-config.md
-- Meshes and the shared palette texture: specs/004-snow-village/contracts/world-content.md. An empty string
-- means "not imported yet", and the world falls back to a plain stand-in part.

local Assets = {
	sounds = {
		pickup = "rbxasset://sounds/electronicpingshort.wav",
		tierUnlock = "rbxasset://sounds/button.wav",
		bump = "rbxasset://sounds/snap.mp3",
		bell = "rbxasset://sounds/bass.wav",
		-- The looping theme music (musicWinter used to be named music). "" means no track is picked:
		-- nothing plays, rather than a placeholder that would be annoying on a loop. Winter and city
		-- each have their own track; the other themes have none yet and stay silent instead of
		-- reusing one.
		musicWinter = "rbxassetid://114423108310478",
		musicCity = "rbxassetid://80565841497538",
		musicSpring = "",
		musicAutumn = "",
		musicToon = "",
		musicNeon = "",
	} :: { [string]: string },
	-- Which texture generation the currently uploaded meshes carry: the old 256 px shared palette
	-- ("legacy") or the per-theme atlases ("atlas").
	renderingMode = "atlas",
	-- Fallback texture ID for when meshes are missing UVs (replaces Assets.palette).
	meshUv = "rbxassetid://95185035371248",
	-- Content ids for the six season atlases (005), "" until the owner uploads them. A theme's
	-- paletteAssetKey equals its id.
	palettes = {
		city = "rbxassetid://135771669927883",
		winter = "rbxassetid://80845524655584",
		spring = "rbxassetid://130785517655515",
		autumn = "rbxassetid://77294706934568",
		toon = "rbxassetid://119324797322203",
		neon = "rbxassetid://88161628123428",
	} :: { [string]: string },
	-- One key per ObjectDef.assetKey, plus the hub.
	meshes = {
		gumdrop = "rbxassetid://119269604885219",
		button = "rbxassetid://114503105730496",
		jingle_bell = "rbxassetid://121209806872852",
		acorn = "rbxassetid://91692677080538",
		marshmallow = "rbxassetid://135692787137252",
		peppermint = "rbxassetid://86168197298182",
		pine_cone = "rbxassetid://133938212588427",
		bauble = "rbxassetid://122325794308962",
		cookie = "rbxassetid://106870230011749",
		ribbon_bow = "rbxassetid://111680255406845",
		mini_snow_globe = "rbxassetid://115977026405669",
		wooden_star = "rbxassetid://129104487756023",
		candy_cane = "rbxassetid://113743572275913",
		sock_ornament = "rbxassetid://107078625236403",
		gingerbread_man = "rbxassetid://126921805955255",
		matchbox_car = "rbxassetid://113281536482802",
		toy_soldier = "rbxassetid://102093384402679",
		cocoa_mug = "rbxassetid://131974007319581",
		rubber_duck = "rbxassetid://89470067989017",
		mitten_pair = "rbxassetid://138290742806354",
		gift_box = "rbxassetid://100121757374364",
		block_stack = "rbxassetid://80254582473573",
		snowball = "rbxassetid://73680659520258",
		toy_drum = "rbxassetid://140092193841459",
		snow_boot = "rbxassetid://117089032513912",
		teddy_bear = "rbxassetid://130164728050675",
		plush_penguin = "rbxassetid://114865656409948",
		tin_robot = "rbxassetid://109025699607735",
		lantern = "rbxassetid://130417490003713",
		cat = "rbxassetid://77587031888817",
		wreath = "rbxassetid://85778168806399",
		flower_pot = "rbxassetid://79050075933750",
		toy_sled = "rbxassetid://94165408727585",
		rocking_horse = "rbxassetid://83856999033693",
		barrel = "rbxassetid://94322514288886",
		mailbox = "rbxassetid://125946906000262",
		giant_gift = "rbxassetid://135409726259182",
		snow_mound = "rbxassetid://135238165076433",
		dog = "rbxassetid://112537511796409",
		fence_section = "rbxassetid://117218480017668",
		firewood_stack = "rbxassetid://139807571927621",
		sledge = "rbxassetid://107596323435241",
		bicycle = "rbxassetid://76775704007205",
		bench = "rbxassetid://133375493072127",
		snowman = "rbxassetid://117434083288276",
		cocoa_cart = "rbxassetid://99304234087941",
		pine_sapling = "rbxassetid://98918352107244",
		street_lamp = "rbxassetid://127223089770183",
		bus_shelter = "rbxassetid://131037771399182",
		market_stall = "rbxassetid://132143492102273",
		big_snowman = "rbxassetid://84384488018027",
		kiosk = "rbxassetid://97033267990342",
		fountain = "rbxassetid://92086426970658",
		car = "rbxassetid://123252961931482",
		sleigh = "rbxassetid://120724086758419",
		van = "rbxassetid://121677590470873",
		bandstand = "rbxassetid://92801184909052",
		christmas_tree = "rbxassetid://91417987670585",
		snowplough = "rbxassetid://88985030812018",
		bus = "rbxassetid://93015715421626",
		cottage = "rbxassetid://125869138435407",
		town_house = "rbxassetid://115601999152051",
		skating_rink = "rbxassetid://122621796492671",
		clock_tower = "rbxassetid://81833436229658",
		hub = "rbxassetid://116134471627481",
	} :: { [string]: string },
}

return Assets
