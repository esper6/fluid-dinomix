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

func _input(event):
	if event is InputEventMouseButton:
		var grid_pos = world_to_grid(get_global_mouse_position())
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				place_block(grid_pos)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				remove_block(grid_pos)

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
	
	var block = create_building_block(current_block_type)
	add_child(block)
	block.global_position = grid_to_world(grid_pos)
	
	placed_blocks[key] = block
	block_placed.emit(grid_to_world(grid_pos), current_block_type)

func create_building_block(block_type: BuildingBlock.BlockType) -> BuildingBlock:
	var block = BuildingBlock.new()
	block.block_type = block_type
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	block.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	
	match block_type:
		BuildingBlock.BlockType.SOLID:
			image.fill(Color.GRAY)
		BuildingBlock.BlockType.RAMP_RIGHT:
			image.fill(Color.BROWN)
		BuildingBlock.BlockType.RAMP_LEFT:
			image.fill(Color.BROWN)
		BuildingBlock.BlockType.PIPE_HORIZONTAL:
			image.fill(Color.DARK_GRAY)
		BuildingBlock.BlockType.PIPE_VERTICAL:
			image.fill(Color.DARK_GRAY)
	
	texture.set_image(image)
	sprite.texture = texture
	block.add_child(sprite)
	
	return block

func remove_block(grid_pos: Vector2i):
	var key = str(grid_pos)
	
	if key in placed_blocks:
		placed_blocks[key].queue_free()
		placed_blocks.erase(key)
		block_removed.emit(grid_to_world(grid_pos))

func set_current_block_type(type: BuildingBlock.BlockType):
	current_block_type = type
