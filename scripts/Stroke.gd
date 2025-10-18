extends Node2D
class_name Stroke

# Public knobs
@export var draw_thickness: float = 16.0
@export var color: Color = Color.BROWN

# Internals
var line: Line2D
var body: StaticBody2D
var segment_shapes: Array[CollisionShape2D] = []	# index matches segment (p[i]→p[i+1])

func _ready() -> void:
	line = Line2D.new()
	line.width = draw_thickness
	line.default_color = color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(line)

	body = StaticBody2D.new()
	add_child(body)

func add_point(p: Vector2) -> void:
	var pts := line.points
	line.add_point(p)
	if pts.size() >= 1:
		_create_segment_collision(pts[pts.size() - 1], p)

func points() -> PackedVector2Array:
	return line.points

func segment_count() -> int:
	return max(0, line.points.size() - 1)

func get_closest_segment_index(pos: Vector2, max_dist: float) -> int:
	var best_i := -1
	var best_d := INF
	var pts := line.points
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var closest := Geometry2D.get_closest_point_to_segment(pos, a, b)
		var d := pos.distance_to(closest)
		if d < best_d and d <= max_dist:
			best_d = d
			best_i = i
	return best_i

func erase_segment_at_position(pos: Vector2, max_dist: float) -> Array:
	# Returns Array of new Stroke nodes (0..2). Empty if nothing removed.
	if segment_count() == 0:
		return []

	var seg_i := get_closest_segment_index(pos, max_dist)
	if seg_i == -1:
		return []

	# 1) Remove that segment's collision shape
	if seg_i >= 0 and seg_i < segment_shapes.size():
		var cs := segment_shapes[seg_i]
		if is_instance_valid(cs):
			cs.queue_free()

	# 2) Split into left/right lists of points
	var old_pts := line.points.duplicate()
	var left_pts := PackedVector2Array()
	var right_pts := PackedVector2Array()

	for i in range(0, seg_i + 1):
		left_pts.append(old_pts[i])
	for i in range(seg_i + 1, old_pts.size()):
		right_pts.append(old_pts[i])

	# 3) Spawn new strokes under our parent (not under self)
	var spawned: Array = []
	var parent := get_parent()

	_spawn_stroke_from_points(left_pts, parent, spawned)
	_spawn_stroke_from_points(right_pts, parent, spawned)

	# 4) Cleanup: free remaining shapes and this stroke
	for cs2 in segment_shapes:
		if is_instance_valid(cs2):
			cs2.queue_free()
	segment_shapes.clear()

	queue_free()

	return spawned

# --- helpers ---

func _spawn_stroke_from_points(points: PackedVector2Array, parent: Node, spawned: Array) -> void:
	if points.size() < 2:
		return
	var s := Stroke.new()
	s.draw_thickness = draw_thickness
	s.color = color

	# Keep relative transform the same as ours (we live under the same parent)
	parent.add_child(s)

	# Build the stroke so collisions are created per segment
	for pi in points:
		s.add_point(pi)

	spawned.append(s)

func _create_segment_collision(a: Vector2, b: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()

	var seg_len := a.distance_to(b)
	var seg_center := (a + b) / 2.0
	var seg_angle := a.angle_to_point(b)

	shape.size = Vector2(seg_len, draw_thickness)
	collision.shape = shape
	collision.position = seg_center
	collision.rotation = seg_angle

	body.add_child(collision)
	segment_shapes.append(collision)
