extends Node2D
class_name BuildingSystem

@export var grid_size: int = 32
var building_block_scene: PackedScene
var placed_blocks: Dictionary = {}
var current_block_type: BuildingBlock.BlockType = BuildingBlock.BlockType.SOLID

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
			
		var grid_pos = world_to_grid(get_global_mouse_position())
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				place_block(grid_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				remove_block(grid_pos)

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
