class_name HouseLayout
## The floor plan of the house. All units are metres; the house sits on the
## XZ plane with its front wall at z = 0 and its back wall at z = DEPTH.
##
##  z=10 +---------+-------+------+
##       | Bedroom |  Bath | Util |--> back door to the yard
##  z=6  +----d----+--d----+--d---+
##       |   Living room   d Kitchen
##  z=0  +---D-----[win]---+-[win]+
##       x=0       7   8   11     14

const WIDTH := 14.0
const DEPTH := 10.0
const WALL_H := 2.8
const WALL_T := 0.2

## id -> rect [x0, z0, x1, z1], default finishes and display name.
const ROOMS := {
	"living":
	{
		"name": "Living Room",
		"rect": [0.0, 0.0, 8.0, 6.0],
		"wall": "old_floral",
		"floor": "old_carpet"
	},
	"kitchen":
	{
		"name": "Kitchen",
		"rect": [8.0, 0.0, 14.0, 6.0],
		"wall": "old_yellow",
		"floor": "old_checker"
	},
	"bedroom":
	{"name": "Bedroom", "rect": [0.0, 6.0, 7.0, 10.0], "wall": "old_dots", "floor": "old_wood"},
	"bathroom":
	{
		"name": "Bathroom",
		"rect": [7.0, 6.0, 11.0, 10.0],
		"wall": "old_green",
		"floor": "old_concrete"
	},
	"utility":
	{
		"name": "Laundry",
		"rect": [11.0, 6.0, 14.0, 10.0],
		"wall": "old_yellow",
		"floor": "old_concrete"
	},
}

## Wall lines. axis "x": runs along x at z = at, from..to are x values.
## axis "z": runs along z at x = at.
const WALLS := [
	{"axis": "x", "at": 0.0, "from": 0.0, "to": 14.0},
	{"axis": "x", "at": 10.0, "from": 0.0, "to": 14.0},
	{"axis": "z", "at": 0.0, "from": 0.0, "to": 10.0},
	{"axis": "z", "at": 14.0, "from": 0.0, "to": 10.0},
	{"axis": "x", "at": 6.0, "from": 0.0, "to": 14.0},
	{"axis": "z", "at": 8.0, "from": 0.0, "to": 6.0},
	{"axis": "z", "at": 7.0, "from": 6.0, "to": 10.0},
	{"axis": "z", "at": 11.0, "from": 6.0, "to": 10.0},
]

## Holes in walls. bottom/top are heights. kind: door, opening or window.
const OPENINGS := [
	{"axis": "x", "at": 0.0, "from": 3.0, "to": 4.1, "bottom": 0.0, "top": 2.15, "kind": "door"},
	{"axis": "x", "at": 0.0, "from": 5.2, "to": 7.2, "bottom": 0.85, "top": 2.15, "kind": "window"},
	{
		"axis": "x",
		"at": 0.0,
		"from": 10.0,
		"to": 12.6,
		"bottom": 0.95,
		"top": 2.15,
		"kind": "window"
	},
	{"axis": "z", "at": 0.0, "from": 2.0, "to": 4.0, "bottom": 0.85, "top": 2.15, "kind": "window"},
	{
		"axis": "z",
		"at": 14.0,
		"from": 2.2,
		"to": 4.0,
		"bottom": 0.95,
		"top": 2.15,
		"kind": "window"
	},
	{"axis": "z", "at": 8.0, "from": 2.0, "to": 4.2, "bottom": 0.0, "top": 2.3, "kind": "opening"},
	{"axis": "x", "at": 6.0, "from": 3.0, "to": 4.0, "bottom": 0.0, "top": 2.15, "kind": "door"},
	{"axis": "x", "at": 6.0, "from": 7.4, "to": 8.4, "bottom": 0.0, "top": 2.15, "kind": "door"},
	{"axis": "x", "at": 6.0, "from": 12.0, "to": 13.0, "bottom": 0.0, "top": 2.15, "kind": "door"},
	{"axis": "x", "at": 10.0, "from": 12.0, "to": 13.0, "bottom": 0.0, "top": 2.15, "kind": "door"},
	{
		"axis": "x",
		"at": 10.0,
		"from": 2.0,
		"to": 4.4,
		"bottom": 0.85,
		"top": 2.15,
		"kind": "window"
	},
	{"axis": "x", "at": 10.0, "from": 8.4, "to": 9.6, "bottom": 1.4, "top": 2.15, "kind": "window"},
]

## Backyard and front yard dimensions.
const YARD_BACK := 26.0
const YARD_FRONT := -10.0
const YARD_LEFT := -5.0
const YARD_RIGHT := 19.0
const POOL := [2.0, 14.0, 8.0, 19.0]
const PATIO := [9.5, 10.0, 15.5, 14.5]

const PLAYER_START := Vector3(3.55, 0.0, -4.0)


static func room_at(p: Vector3) -> String:
	for id in ROOMS:
		var r: Array = ROOMS[id]["rect"]
		if p.x > r[0] and p.x < r[2] and p.z > r[1] and p.z < r[3]:
			return id
	if p.z > DEPTH:
		return "backyard"
	return "frontyard"


static func room_name(id: String) -> String:
	if ROOMS.has(id):
		return ROOMS[id]["name"]
	return {"backyard": "Backyard", "frontyard": "Front Yard"}.get(id, id)


static func openings_on(axis: String, at: float) -> Array:
	var out := []
	for o in OPENINGS:
		if o["axis"] == axis and is_equal_approx(o["at"], at):
			out.append(o)
	return out
