extends Control
# Lightweight, resolution-independent anime effects; capped and cleaned up.
var ground_only = false
var bursts = []
var clock = 0.0
var dice = RandomNumberGenerator.new()

func _init():
	mouse_filter = MOUSE_FILTER_IGNORE
	dice.seed = 1138

func clear():
	bursts.clear()
	queue_redraw()

func burst(point, direction, kind):
	if bursts.size() >= 4:
		bursts.pop_front()
	var sparks = []
	for i in (22 if kind == "qi" else 14):
		var angle = dice.randf_range(-PI, PI)
		sparks.append(Vector2.from_angle(angle) * dice.randf_range(40.0, 155.0))
	bursts.append({"point": point, "direction": direction, "kind": kind, "age": 0.0, "sparks": sparks})

func _process(delta):
	if not is_visible_in_tree():
		return
	clock += delta
	for event in bursts:
		event["age"] += delta
	bursts = bursts.filter(func(event): return event["age"] < 0.65)
	queue_redraw()

func _draw():
	if size.x <= 0:
		return
	if ground_only:
		for x in [0.27, 0.73]:
			draw_set_transform(Vector2(size.x * x, size.y * 0.945), 0.0, Vector2(1.0, 0.17))
			for ring in 4:
				draw_circle(Vector2.ZERO, size.y * (0.135 - ring * 0.02), Color(0.02, 0.025, 0.06, 0.09))
		draw_set_transform(Vector2.ZERO)
		return
	# Sparse drifting qi motes, rather than a full-screen particle emitter.
	for i in 9:
		var x = fposmod(i * 87.1 + sin(clock * 0.4 + i) * 15.0, size.x)
		var y = fposmod(i * 49.3 - clock * (7.0 + i), max(size.y, 1.0))
		draw_circle(Vector2(x, y), 1.0 + i % 2, Color(0.6, 0.94, 1.0, 0.12 + 0.08 * sin(clock + i)))
	for event in bursts:
		var t = event["age"] / 0.65
		var point = event["point"]
		var qi = event["kind"] == "qi"
		var tint = Color("77eaff") if qi else Color("ffd28a")
		tint.a = (1.0 - t) * (1.0 - t)
		var radius = 8.0 + t * (100.0 if qi else 65.0)
		draw_arc(point, radius, 0, TAU, 48, tint, max(1.0, 5.0 * (1.0 - t)), true)
		if qi:
			draw_arc(point, radius * 0.65, -clock * 3.0, TAU - clock * 3.0, 48, Color(tint, tint.a * 0.6), 2.0, true)
		for velocity in event["sparks"]:
			var start = point + velocity * t
			var end = start + velocity.normalized() * (13.0 * (1.0 - t))
			draw_line(start, end, tint, 2.0, true)
		# Bright four-point impact star, disappearing faster than the sparks.
		if t < 0.32:
			var length = (1.0 - t / 0.32) * (60.0 if qi else 42.0)
			var points = PackedVector2Array()
			for i in 8:
				points.append(point + Vector2.from_angle(i * PI / 4.0 + 0.3) * (length if i % 2 == 0 else length * 0.12))
			draw_colored_polygon(points, Color("f3feff") if qi else Color("fff7de"))
