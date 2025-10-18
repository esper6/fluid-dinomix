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
	# Get the LevelGeometry node that contains all block markers
	var level_geometry = get_node_or_null("LevelGeometry")
	if not level_geometry:
		print("Warning: No LevelGeometry node found")
		return
	
	# Iterate through all children to find block markers
	process_markers_recursive(level_geometry)

func process_markers_recursive(node: Node):
	# Process all children of this node
	for child in node.get_children():
		# Check if it's a Marker2D or Node2D with block_type metadata
		if child is Marker2D or child is Node2D:
			if child.has_meta("block_type"):
				var block_type = get_block_type_from_meta(child.get_meta("block_type"))
				if block_type != -1:
					create_building_block_at_position(child.global_position, block_type)
		
		# Recursively process children
		process_markers_recursive(child)

func get_block_type_from_meta(meta_value) -> int:
	# Handle string metadata
	if meta_value is String:
		match meta_value.to_lower():
			"solid": return BuildingBlock.BlockType.SOLID
			"ramp_right": return BuildingBlock.BlockType.RAMP_RIGHT
			"ramp_left": return BuildingBlock.BlockType.RAMP_LEFT
			"pipe_horizontal": return BuildingBlock.BlockType.PIPE_HORIZONTAL
			"pipe_vertical": return BuildingBlock.BlockType.PIPE_VERTICAL
	# Handle int metadata
	elif meta_value is int:
		return meta_value
	
	return -1

func create_building_block_at_position(world_pos: Vector2, block_type: int):
	# Convert world position to grid position
	var grid_pos = Vector2i(
		int(world_pos.x / building_system.grid_size),
		int(world_pos.y / building_system.grid_size)
	)
	
	# Check if block already exists at this position
	var key = str(grid_pos)
	if key in building_system.placed_blocks:
		return  # Already exists
	
	# Create the building block
	var block = building_system.create_building_block(block_type)
	building_system.add_child(block)
	block.global_position = building_system.grid_to_world(grid_pos)
	building_system.placed_blocks[key] = block
	
	print("Created ", BuildingBlock.BlockType.keys()[block_type], " block at ", grid_pos)

func get_source_position() -> Vector2:
	return source_position

func get_goal_position() -> Vector2:
	return goal_position
