class_name Jobs
## The renovation jobs for each house, played in order.
##
## Task types:
##   trash / dirt / junk / weeds: remove every one of these in `rooms` (all if omitted)
##   walls: every wall of `room` has a finish whose category is in `cat` (any new one if empty)
##   floor: the floor of `room` has a finish whose category is in `cat`
##   item: at least `count` items of category `cat` placed in `room`

const LIST := [
	{
		"id": "cleanup",
		"title": "Tenant From Hell",
		"client": "Mrs. Parker",
		"brief":
		"My last tenant left the place in a terrible state. Please get rid of the trash, scrub the grime and haul away the old furniture in the living room and kitchen.",
		"reward": 600,
		"tasks":
		[
			{"type": "trash", "rooms": ["living", "kitchen"]},
			{"type": "dirt", "rooms": ["living", "kitchen"]},
			{"type": "junk", "rooms": ["living", "kitchen"]},
		],
	},
	{
		"id": "bathroom",
		"title": "Bathroom Makeover",
		"client": "Mrs. Parker",
		"brief":
		"That bathroom gives me nightmares. Clean it out, tile the walls and floor, and install a toilet, a sink, a shower or bath and a mirror.",
		"reward": 900,
		"tasks":
		[
			{"type": "junk", "rooms": ["bathroom"]},
			{"type": "dirt", "rooms": ["bathroom"]},
			{"type": "walls", "room": "bathroom", "cat": ["tiles"]},
			{"type": "floor", "room": "bathroom", "cat": ["tiles"]},
			{"type": "item", "room": "bathroom", "cat": "toilet", "count": 1},
			{"type": "item", "room": "bathroom", "cat": "sink", "count": 1},
			{"type": "item", "room": "bathroom", "cat": "bath", "count": 1},
			{"type": "item", "room": "bathroom", "cat": "mirror", "count": 1},
		],
	},
	{
		"id": "living",
		"title": "Cozy Living Room",
		"client": "Mrs. Parker",
		"brief":
		"Now make the living room feel like home: fresh walls, a new floor, a sofa, a coffee table, a TV, a lamp, a rug and some plants.",
		"reward": 1400,
		"tasks":
		[
			{"type": "walls", "room": "living", "cat": ["paint", "wallpaper"]},
			{"type": "floor", "room": "living", "cat": ["wood", "carpet"]},
			{"type": "item", "room": "living", "cat": "sofa", "count": 1},
			{"type": "item", "room": "living", "cat": "coffee_table", "count": 1},
			{"type": "item", "room": "living", "cat": "tv", "count": 1},
			{"type": "item", "room": "living", "cat": "lamp", "count": 1},
			{"type": "item", "room": "living", "cat": "rug", "count": 1},
			{"type": "item", "room": "living", "cat": "plant", "count": 2},
		],
	},
	{
		"id": "kitchen",
		"title": "Dream Kitchen",
		"client": "Mrs. Parker",
		"brief":
		"Buyers love a good kitchen. New walls, tiled floor, a fridge, a stove, a sink, counters and a dining table with chairs, please!",
		"reward": 1500,
		"tasks":
		[
			{"type": "walls", "room": "kitchen", "cat": []},
			{"type": "floor", "room": "kitchen", "cat": ["tiles"]},
			{"type": "item", "room": "kitchen", "cat": "fridge", "count": 1},
			{"type": "item", "room": "kitchen", "cat": "stove", "count": 1},
			{"type": "item", "room": "kitchen", "cat": "kitchen_sink", "count": 1},
			{"type": "item", "room": "kitchen", "cat": "counter", "count": 2},
			{"type": "item", "room": "kitchen", "cat": "table", "count": 1},
			{"type": "item", "room": "kitchen", "cat": "chair", "count": 2},
		],
	},
	{
		"id": "bedroom",
		"title": "Bedroom & Laundry",
		"client": "Mrs. Parker",
		"brief":
		"Clear out the bedroom and laundry room, then decorate the bedroom with a bed, a nightstand and a lamp. Don't forget a washing machine!",
		"reward": 1500,
		"tasks":
		[
			{"type": "junk", "rooms": ["bedroom", "utility"]},
			{"type": "dirt", "rooms": ["bedroom", "utility"]},
			{"type": "trash", "rooms": ["bedroom", "utility", "bathroom"]},
			{"type": "walls", "room": "bedroom", "cat": []},
			{"type": "floor", "room": "bedroom", "cat": ["wood", "carpet"]},
			{"type": "item", "room": "bedroom", "cat": "bed", "count": 1},
			{"type": "item", "room": "bedroom", "cat": "nightstand", "count": 1},
			{"type": "item", "room": "bedroom", "cat": "lamp", "count": 1},
			{"type": "item", "room": "utility", "cat": "washer", "count": 1},
		],
	},
	{
		"id": "garden",
		"title": "Backyard Paradise",
		"client": "Mrs. Parker",
		"brief":
		"Last one! The backyard is a jungle. Pull the weeds, pick up the trash, plant flowers and bushes and set up a place to relax by the pool.",
		"reward": 1600,
		"tasks":
		[
			{"type": "weeds"},
			{"type": "trash", "rooms": ["backyard", "frontyard"]},
			{"type": "item", "room": "backyard", "cat": "flower", "count": 6},
			{"type": "item", "room": "backyard", "cat": "bush", "count": 2},
			{"type": "item", "room": "backyard", "cat": "outdoor_seat", "count": 2},
			{"type": "item", "room": "backyard", "cat": "outdoor_table", "count": 1},
		],
	},
	{
		"id": "sell",
		"title": "Flip It!",
		"client": "Real Estate Agent",
		"brief":
		"The house looks amazing. Walk around, add any finishing touches you like, then put it on the market. The more you improved it, the higher the price!",
		"reward": 0,
		"tasks": [],
	},
]

const CAT_LABELS := {
	"toilet": "toilet",
	"sink": "bathroom sink",
	"bath": "shower or bathtub",
	"mirror": "mirror",
	"sofa": "sofa",
	"coffee_table": "coffee table",
	"tv": "TV",
	"lamp": "lamp",
	"rug": "rug",
	"plant": "plants",
	"fridge": "fridge",
	"stove": "stove",
	"kitchen_sink": "kitchen sink",
	"counter": "counters",
	"table": "dining table",
	"chair": "chairs",
	"bed": "bed",
	"nightstand": "nightstand",
	"washer": "washing machine",
	"flower": "flowers",
	"bush": "bushes or planters",
	"outdoor_seat": "garden seats",
	"outdoor_table": "garden table",
}


static func count() -> int:
	return LIST.size()


static func get_job(index: int) -> Dictionary:
	return LIST[clampi(index, 0, LIST.size() - 1)]


static func reward(index: int, house_no: int) -> int:
	return int(get_job(index)["reward"] * (1.0 + 0.25 * (house_no - 1)))


static func task_label(t: Dictionary) -> String:
	var rooms := ""
	if t.has("rooms"):
		var names := []
		for r in t["rooms"]:
			names.append(HouseLayout.room_name(r))
		rooms = " (" + ", ".join(names) + ")"
	match t["type"]:
		"trash":
			return "Pick up trash" + rooms
		"dirt":
			return "Clean dirt" + rooms
		"junk":
			return "Remove old furniture" + rooms
		"weeds":
			return "Pull weeds in the yard"
		"walls":
			var what := (
				"new " + " or ".join(t["cat"])
				if not t["cat"].is_empty()
				else "new paint or wallpaper"
			)
			return "%s walls: %s" % [HouseLayout.room_name(t["room"]), what]
		"floor":
			var what := "new " + " or ".join(t["cat"]) if not t["cat"].is_empty() else "a new floor"
			return "%s floor: %s" % [HouseLayout.room_name(t["room"]), what]
		"item":
			var n: int = t["count"]
			var label: String = CAT_LABELS.get(t["cat"], t["cat"])
			var prefix := "Place %d %s" % [n, label] if n > 1 else "Place a " + label
			return "%s in the %s" % [prefix, HouseLayout.room_name(t["room"]).to_lower()]
	return "?"
