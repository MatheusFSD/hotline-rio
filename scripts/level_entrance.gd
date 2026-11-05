class_name LapaEntrance
extends RefCounted
## A level's opening shot. The hero walks in along the level's entrance path to the start
## point with the camera close on him; on arrival he turns to face the level and the camera
## pulls back to the gameplay framing. Gameplay waits until it ends (or is skipped).
##
## Each level describes it in its layout:
##   "entrance": {"path": [[x, z], ...]}   points walked through before the start point
## and optionally "speed" (m/s, walking pace), "close" (camera size on the hero), "hold"
## (seconds standing at the start before the pull-back) and "pull_back" (its duration).
const SPEED := 1.4
const CLOSE := 7.5
const HOLD := .45
const PULL_BACK := 1.6
const TURN_RATE := 9.0

var route := PackedVector2Array()
var facing := 0.0
var speed := SPEED
var close := CLOSE
var hold := HOLD
var pull_back := PULL_BACK
var leg := 0
var arrived_for := 0.0
var finished := false

static func from_layout(layout: Dictionary,start: Vector2,start_angle: float) -> LapaEntrance:
	## null when the level has no entrance.
	var spec: Dictionary = layout.get("entrance",{})
	if spec.get("path",[]).is_empty(): return null
	var entrance := LapaEntrance.new()
	for point in spec.path: entrance.route.append(Vector2(point[0],point[1]))
	entrance.route.append(start)
	entrance.facing = start_angle
	entrance.speed = float(spec.get("speed",SPEED))
	entrance.close = float(spec.get("close",CLOSE))
	entrance.hold = float(spec.get("hold",HOLD))
	entrance.pull_back = float(spec.get("pull_back",PULL_BACK))
	return entrance

func duration() -> float:
	var walk := 0.0
	for i in route.size()-1: walk += route[i].distance_to(route[i+1])
	return walk/speed+hold+pull_back

func begin(player: Dictionary) -> void:
	## Puts the hero at the first point, already facing his way.
	player.p = route[0]
	player.angle = (route[1]-route[0]).angle()
	_walking(player,true)

func update(dt: float,player: Dictionary) -> float:
	## Moves the hero one step. Returns how close the camera is: 1 on the hero, 0 at the
	## gameplay framing.
	if leg < route.size()-1:
		var step := speed*dt
		while step > 0 and leg < route.size()-1:
			var to: Vector2 = route[leg+1]-player.p
			if to.length() <= step:
				player.p = route[leg+1]
				step -= to.length()
				leg += 1
			else:
				player.p += to.normalized()*step
				step = 0
		var walking := leg < route.size()-1
		_walking(player,walking)
		if walking: player.angle = lerp_angle(player.angle,(route[leg+1]-player.p).angle(),1.0-exp(-TURN_RATE*dt))
		return 1.0
	# Arrived: turn to face the level, stand a beat, then let the camera pull back.
	arrived_for += dt
	player.angle = lerp_angle(player.angle,facing,1.0-exp(-TURN_RATE*dt))
	var t := clampf((arrived_for-hold)/pull_back,0.0,1.0)
	if t >= 1.0: skip(player)
	return 1.0-smoothstep(0.0,1.0,t)

## The hero has stopped, the beat is over, the camera is on its way back.
func pulling_back() -> bool:
	return leg >= route.size()-1 and arrived_for >= hold

func skip(player: Dictionary) -> void:
	player.p = route[route.size()-1]
	player.angle = facing
	_walking(player,false)
	leg = route.size()-1
	finished = true

func _walking(player: Dictionary,walking: bool) -> void:
	# The visual picks the walk cycle from the velocity, as it does in play.
	player.moving = walking
	player.velocity = (route[leg+1]-route[leg]).normalized()*speed if walking else Vector2.ZERO
