extends Node2D
class_name BuildingSystem

@export var grid_size: int = 32
var building_block_scene: PackedScene
var placed_blocks: Dictionary = {}
var current_block_type: BuildingBlock.BlockType = BuildingBlock.BlockType.SOLID

# Drawing mode variables
var is_draw_mode: bool = false
var is_drawing: bool = false
var current_drawing_line: Line2D
var current_drawing_body: StaticBody2D
var draw_points: PackedVector2Array = []
var draw_thickness: float = 16.0
var stroke_segments := {}  # Dictionary: Line2D -> Array[CollisionShape2D]

# Continuous erase state
var is_erasing: bool = false
var last_erase_pos: Vector2 = Vector2.INF
var erase_interval_sec: float = 0.0      # 0 = every frame; set e.g. 0.02 for 50 Hz
var erase_min_spacing: float = 2.0       # don't erase twice too close to each other
var _erase_accum: float = 0.0


var strokes: Array[Stroke] = []
var current_stroke: Stroke = null

signal block_placed(position: Vector2, block_type: BuildingBlock.BlockType)
signal block_removed(position: Vector2)

func _ready():
	print("BuildingSystem ready - creating blocks programmatically")
	# Add to group for easy finding
	add_to_group("building_system")


func _process(delta: float) -> void:
	if not is_draw_mode:
		return

	if is_erasing:
		if erase_interval_sec <= 0.0:
			# Every frame is fine; spacing guard will protect from over-splitting
			_perform_erase(get_global_mouse_position())
		else:
			_erase_accum += delta
			while _erase_accum >= erase_interval_sec:
				_erase_accum -= erase_interval_sec
				_perform_erase(get_global_mouse_position())


func _input(event):
	if event is InputEventMouseButton:
		# Check if mouse is over UI - if so, don't handle the input
		var ui_node = get_node_or_null("/root/Main/UI/GameUI")
		if ui_node and _is_mouse_over_ui(ui_node, event.position):
			return
		
		if is_draw_mode:
			print("Routing input to draw mode: ", event.button_index, " pressed: ", event.pressed)
			handle_draw_input(event)
		else:
			handle_block_input(event)
	
	elif event is InputEventMouseMotion and is_draw_mode and is_drawing:
		handle_draw_motion(event)

func handle_block_input(event: InputEventMouseButton):
	var grid_pos = world_to_grid(get_global_mouse_position())
	
	if event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place_block(grid_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove_block(grid_pos)



func handle_draw_input(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drawing(get_global_mouse_position())
		else:
			finish_drawing()

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_erasing = true
			last_erase_pos = Vector2.INF
			_perform_erase(get_global_mouse_position())
		else:
			is_erasing = false
			last_erase_pos = Vector2.INF


func handle_draw_motion(_event: InputEventMouseMotion) -> void:
	if is_drawing and current_stroke:
		add_point_to_current_drawing(get_global_mouse_position())
	# Erase while moving the mouse, if RMB is held
	if is_erasing:
		_perform_erase(get_global_mouse_position())


func _is_mouse_over_ui(ui_node: Control, mouse_pos: Vector2) -> bool:
	# Check if mouse is over any UI element
	var ui_rect = ui_node.get_global_rect()
	if ui_rect.has_point(mouse_pos):
		# More specific check for building palette
		var building_palette = ui_node.get_node_or_null("BuildingPalette")
		if building_palette:
			var palette_rect = building_palette.get_global_rect()
			if palette_rect.has_point(mouse_pos):
				return true
	return false

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / grid_size),
		int(world_pos.y / grid_size)
	)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * grid_size + grid_size / 2.0,
		grid_pos.y * grid_size + grid_size / 2.0
	)

func place_block(grid_pos: Vector2i):
	var key = str(grid_pos)
	
	# Don't place if already occupied
	if key in placed_blocks:
		return
	
	print("Placing block of type: ", current_block_type, " at position: ", grid_pos)
	var block = create_building_block(current_block_type)
	add_child(block)
	block.global_position = grid_to_world(grid_pos)
	
	placed_blocks[key] = block
	block_placed.emit(grid_to_world(grid_pos), current_block_type)

func create_building_block(block_type: BuildingBlock.BlockType) -> BuildingBlock:
	var block = BuildingBlock.new()
	block.block_type = block_type
	
	# Create collision shape based on block type
	create_collision_for_block_type(block, block_type)
	
	# Add sprite with distinct visual for each type
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	
	match block_type:
		BuildingBlock.BlockType.SOLID:
			# Gray solid block
			image.fill(Color.GRAY)
			
		BuildingBlock.BlockType.RAMP_RIGHT:
			# Brown ramp - solid brown, no transparency
			# Collision: bottom-left to bottom-right to top-right triangle
			image.fill(Color.BROWN)
			# Make non-collision area match background color
			for y in range(32):
				for x in range(32):
					# Convert to collision coordinate system (-16 to 16)
					var local_x = x - 16
					var local_y = y - 16
					# Check if point is inside the collision triangle
					# Triangle: (-16,16), (16,16), (16,-16)
					if not point_in_right_triangle(local_x, local_y):
						image.set_pixel(x, y, Color(0.1, 0.15, 0.3, 1))  # Match game background
						
		BuildingBlock.BlockType.RAMP_LEFT:
			# Brown ramp - solid brown, no transparency
			# Collision: bottom-left to bottom-right to top-left triangle
			image.fill(Color.BROWN)
			# Make non-collision area match background color
			for y in range(32):
				for x in range(32):
					# Convert to collision coordinate system (-16 to 16)
					var local_x = x - 16
					var local_y = y - 16
					# Check if point is inside the collision triangle
					# Triangle: (-16,16), (16,16), (-16,-16)
					if not point_in_left_triangle(local_x, local_y):
						image.set_pixel(x, y, Color(0.1, 0.15, 0.3, 1))  # Match game background
						
		BuildingBlock.BlockType.PIPE_HORIZONTAL:
			# Dark gray pipe - show solid parts only
			image.fill(Color(0.1, 0.15, 0.3, 1))  # Background color
			# Fill the solid collision areas (top and bottom strips)
			for y in range(32):
				for x in range(32):
					if y < 12 or y >= 20:  # Top and bottom strips only
						image.set_pixel(x, y, Color.DARK_GRAY)
					
		BuildingBlock.BlockType.PIPE_VERTICAL:
			# Dark gray pipe - show solid parts only
			image.fill(Color(0.1, 0.15, 0.3, 1))  # Background color
			# Fill the solid collision areas (left and right strips)
			for x in range(32):
				for y in range(32):
					if x < 12 or x >= 20:  # Left and right strips only
						image.set_pixel(x, y, Color.DARK_GRAY)

	
	texture.set_image(image)
	sprite.texture = texture
	block.add_child(sprite)
	
	return block

# Helper functions to check if point is inside collision triangles
func point_in_right_triangle(x: float, y: float) -> bool:
	# Right triangle: (-16,16), (16,16), (16,-16)
	# Point is inside if it's below/on the diagonal line from top-right to bottom-left
	# Line equation: y = -x (from (16,-16) to (-16,16))
	return y >= -x

func point_in_left_triangle(x: float, y: float) -> bool:
	# Left triangle: (-16,16), (16,16), (-16,-16)  
	# Point is inside if it's below/on the diagonal line from top-left to bottom-right
	# Line equation: y = x (from (-16,-16) to (16,16))
	return y >= x

func create_collision_for_block_type(block: BuildingBlock, block_type: BuildingBlock.BlockType):
	match block_type:
		BuildingBlock.BlockType.SOLID:
			# Solid rectangle collision
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(32, 32)
			collision.shape = shape
			block.add_child(collision)
			
		BuildingBlock.BlockType.RAMP_RIGHT:
			# Right triangle collision
			var collision = CollisionShape2D.new()
			var shape = ConvexPolygonShape2D.new()
			# Triangle points: bottom-left, bottom-right, top-right
			shape.points = PackedVector2Array([
				Vector2(-16, 16),   # bottom-left
				Vector2(16, 16),    # bottom-right  
				Vector2(16, -16)    # top-right
			])
			collision.shape = shape
			block.add_child(collision)
			
		BuildingBlock.BlockType.RAMP_LEFT:
			# Left triangle collision
			var collision = CollisionShape2D.new()
			var shape = ConvexPolygonShape2D.new()
			# Triangle points: bottom-left, bottom-right, top-left
			shape.points = PackedVector2Array([
				Vector2(-16, 16),   # bottom-left
				Vector2(16, 16),    # bottom-right
				Vector2(-16, -16)   # top-left
			])
			collision.shape = shape
			block.add_child(collision)
			
		BuildingBlock.BlockType.PIPE_HORIZONTAL:
			# Hollow pipe - create top and bottom collision strips
			# Top strip
			var top_collision = CollisionShape2D.new()
			var top_shape = RectangleShape2D.new()
			top_shape.size = Vector2(32, 12)
			top_collision.shape = top_shape
			top_collision.position = Vector2(0, -10)  # Move up
			block.add_child(top_collision)
			
			# Bottom strip  
			var bottom_collision = CollisionShape2D.new()
			var bottom_shape = RectangleShape2D.new()
			bottom_shape.size = Vector2(32, 12)
			bottom_collision.shape = bottom_shape
			bottom_collision.position = Vector2(0, 10)   # Move down
			block.add_child(bottom_collision)
			
		BuildingBlock.BlockType.PIPE_VERTICAL:
			# Hollow pipe - create left and right collision strips
			# Left strip
			var left_collision = CollisionShape2D.new()
			var left_shape = RectangleShape2D.new()
			left_shape.size = Vector2(12, 32)
			left_collision.shape = left_shape
			left_collision.position = Vector2(-10, 0)  # Move left
			block.add_child(left_collision)
			
			# Right strip
			var right_collision = CollisionShape2D.new()
			var right_shape = RectangleShape2D.new()
			right_shape.size = Vector2(12, 32)
			right_collision.shape = right_shape
			right_collision.position = Vector2(10, 0)   # Move right
			block.add_child(right_collision)

func remove_block(grid_pos: Vector2i):
	var key = str(grid_pos)
	
	if key in placed_blocks:
		placed_blocks[key].queue_free()
		placed_blocks.erase(key)
		block_removed.emit(grid_to_world(grid_pos))

func set_current_block_type(type: BuildingBlock.BlockType):
	current_block_type = type
	print("Building system: Block type changed to ", type)

func set_draw_mode(draw_mode: bool):
	is_draw_mode = draw_mode
	print("Building system: Draw mode ", "enabled" if draw_mode else "disabled")
	
	# If switching away from draw mode, finish any current drawing
	if not draw_mode and is_drawing:
		finish_drawing()

# Drawing mode functions

func start_drawing(start_pos: Vector2) -> void:
	print("Starting drawing at: ", start_pos)
	is_drawing = true
	current_stroke = Stroke.new()
	current_stroke.draw_thickness = draw_thickness
	current_stroke.color = Color.BROWN
	add_child(current_stroke)
	strokes.append(current_stroke)
	current_stroke.add_point(start_pos)



func add_point_to_current_drawing(pos: Vector2) -> void:
	if not current_stroke:
		return
	var pts := current_stroke.points()
	if pts.size() == 0 or pos.distance_to(pts[pts.size() - 1]) > 8.0:
		current_stroke.add_point(pos)


func add_collision_segment(from: Vector2, to: Vector2):
	if not current_drawing_body:
		return
	
	# Create collision shape for this line segment
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# Calculate segment properties
	var segment_length = from.distance_to(to)
	var segment_center = (from + to) / 2.0
	var segment_angle = from.angle_to_point(to)
	
	# Set up collision shape
	shape.size = Vector2(segment_length, draw_thickness)
	collision.shape = shape
	collision.position = segment_center
	collision.rotation = segment_angle
	
	current_drawing_body.add_child(collision)


func finish_drawing() -> void:
	if not is_drawing:
		return
	print("Finishing drawing with ", current_stroke.points().size(), " points")
	is_drawing = false
	current_stroke = null


func erase_drawn_line_at_position(pos: Vector2) -> void:
	print("Erasing near: ", pos)
	var erase_radius := draw_thickness * 2.0

	var best_stroke: Stroke = null
	var best_idx := -1
	var best_dist := INF

	for s in strokes:
		if not is_instance_valid(s):
			continue
		var idx := s.get_closest_segment_index(pos, erase_radius)
		if idx == -1:
			continue
		var pts := s.points()
		var a := pts[idx]
		var b := pts[idx + 1]
		var closest := Geometry2D.get_closest_point_to_segment(pos, a, b)
		var d := pos.distance_to(closest)
		if d < best_dist:
			best_dist = d
			best_stroke = s
			best_idx = idx

	if best_stroke == null:
		print("No drawn segment found near position: ", pos)
		return

	var spawned: Array = best_stroke.erase_segment_at_position(pos, erase_radius)

	# Rebuild strokes list: drop the freed one, keep valid ones, then add spawns
	var new_list: Array[Stroke] = []
	for s in strokes:
		if is_instance_valid(s) and s != best_stroke:
			new_list.append(s)
	for ns in spawned:
		if is_instance_valid(ns):
			new_list.append(ns)
	strokes = new_list

	print("Erased one segment. New strokes: ", spawned.size())



func clear_blocks():
	print("BuildingSystem: Clearing all blocks and drawn lines")

	# Remove all placed blocks
	for block in placed_blocks.values():
		if is_instance_valid(block):
			block.queue_free()
	placed_blocks.clear()

	# Remove all strokes
	for s in strokes:
		if is_instance_valid(s):
			s.queue_free()
	strokes.clear()


func _perform_erase(current_pos: Vector2) -> void:
	# First time or reset: just erase where we are
	if last_erase_pos == Vector2.INF:
		_do_single_erase(current_pos)
		last_erase_pos = current_pos
		return

	var dist := last_erase_pos.distance_to(current_pos)
	if dist < erase_min_spacing:
		# Still honor small movement if called from _process (cursor still)
		_do_single_erase(current_pos)
		last_erase_pos = current_pos
		return

	# Step along the line from last -> current and erase at fixed spacing
	var step := erase_min_spacing
	var dir := (current_pos - last_erase_pos).normalized()
	var walked := 0.0
	var p := last_erase_pos

	while walked + step <= dist:
		p += dir * step
		_do_single_erase(p)
		walked += step

	# Final pass at the actual current position
	_do_single_erase(current_pos)
	last_erase_pos = current_pos


func _do_single_erase(pos: Vector2) -> void:
	# You already have erase_drawn_line_at_position(pos) implemented.
	erase_drawn_line_at_position(pos)
