class_name Catalog
## Static game data: furniture you can buy and wall / floor finishes.

const FURNITURE_DIR := "res://assets/models/furniture/%s.glb"
const NATURE_DIR := "res://assets/models/nature/%s.glb"
const THUMB_DIR := "res://assets/thumbs/%s.png"

## Shop categories, in tab order.
const SHOP_TABS := [
	["living", "Living"],
	["bedroom", "Bedroom"],
	["kitchen", "Kitchen"],
	["bathroom", "Bathroom"],
	["decor", "Decor"],
	["garden", "Garden"],
]

## Every buyable item.
## place: "floor" sits on any upward surface, "wall" hangs on walls.
## cat: what job tasks check for. tab: which shop tab lists it.
const ITEMS := {
	# Living room
	"sofa": {"name": "Sofa", "model": "loungeSofa", "price": 320, "cat": "sofa", "tab": "living"},
	"sofa_long":
	{"name": "Long Sofa", "model": "loungeSofaLong", "price": 420, "cat": "sofa", "tab": "living"},
	"sofa_corner":
	{
		"name": "Corner Sofa",
		"model": "loungeSofaCorner",
		"price": 480,
		"cat": "sofa",
		"tab": "living"
	},
	"sofa_design":
	{
		"name": "Design Sofa",
		"model": "loungeDesignSofa",
		"price": 520,
		"cat": "sofa",
		"tab": "living"
	},
	"ottoman":
	{"name": "Ottoman", "model": "loungeSofaOttoman", "price": 90, "cat": "seat", "tab": "living"},
	"armchair":
	{"name": "Armchair", "model": "loungeChair", "price": 180, "cat": "seat", "tab": "living"},
	"armchair_relax":
	{"name": "Recliner", "model": "loungeChairRelax", "price": 240, "cat": "seat", "tab": "living"},
	"coffee_table":
	{
		"name": "Coffee Table",
		"model": "tableCoffee",
		"price": 110,
		"cat": "coffee_table",
		"tab": "living"
	},
	"coffee_glass":
	{
		"name": "Glass Coffee Table",
		"model": "tableCoffeeGlass",
		"price": 150,
		"cat": "coffee_table",
		"tab": "living"
	},
	"coffee_square":
	{
		"name": "Square Coffee Table",
		"model": "tableCoffeeSquare",
		"price": 90,
		"cat": "coffee_table",
		"tab": "living"
	},
	"tv_modern":
	{"name": "Flat TV", "model": "televisionModern", "price": 400, "cat": "tv", "tab": "living"},
	"tv_vintage":
	{"name": "Retro TV", "model": "televisionVintage", "price": 140, "cat": "tv", "tab": "living"},
	"tv_cabinet":
	{
		"name": "TV Cabinet",
		"model": "cabinetTelevision",
		"price": 160,
		"cat": "cabinet",
		"tab": "living"
	},
	"bookcase":
	{"name": "Bookcase", "model": "bookcaseOpen", "price": 150, "cat": "storage", "tab": "living"},
	"bookcase_wide":
	{
		"name": "Wide Bookcase",
		"model": "bookcaseClosedWide",
		"price": 210,
		"cat": "storage",
		"tab": "living"
	},
	"speaker":
	{"name": "Speaker", "model": "speaker", "price": 120, "cat": "decor", "tab": "living"},
	"bed_double":
	{"name": "Double Bed", "model": "bedDouble", "price": 450, "cat": "bed", "tab": "bedroom"},
	# Bedroom
	"bed_single":
	{"name": "Single Bed", "model": "bedSingle", "price": 260, "cat": "bed", "tab": "bedroom"},
	"nightstand":
	{
		"name": "Nightstand",
		"model": "cabinetBed",
		"price": 70,
		"cat": "nightstand",
		"tab": "bedroom"
	},
	"dresser":
	{
		"name": "Dresser",
		"model": "sideTableDrawers",
		"price": 180,
		"cat": "storage",
		"tab": "bedroom"
	},
	"desk": {"name": "Desk", "model": "desk", "price": 190, "cat": "desk", "tab": "bedroom"},
	"desk_chair":
	{"name": "Desk Chair", "model": "chairDesk", "price": 110, "cat": "chair", "tab": "bedroom"},
	"coat_rack":
	{
		"name": "Coat Rack",
		"model": "coatRackStanding",
		"price": 45,
		"cat": "decor",
		"tab": "bedroom"
	},
	"fridge":
	{"name": "Fridge", "model": "kitchenFridge", "price": 380, "cat": "fridge", "tab": "kitchen"},
	# Kitchen
	"fridge_large":
	{
		"name": "Large Fridge",
		"model": "kitchenFridgeLarge",
		"price": 560,
		"cat": "fridge",
		"tab": "kitchen"
	},
	"stove":
	{"name": "Stove", "model": "kitchenStove", "price": 300, "cat": "stove", "tab": "kitchen"},
	"kitchen_sink":
	{
		"name": "Kitchen Sink",
		"model": "kitchenSink",
		"price": 220,
		"cat": "kitchen_sink",
		"tab": "kitchen"
	},
	"kitchen_cabinet":
	{
		"name": "Counter",
		"model": "kitchenCabinet",
		"price": 120,
		"cat": "counter",
		"tab": "kitchen"
	},
	"kitchen_drawer":
	{
		"name": "Drawer Counter",
		"model": "kitchenCabinetDrawer",
		"price": 140,
		"cat": "counter",
		"tab": "kitchen"
	},
	"kitchen_upper":
	{
		"name": "Wall Cabinet",
		"model": "kitchenCabinetUpper",
		"price": 90,
		"cat": "counter_upper",
		"tab": "kitchen",
		"place": "wall"
	},
	"kitchen_bar":
	{
		"name": "Kitchen Island",
		"model": "kitchenBar",
		"price": 200,
		"cat": "counter",
		"tab": "kitchen"
	},
	"dining_table":
	{
		"name": "Dining Table",
		"model": "table",
		"price": 210,
		"cat": "table",
		"tab": "kitchen",
		"scale": 2.2
	},
	"dining_round":
	{
		"name": "Round Table",
		"model": "tableRound",
		"price": 230,
		"cat": "table",
		"tab": "kitchen",
		"scale": 2.2
	},
	"dining_cloth":
	{
		"name": "Table with Cloth",
		"model": "tableCloth",
		"price": 240,
		"cat": "table",
		"tab": "kitchen",
		"scale": 2.2
	},
	"chair": {"name": "Chair", "model": "chair", "price": 60, "cat": "chair", "tab": "kitchen"},
	"chair_cushion":
	{
		"name": "Cushion Chair",
		"model": "chairCushion",
		"price": 80,
		"cat": "chair",
		"tab": "kitchen"
	},
	"chair_modern":
	{
		"name": "Modern Chair",
		"model": "chairModernCushion",
		"price": 95,
		"cat": "chair",
		"tab": "kitchen"
	},
	"microwave":
	{
		"name": "Microwave",
		"model": "kitchenMicrowave",
		"price": 90,
		"cat": "appliance",
		"tab": "kitchen"
	},
	"coffee_machine":
	{
		"name": "Coffee Machine",
		"model": "kitchenCoffeeMachine",
		"price": 120,
		"cat": "appliance",
		"tab": "kitchen"
	},
	"toaster":
	{"name": "Toaster", "model": "toaster", "price": 35, "cat": "appliance", "tab": "kitchen"},
	"blender":
	{
		"name": "Blender",
		"model": "kitchenBlender",
		"price": 45,
		"cat": "appliance",
		"tab": "kitchen"
	},
	"washer":
	{"name": "Washing Machine", "model": "washer", "price": 330, "cat": "washer", "tab": "kitchen"},
	"dryer": {"name": "Dryer", "model": "dryer", "price": 290, "cat": "dryer", "tab": "kitchen"},
	"toilet":
	{"name": "Toilet", "model": "toilet", "price": 150, "cat": "toilet", "tab": "bathroom"},
	# Bathroom
	"toilet_square":
	{
		"name": "Modern Toilet",
		"model": "toiletSquare",
		"price": 210,
		"cat": "toilet",
		"tab": "bathroom"
	},
	"sink":
	{"name": "Sink", "model": "bathroomSink", "price": 110, "cat": "sink", "tab": "bathroom"},
	"sink_square":
	{
		"name": "Vanity Sink",
		"model": "bathroomSinkSquare",
		"price": 190,
		"cat": "sink",
		"tab": "bathroom"
	},
	"shower":
	{"name": "Corner Shower", "model": "shower", "price": 360, "cat": "bath", "tab": "bathroom"},
	"shower_round":
	{
		"name": "Round Shower",
		"model": "showerRound",
		"price": 400,
		"cat": "bath",
		"tab": "bathroom"
	},
	"bathtub":
	{
		"name": "Bathtub",
		"model": "bathtub",
		"price": 420,
		"cat": "bath",
		"tab": "bathroom",
		"scale": 1.7
	},
	"mirror":
	{
		"name": "Mirror",
		"model": "bathroomMirror",
		"price": 60,
		"cat": "mirror",
		"tab": "bathroom",
		"place": "wall"
	},
	"bath_cabinet":
	{
		"name": "Bathroom Cabinet",
		"model": "bathroomCabinet",
		"price": 80,
		"cat": "bath_storage",
		"tab": "bathroom",
		"place": "wall"
	},
	"trashcan":
	{"name": "Trash Can", "model": "trashcan", "price": 25, "cat": "decor", "tab": "bathroom"},
	"lamp_floor":
	{"name": "Floor Lamp", "model": "lampRoundFloor", "price": 85, "cat": "lamp", "tab": "decor"},
	# Decor
	"lamp_floor_sq":
	{
		"name": "Square Floor Lamp",
		"model": "lampSquareFloor",
		"price": 95,
		"cat": "lamp",
		"tab": "decor"
	},
	"lamp_table":
	{"name": "Table Lamp", "model": "lampRoundTable", "price": 45, "cat": "lamp", "tab": "decor"},
	"lamp_wall":
	{
		"name": "Wall Lamp",
		"model": "lampWall",
		"price": 55,
		"cat": "lamp",
		"tab": "decor",
		"place": "wall"
	},
	"plant_potted":
	{"name": "Potted Plant", "model": "pottedPlant", "price": 40, "cat": "plant", "tab": "decor"},
	"plant_small1":
	{"name": "Small Plant", "model": "plantSmall1", "price": 15, "cat": "plant", "tab": "decor"},
	"plant_small2":
	{"name": "Succulent", "model": "plantSmall2", "price": 15, "cat": "plant", "tab": "decor"},
	"plant_small3":
	{"name": "Cactus", "model": "plantSmall3", "price": 18, "cat": "plant", "tab": "decor"},
	"rug_rect": {"name": "Rug", "model": "rugRectangle", "price": 75, "cat": "rug", "tab": "decor"},
	"rug_round":
	{"name": "Round Rug", "model": "rugRound", "price": 65, "cat": "rug", "tab": "decor"},
	"rug_rounded":
	{"name": "Soft Rug", "model": "rugRounded", "price": 80, "cat": "rug", "tab": "decor"},
	"rug_square":
	{"name": "Square Rug", "model": "rugSquare", "price": 60, "cat": "rug", "tab": "decor"},
	"doormat":
	{"name": "Doormat", "model": "rugDoormat", "price": 20, "cat": "rug", "tab": "decor"},
	"books": {"name": "Books", "model": "books", "price": 20, "cat": "decor", "tab": "decor"},
	"radio": {"name": "Radio", "model": "radio", "price": 50, "cat": "decor", "tab": "decor"},
	"laptop": {"name": "Laptop", "model": "laptop", "price": 300, "cat": "decor", "tab": "decor"},
	"computer":
	{"name": "Monitor", "model": "computerScreen", "price": 180, "cat": "decor", "tab": "decor"},
	"pillow": {"name": "Pillow", "model": "pillow", "price": 15, "cat": "decor", "tab": "decor"},
	"pillow_blue":
	{"name": "Blue Pillow", "model": "pillowBlue", "price": 15, "cat": "decor", "tab": "decor"},
	"teddy": {"name": "Teddy Bear", "model": "bear", "price": 25, "cat": "decor", "tab": "decor"},
	"side_table":
	{"name": "Side Table", "model": "sideTable", "price": 70, "cat": "table_small", "tab": "decor"},
	"flower_red":
	{
		# Garden
		"name": "Red Flowers",
		"model": "flower_redA",
		"price": 12,
		"cat": "flower",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.4
	},
	"flower_yellow":
	{
		"name": "Yellow Flowers",
		"model": "flower_yellowA",
		"price": 12,
		"cat": "flower",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.4
	},
	"flower_purple":
	{
		"name": "Purple Flowers",
		"model": "flower_purpleA",
		"price": 12,
		"cat": "flower",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.4
	},
	"flower_red_b":
	{
		"name": "Red Blossoms",
		"model": "flower_redB",
		"price": 14,
		"cat": "flower",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.4
	},
	"bush":
	{
		"name": "Bush",
		"model": "plant_bushDetailed",
		"price": 35,
		"cat": "bush",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.0
	},
	"bush_small":
	{
		"name": "Small Bush",
		"model": "plant_bush",
		"price": 25,
		"cat": "bush",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.5
	},
	"pot_large":
	{
		"name": "Planter",
		"model": "pot_large",
		"price": 40,
		"cat": "bush",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.0
	},
	"tree_small":
	{
		"name": "Young Tree",
		"model": "tree_small",
		"price": 90,
		"cat": "tree",
		"tab": "garden",
		"dir": "nature",
		"scale": 3.0
	},
	"tree_oak":
	{
		"name": "Oak Tree",
		"model": "tree_oak",
		"price": 160,
		"cat": "tree",
		"tab": "garden",
		"dir": "nature",
		"scale": 3.5
	},
	"tree_palm":
	{
		"name": "Palm Tree",
		"model": "tree_palmTall",
		"price": 200,
		"cat": "tree",
		"tab": "garden",
		"dir": "nature",
		"scale": 3.5
	},
	"garden_bench":
	{
		"name": "Garden Bench",
		"model": "bench",
		"price": 120,
		"cat": "outdoor_seat",
		"tab": "garden"
	},
	"lounger":
	{
		"name": "Sun Lounger",
		"model": "loungeChairRelax",
		"price": 150,
		"cat": "outdoor_seat",
		"tab": "garden"
	},
	"garden_table":
	{
		"name": "Garden Table",
		"model": "tableRound",
		"price": 170,
		"cat": "outdoor_table",
		"tab": "garden",
		"scale": 2.2
	},
	"garden_chair":
	{
		"name": "Garden Chair",
		"model": "chairRounded",
		"price": 55,
		"cat": "outdoor_seat",
		"tab": "garden"
	},
	"rock":
	{
		"name": "Rock",
		"model": "rock_smallA",
		"price": 10,
		"cat": "decor",
		"tab": "garden",
		"dir": "nature",
		"scale": 2.5
	},
}

## Models used for old junk furniture left in the house (not sold in the shop).
const JUNK := {
	"junk_sofa":
	{"name": "Old Sofa", "model": "loungeSofa", "value": 40, "tint": Color(0.45, 0.32, 0.5)},
	"junk_table":
	{
		"name": "Old Table",
		"model": "table",
		"value": 20,
		"scale": 2.2,
		"tint": Color(0.45, 0.25, 0.2)
	},
	"junk_chair":
	{"name": "Old Chair", "model": "chair", "value": 10, "tint": Color(0.35, 0.22, 0.18)},
	"junk_dresser":
	{
		"name": "Old Dresser",
		"model": "sideTableDrawers",
		"value": 25,
		"tint": Color(0.4, 0.22, 0.16)
	},
	"junk_bed":
	{"name": "Old Mattress", "model": "bedSingle", "value": 20, "tint": Color(0.6, 0.55, 0.45)},
	"junk_tv":
	{"name": "Broken TV", "model": "televisionVintage", "value": 15, "tint": Color(0.4, 0.4, 0.4)},
	"junk_fridge":
	{"name": "Rusty Fridge", "model": "kitchenFridge", "value": 30, "tint": Color(0.7, 0.62, 0.45)},
	"junk_toilet":
	{"name": "Cracked Toilet", "model": "toilet", "value": 15, "tint": Color(0.7, 0.66, 0.5)},
	"junk_washer":
	{"name": "Broken Washer", "model": "washer", "value": 25, "tint": Color(0.6, 0.58, 0.5)},
}

const OLD_TINT := Color(0.78, 0.72, 0.6)

## Wall finishes. tex: texture name in assets/textures, or color only for paint.
## m: how many metres one texture repeat covers.
const WALL := {
	"old_floral":
	{
		"name": "Old Floral",
		"tex": "wallpaper_floral",
		"tint": OLD_TINT,
		"m": 1.4,
		"cat": "old",
		"price": 0
	},
	"old_dots":
	{
		"name": "Old Dots",
		"tex": "wallpaper_dots",
		"tint": Color(0.75, 0.72, 0.58),
		"m": 1.4,
		"cat": "old",
		"price": 0
	},
	"old_green":
	{"name": "Old Green Paint", "color": Color(0.55, 0.58, 0.42), "cat": "old", "price": 0},
	"old_yellow":
	{"name": "Old Yellow Paint", "color": Color(0.74, 0.67, 0.44), "cat": "old", "price": 0},
	"paint_white":
	{"name": "Pure White", "color": Color(0.95, 0.94, 0.91), "cat": "paint", "price": 20},
	"paint_cream": {"name": "Cream", "color": Color(0.96, 0.9, 0.78), "cat": "paint", "price": 20},
	"paint_sage": {"name": "Sage", "color": Color(0.66, 0.74, 0.62), "cat": "paint", "price": 20},
	"paint_sky":
	{"name": "Sky Blue", "color": Color(0.62, 0.77, 0.86), "cat": "paint", "price": 20},
	"paint_blush": {"name": "Blush", "color": Color(0.91, 0.74, 0.71), "cat": "paint", "price": 20},
	"paint_mint": {"name": "Mint", "color": Color(0.7, 0.88, 0.8), "cat": "paint", "price": 20},
	"paint_mustard":
	{"name": "Mustard", "color": Color(0.87, 0.71, 0.33), "cat": "paint", "price": 20},
	"paint_navy": {"name": "Navy", "color": Color(0.2, 0.26, 0.38), "cat": "paint", "price": 25},
	"paint_charcoal":
	{"name": "Charcoal", "color": Color(0.3, 0.31, 0.34), "cat": "paint", "price": 25},
	"wp_floral":
	{
		"name": "Floral Wallpaper",
		"tex": "wallpaper_floral",
		"m": 1.4,
		"cat": "wallpaper",
		"price": 35
	},
	"wp_leaf":
	{"name": "Leaf Wallpaper", "tex": "wallpaper_leaf", "m": 1.4, "cat": "wallpaper", "price": 40},
	"wp_stripes":
	{
		"name": "Striped Wallpaper",
		"tex": "wallpaper_stripes",
		"m": 1.4,
		"cat": "wallpaper",
		"price": 35
	},
	"wp_dots":
	{"name": "Polka Wallpaper", "tex": "wallpaper_dots", "m": 1.4, "cat": "wallpaper", "price": 35},
	"wp_brick":
	{
		"name": "Brick Wallpaper",
		"tex": "wallpaper_brick",
		"m": 1.8,
		"cat": "wallpaper",
		"price": 45
	},
	"tiles_beige":
	{"name": "Beige Tiles", "tex": "wall_tiles_beige", "m": 1.6, "cat": "tiles", "price": 50},
	"tiles_white":
	{"name": "White Tiles", "tex": "wall_tiles_white", "m": 1.6, "cat": "tiles", "price": 45},
	"tiles_marble":
	{"name": "Marble", "tex": "floor_marble", "m": 2.0, "cat": "tiles", "price": 70},
}

const FLOOR := {
	"old_carpet":
	{
		"name": "Worn Carpet",
		"tex": "floor_carpet_old",
		"tint": Color(0.85, 0.8, 0.72),
		"m": 2.0,
		"cat": "old",
		"price": 0
	},
	"old_wood":
	{
		"name": "Scratched Wood",
		"tex": "floor_wood",
		"tint": Color(0.55, 0.48, 0.42),
		"m": 2.4,
		"cat": "old",
		"price": 0
	},
	"old_concrete":
	{
		"name": "Bare Concrete",
		"tex": "concrete",
		"tint": Color(0.62, 0.6, 0.56),
		"m": 3.0,
		"cat": "old",
		"price": 0
	},
	"old_checker":
	{
		"name": "Grimy Checker",
		"tex": "floor_checker",
		"tint": Color(0.72, 0.68, 0.55),
		"m": 2.4,
		"cat": "old",
		"price": 0
	},
	"wood_oak": {"name": "Oak Planks", "tex": "floor_wood", "m": 2.4, "cat": "wood", "price": 70},
	"wood_walnut":
	{
		"name": "Walnut Planks",
		"tex": "floor_wood",
		"tint": Color(0.68, 0.55, 0.47),
		"m": 2.4,
		"cat": "wood",
		"price": 80
	},
	"carpet_grey":
	{"name": "Grey Carpet", "tex": "floor_carpet_grey", "m": 2.0, "cat": "carpet", "price": 55},
	"carpet_beige":
	{
		"name": "Beige Carpet",
		"tex": "floor_carpet_grey",
		"tint": Color(1.25, 1.12, 0.92),
		"m": 2.0,
		"cat": "carpet",
		"price": 55
	},
	"tiles_beige":
	{"name": "Beige Tiles", "tex": "floor_tiles_beige", "m": 2.0, "cat": "tiles", "price": 65},
	"tiles_checker":
	{"name": "Checker Tiles", "tex": "floor_checker", "m": 2.4, "cat": "tiles", "price": 65},
	"tiles_marble":
	{"name": "Marble", "tex": "floor_marble", "m": 2.0, "cat": "tiles", "price": 95},
	"concrete":
	{"name": "Polished Concrete", "tex": "concrete", "m": 3.0, "cat": "concrete", "price": 35},
}


static func item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	return JUNK.get(id, {})


static func model_path(data: Dictionary) -> String:
	var dir: String = NATURE_DIR if data.get("dir", "") == "nature" else FURNITURE_DIR
	return dir % data["model"]


static func items_in_tab(tab: String) -> Array:
	var out := []
	for id in ITEMS:
		if ITEMS[id]["tab"] == tab:
			out.append(id)
	return out


static func finish(kind: String, id: String) -> Dictionary:
	return (WALL if kind == "wall" else FLOOR).get(id, {})


static func shop_finishes(kind: String) -> Array:
	var table: Dictionary = WALL if kind == "wall" else FLOOR
	var out := []
	for id in table:
		if table[id]["cat"] != "old":
			out.append(id)
	return out
