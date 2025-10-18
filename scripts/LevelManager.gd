extends Node
class_name LevelManager

# Signals
signal level_completed
signal level_failed

# Level management
@export var levels: Array[PackedScene] = []
@export var current_level: int = 1  # 1-based index

# System references (NodePaths with sensible defaults)
@export var building_system_path: NodePath = NodePath("../GameArea/BuildingSystem")
@export var fluid_system_path: NodePath = NodePath("../FluidSystem")

# Internal state
var building_system: BuildingSystem
var fluid_system: FluidSystem
var active_level: Level = null
var active_level_node: Node = null

# Goal tracking
var goals_completed: int = 0
var total_goals: int = 0
var connected_goals: Array[FluidGoal] = []
var connected_sources: Array[FluidSource] = []

func _ready():
	print("LevelManager: Initializing")
	
	# Auto-load first level if we have levels (deferred to let Main setup systems first)
	if levels.size() > 0:
		call_deferred("load_current_level")

func _ensure_systems():
	"""Resolve system references - called when actually needed"""
	if not building_system:
		building_system = get_node_or_null(building_system_path) as BuildingSystem
		if not building_system:
			push_error("LevelManager: BuildingSystem not found at path: ", building_system_path)
	
	if not fluid_system:
		fluid_system = get_node_or_null(fluid_system_path) as FluidSystem
		if not fluid_system:
			push_error("LevelManager: FluidSystem not found at path: ", fluid_system_path)

func load_current_level():
	"""Load the level at current_level index"""
	# Ensure systems are resolved
	_ensure_systems()
	
	if current_level < 1 or current_level > levels.size():
		push_error("LevelManager: Invalid level index ", current_level, " (total levels: ", levels.size(), ")")
		return
	
	print("\n=== Loading Level ", current_level, " ===")
	
	# Get the packed scene
	var level_scene = levels[current_level - 1]
	if not level_scene:
		push_error("LevelManager: No scene at index ", current_level - 1)
		return
	
	# Instantiate the level
	active_level_node = level_scene.instantiate()
	add_child(active_level_node)
	
	# Find the Level script (either on root or a descendant)
	active_level = active_level_node as Level
	if not active_level:
		active_level = _find_level_script(active_level_node)
	
	if not active_level:
		push_error("LevelManager: Loaded scene has no Level script")
		return
	
	print("LevelManager: Level scene instantiated: ", active_level.level_name)
	
	# Discover sources and goals via groups
	var sources = _find_sources_in(active_level_node)
	var goals = _find_goals_in(active_level_node)
	
	print("LevelManager: Found ", sources.size(), " sources and ", goals.size(), " goals")
	
	# Connect sources to fluid system
	if fluid_system:
		for source in sources:
			if source and is_instance_valid(source):
				source.fluid_spawned.connect(_on_fluid_spawned)
				connected_sources.append(source)
				print("  - Connected source '", source.name, "' to FluidSystem")
	
	# Setup level tracking
	setup_level(sources, goals)
	
	# Let the level initialize its geometry
	if building_system and fluid_system:
		active_level.setup_level(building_system, fluid_system, self)
	else:
		push_warning("LevelManager: Missing systems, skipping level setup")
	
	print("=== Level ", current_level, " loaded successfully ===\n")

func reload_level():
	"""Reload the current level from scratch"""
	print("LevelManager: Reloading level ", current_level)
	unload_current_level()
	load_current_level()

func unload_current_level():
	"""Clean up and unload the active level"""
	if not active_level_node:
		return
	
	print("LevelManager: Unloading current level")
	
	# Disconnect source signals
	for source in connected_sources:
		if is_instance_valid(source) and source.fluid_spawned.is_connected(_on_fluid_spawned):
			source.fluid_spawned.disconnect(_on_fluid_spawned)
	connected_sources.clear()
	
	# Disconnect goal signals
	for goal in connected_goals:
		if is_instance_valid(goal) and goal.goal_completed.is_connected(_on_goal_completed):
			goal.goal_completed.disconnect(_on_goal_completed)
	connected_goals.clear()
	
	# Clear building blocks
	if building_system:
		building_system.clear_blocks()
	
	# Remove level node
	if is_instance_valid(active_level_node):
		active_level_node.queue_free()
	
	active_level = null
	active_level_node = null
	goals_completed = 0
	total_goals = 0
	
	print("LevelManager: Level unloaded")

func next_level():
	"""Unload current level and load the next one"""
	print("LevelManager: Moving to next level")
	unload_current_level()
	reset_level()
	current_level += 1
	
	if current_level <= levels.size():
		load_current_level()
	else:
		print("LevelManager: All levels completed!")
		# TODO: Show victory screen or loop back to level 1

func fail_level():
	"""Called when level conditions are not met"""
	print("LevelManager: Level failed")
	level_failed.emit()
	# TODO: Optionally auto-reload here if desired
	# reload_level()

func setup_level(_sources: Array[FluidSource], goals: Array[FluidGoal]):
	"""Setup level tracking - called internally after discovery"""
	total_goals = goals.size()
	goals_completed = 0
	connected_goals.clear()
	
	print("LevelManager: Setting up tracking for ", total_goals, " goals")
	
	# Connect goal signals and track them
	for goal in goals:
		if goal and is_instance_valid(goal):
			goal.goal_completed.connect(_on_goal_completed)
			connected_goals.append(goal)
			print("  - Connected goal: ", goal.name)

func reset_level():
	"""Reset level state without reloading"""
	goals_completed = 0

func _on_goal_completed():
	"""Called when any goal is completed"""
	goals_completed += 1
	print("LevelManager: Goals completed: ", goals_completed, "/", total_goals)
	
	if goals_completed >= total_goals:
		if total_goals > 0:
			print("LevelManager: All goals completed!")
			level_completed.emit()
		else:
			push_warning("LevelManager: 0 goals in level, auto-completing")

# Helper functions for group-based discovery

func _find_sources_in(level_root: Node) -> Array[FluidSource]:
	"""Find all FluidSource nodes in the level using groups"""
	var sources: Array[FluidSource] = []
	
	for node in get_tree().get_nodes_in_group("FluidSource"):
		# Check if node is part of this level (scoped)
		if level_root.is_ancestor_of(node):
			# Type safety check
			if node is FluidSource:
				sources.append(node as FluidSource)
			else:
				push_warning("LevelManager: Node '", node.name, "' in FluidSource group but not FluidSource type")
	
	return sources

func _find_goals_in(level_root: Node) -> Array[FluidGoal]:
	"""Find all FluidGoal nodes in the level using groups"""
	var goals: Array[FluidGoal] = []
	
	for node in get_tree().get_nodes_in_group("FluidGoal"):
		# Check if node is part of this level (scoped)
		if level_root.is_ancestor_of(node):
			# Type safety check
			if node is FluidGoal:
				goals.append(node as FluidGoal)
			else:
				push_warning("LevelManager: Node '", node.name, "' in FluidGoal group but not FluidGoal type")
	
	return goals

func _find_level_script(node: Node) -> Level:
	"""Recursively search for a node with the Level script"""
	if node is Level:
		return node as Level
	
	for child in node.get_children():
		var result = _find_level_script(child)
		if result:
			return result
	
	return null

func _on_fluid_spawned(spawn_position: Vector2):
	"""Called when a FluidSource spawns fluid - forward to FluidSystem"""
	if fluid_system:
		fluid_system.spawn_fluid_particle(spawn_position)
	else:
		push_warning("LevelManager: FluidSystem not available for spawning")
