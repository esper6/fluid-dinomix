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

signal block_placed(position: Vector2, block_type: BuildingBlock.BlockType)
signal block_removed(position: Vector2)

func _ready():
	print("BuildingSystem ready - creating blocks programmatically")
	# Add to group for easy finding
	add_to_group("building_system")

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

func handle_draw_input(event: InputEventMouseButton):
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drawing(get_global_mouse_position())
		else:
			finish_drawing()
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right click to erase drawn lines
		print("Right-click in draw mode at: ", get_global_mouse_position())
		erase_drawn_line_at_position(get_global_mouse_position())

func handle_draw_motion(_event: InputEventMouseMotion):
	if is_drawing and current_drawing_line:
		add_point_to_current_drawing(get_global_mouse_position())

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
func start_drawing(start_pos: Vector2):
	print("Starting drawing at: ", start_pos)
	is_drawing = true
	draw_points.clear()
	draw_points.append(start_pos)
	
	# Create visual line
	current_drawing_line = Line2D.new()
	current_drawing_line.width = draw_thickness
	current_drawing_line.default_color = Color.BROWN
	current_drawing_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_drawing_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_drawing_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_drawing_line.add_point(start_pos)
	add_child(current_drawing_line)
	
	# Create physics body for collision
	current_drawing_body = StaticBody2D.new()
	add_child(current_drawing_body)

func add_point_to_current_drawing(pos: Vector2):
	if not is_drawing or not current_drawing_line:
		return
	
	# Only add point if it's far enough from the last point (smooth drawing)
	var last_point = draw_points[-1]
	if pos.distance_to(last_point) > 8.0:  # Minimum distance between points
		draw_points.append(pos)
		current_drawing_line.add_point(pos)
		
		# Add collision segment for the new line segment
		add_collision_segment(last_point, pos)

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

func finish_drawing():
	if not is_drawing:
		return
	
	print("Finishing drawing with ", draw_points.size(), " points")
	is_drawing = false
	
	# Finalize the drawing
	if current_drawing_line and draw_points.size() >= 2:
		# Keep the line and collision body
		current_drawing_line = null
		current_drawing_body = null
	else:
		# Remove incomplete drawing
		if current_drawing_line:
			current_drawing_line.queue_free()
			current_drawing_line = null
		if current_drawing_body:
			current_drawing_body.queue_free()
			current_drawing_body = null
	
	draw_points.clear()

func erase_drawn_line_at_position(pos: Vector2):
	print("Looking for drawn lines to erase at position: ", pos)
	var erase_radius = draw_thickness * 2  # Larger detection radius
	var lines_to_remove = []
	var bodies_to_remove = []
	
	# Find all Line2D nodes and their corresponding StaticBody2D collision bodies
	for child in get_children():
		if child is Line2D:
			# Check if click is near any point on the line
			var line_node = child as Line2D
			var should_remove = false
			
			for point in line_node.points:
				if pos.distance_to(point) < erase_radius:
					should_remove = true
					break
			
			# Also check if click is near any line segment
			if not should_remove and line_node.points.size() >= 2:
				for i in range(line_node.points.size() - 1):
					var point_a = line_node.points[i]
					var point_b = line_node.points[i + 1]
					var closest_point = Geometry2D.get_closest_point_to_segment(pos, point_a, point_b)
					if pos.distance_to(closest_point) < erase_radius:
						should_remove = true
						break
			
			if should_remove:
				lines_to_remove.append(line_node)
				print("Found line to remove with ", line_node.points.size(), " points")
	
	# Find corresponding StaticBody2D collision bodies to remove
	for child in get_children():
		if child is StaticBody2D:
			# Check if this StaticBody2D has collision shapes near the click position
			var body_node = child as StaticBody2D
			var should_remove = false
			
			for collision_child in body_node.get_children():
				if collision_child is CollisionShape2D:
					var collision_pos = body_node.global_position + collision_child.position
					if pos.distance_to(collision_pos) < erase_radius * 2:  # Larger radius for collision bodies
						should_remove = true
						break
			
			if should_remove:
				bodies_to_remove.append(body_node)
	
	# Remove all found lines and bodies
	for line in lines_to_remove:
		line.queue_free()
	for body in bodies_to_remove:
		body.queue_free()
	
	if lines_to_remove.size() > 0:
		print("Erased ", lines_to_remove.size(), " drawn lines and ", bodies_to_remove.size(), " collision bodies at: ", pos)
	else:
		print("No drawn lines found near position: ", pos)
