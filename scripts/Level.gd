@tool
extends Node2D
class_name Level

# Level configuration
@export var level_name: String = "Untitled Level"
@export var level_description: String = ""
@export var source_position: Vector2 = Vector2(100, 100)
@export var goal_position: Vector2 = Vector2(400, 300)

# References to child nodes
var building_system: BuildingSystem
var fluid_system: FluidSystem
var level_manager: LevelManager

signal level_completed
signal level_failed

func _ready():
	print("Level loaded: ", level_name)

func setup_level(bs: BuildingSystem, fs: FluidSystem, lm: LevelManager):
	building_system = bs
	fluid_system = fs  
	level_manager = lm
	
	print("Level '", level_name, "' setup initiated.")
	
	# Convert visual nodes to actual building blocks
	create_building_blocks_from_nodes()
	
	print("Level '", level_name, "' geometry converted to building blocks.")

func create_building_blocks_from_nodes():
	# Get the LevelGeometry node and its children
	var level_geometry = get_node_or_null("LevelGeometry")
	if not level_geometry:
		print("Warning: No LevelGeometry node found")
		return
	
	# Process platforms (solid blocks)
	var platforms = level_geometry.get_node_or_null("Platforms")
	if platforms:
		for platform in platforms.get_children():
			if platform is ColorRect:
				create_block_from_rect(platform, BuildingBlock.BlockType.SOLID)
	
	# Process obstacles (solid blocks)
	var obstacles = level_geometry.get_node_or_null("Obstacles")
	if obstacles:
		for obstacle in obstacles.get_children():
			if obstacle is ColorRect:
				create_block_from_rect(obstacle, BuildingBlock.BlockType.SOLID)
	
	# Process ramps
	var ramps = level_geometry.get_node_or_null("Ramps")
	if ramps:
		for ramp in ramps.get_children():
			if ramp is ColorRect:
				var block_type = BuildingBlock.BlockType.RAMP_RIGHT
				if "Left" in ramp.name:
					block_type = BuildingBlock.BlockType.RAMP_LEFT
				create_block_from_rect(ramp, block_type)
	
	# Process pipes
	var pipes = level_geometry.get_node_or_null("Pipes")
	if pipes:
		for pipe in pipes.get_children():
			if pipe is ColorRect:
				var block_type = BuildingBlock.BlockType.PIPE_HORIZONTAL
				if "V" in pipe.name or "Vertical" in pipe.name:
					block_type = BuildingBlock.BlockType.PIPE_VERTICAL
				create_block_from_rect(pipe, block_type)

func create_block_from_rect(rect: ColorRect, block_type: BuildingBlock.BlockType):
	# Calculate center position of the rect
	var center_pos = Vector2(
		rect.position.x + rect.size.x / 2,
		rect.position.y + rect.size.y / 2
	)
	
	# Convert to grid position
	var grid_pos = Vector2i(
		int(center_pos.x / building_system.grid_size),
		int(center_pos.y / building_system.grid_size)
	)
	
	# Create the building block
	var key = str(grid_pos)
	if key in building_system.placed_blocks:
		return  # Already exists
	
	var block = building_system.create_building_block(block_type)
	building_system.add_child(block)
	block.global_position = building_system.grid_to_world(grid_pos)
	building_system.placed_blocks[key] = block
	
	print("Created ", BuildingBlock.BlockType.keys()[block_type], " block at ", grid_pos)

func get_source_position() -> Vector2:
	return source_position

func get_goal_position() -> Vector2:
	return goal_position
