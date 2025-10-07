extends Node2D
class_name Main

var game_area: Node2D
var fluid_system: FluidSystem
var ui: CanvasLayer
var building_system: BuildingSystem
var level_manager: LevelManager
var fluid_sources: Array[FluidSource] = []
var fluid_goals: Array[FluidGoal] = []

func _ready():
	print("Fluid Dinomix - Main scene loaded")
	var current_scene = get_tree().current_scene
	if current_scene != null:
		print("Scene tree: ", current_scene.name)
	else:
		print("Scene tree: [null current_scene]")
	
	# Show the game UI when Main.tscn loads
	if has_node("UI"):
		ui = get_node("UI")
		if ui != null:
			ui.visible = true
	
	# Always start the game directly when Main.tscn is loaded
	# (TitleScreen.tscn will load this scene when Play is pressed)
	setup_game()


func setup_game():
	print("Setting up game...")
	
	# Debug: Print all child nodes
	print("Available child nodes:")
	for child in get_children():
		if child != null:
			print("  - ", child.name, " (", child.get_class(), ")")
		else:
			print("  - [null child]")
	
	# Get node references directly to avoid @onready timing issues
	if has_node("GameArea"):
		game_area = get_node("GameArea")
	else:
		print("GameArea node does not exist!")
		
	if has_node("FluidSystem"):
		fluid_system = get_node("FluidSystem")
	else:
		print("FluidSystem node does not exist!")
		
	if has_node("UI"):
		ui = get_node("UI")
		# Make sure UI is visible during gameplay
		ui.visible = true
	else:
		print("UI node does not exist!")
	
	print("GameArea found: ", game_area != null)
	print("FluidSystem found: ", fluid_system != null)
	print("UI found: ", ui != null)
	
	# Create missing nodes if they don't exist
	if game_area == null:
		print("Creating GameArea node...")
		game_area = Node2D.new()
		game_area.name = "GameArea"
		add_child(game_area)
		
	if fluid_system == null:
		print("Creating FluidSystem node...")
		fluid_system = FluidSystem.new()
		fluid_system.name = "FluidSystem"
		add_child(fluid_system)
		
	# Initialize building system FIRST
	print("Creating building system...")
	building_system = BuildingSystem.new()
	game_area.add_child(building_system)
	print("Building system added to GameArea")
	
	# THEN connect UI to building system
	if ui != null:
		# UI.tscn is now loaded, connect it to building system
		setup_ui_connections()
	
	# Initialize level manager
	print("Creating level manager...")
	level_manager = LevelManager.new()
	add_child(level_manager)
	level_manager.level_completed.connect(_on_level_completed)
	print("Level manager created")
	
	# Fluid system script is already attached in the scene
	
	# Load and setup the current level
	print("Loading level...")
	load_current_level()
	print("Game setup complete!")

func load_current_level():
	# Load Level 1 scene
	var level_scene = load("res://scenes/Level1.tscn")
	if level_scene == null:
		print("Failed to load Level1.tscn - falling back to simple test level")
		create_simple_test_level()
		return
	
	# Instance the level
	var current_level = level_scene.instantiate()
	add_child(current_level)
	
	# Setup the level with our systems
	current_level.setup_level(building_system, fluid_system, level_manager)
	
	# Create source and goal based on level data
	create_level_source_and_goal(current_level)
	
	# Now that the goal exists, ensure UI is connected to it
	call_deferred("_reconnect_ui_to_goal")
	
	print("Level loaded successfully: ", current_level.level_name)

func create_level_source_and_goal(level: Level):
	# Create fluid source at level-specified position
	print("Creating FluidSource...")
	var source = create_fluid_source()
	game_area.add_child(source)
	source.global_position = level.get_source_position()
	source.fluid_spawned.connect(_on_fluid_spawned)
	fluid_sources.append(source)
	print("FluidSource created at position: ", source.global_position)
	
	# Create fluid goal at level-specified position
	print("Creating FluidGoal...")
	var goal = create_fluid_goal()
	game_area.add_child(goal)
	goal.global_position = level.get_goal_position()
	fluid_goals.append(goal)
	print("FluidGoal created at position: ", goal.global_position)
	
	# Setup level manager
	print("Setting up level manager with ", fluid_sources.size(), " sources and ", fluid_goals.size(), " goals")
	level_manager.setup_level(fluid_sources, fluid_goals)

func create_simple_test_level():
	# Fallback simple level if Level1.tscn fails to load
	print("Creating simple test level...")
	
	var source = create_fluid_source()
	game_area.add_child(source)
	source.global_position = Vector2(100, 100)
	source.fluid_spawned.connect(_on_fluid_spawned)
	fluid_sources.append(source)
	
	var goal = create_fluid_goal()
	game_area.add_child(goal)
	goal.global_position = Vector2(400, 300)
	fluid_goals.append(goal)
	
	level_manager.setup_level(fluid_sources, fluid_goals)
	
	# Ensure UI is connected to the goal
	call_deferred("_reconnect_ui_to_goal")

func create_fluid_source() -> FluidSource:
	var source = FluidSource.new()
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	source.add_child(collision)
	
	# Add sprite - load external faucet sprite from assets folder
	var sprite = Sprite2D.new()
	sprite.modulate = Color.WHITE
	
	# Try to load external faucet sprite from organized folder structure
	var texture = load("res://assets/sprites/faucet.png")
	if texture == null:
		# Simple fallback - just a blue square with indicator
		texture = ImageTexture.new()
		var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.3, 0.6, 1.0, 1.0))  # Blue background
		
		# Add simple text indicator (very basic)
		for x in range(8, 24):
			for y in range(14, 18):
				image.set_pixel(x, y, Color.WHITE)  # White text area
		
		texture.set_image(image)
		print("Using fallback faucet sprite - place faucet.png in assets/sprites/ folder to use custom sprite")
	else:
		print("Using custom faucet sprite from assets/sprites/faucet.png")
		
		# Auto-scale sprite to fit nicely in 32x32 area
		var texture_size = texture.get_size()
		var target_size = 32.0
		var scale_factor = target_size / max(texture_size.x, texture_size.y)
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		print("Sprite size: ", texture_size, " - Auto-scaled by: ", scale_factor)
	
	sprite.texture = texture
	source.add_child(sprite)
	
	# Add timer
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.name = "SpawnTimer"
	source.add_child(timer)
	timer.timeout.connect(source._on_spawn_timer_timeout)
	
	return source

func create_fluid_goal() -> FluidGoal:
	var goal = FluidGoal.new()
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(48, 48)
	collision.shape = shape
	goal.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color(1, 0.8, 0.2, 1)
	# Create a simple texture
	var texture = ImageTexture.new()
	var image = Image.create(48, 48, false, Image.FORMAT_RGB8)
	image.fill(Color.ORANGE)
	texture.set_image(image)
	sprite.texture = texture
	goal.add_child(sprite)
	
	# FluidGoal now handles its own connections in _ready()
	# No manual connection needed here
	
	return goal

func _on_fluid_spawned(spawn_position: Vector2):
	fluid_system.spawn_fluid_particle(spawn_position)

func _on_level_completed():
	print("Level completed! Well done!")
	
	# Stop all marble spawning
	stop_marble_spawning()
	
	# Show completion message
	show_completion_message()

func stop_marble_spawning():
	print("Stopping marble spawning and freezing all marbles...")
	
	# Stop all fluid sources
	for source in fluid_sources:
		if source and is_instance_valid(source):
			source.set_active(false)
			print("Stopped fluid source at: ", source.global_position)
	
	# Freeze all existing marbles by setting their gravity scale to 0 and stopping velocity
	var all_marbles = get_tree().get_nodes_in_group("fluid_particles")
	for marble in all_marbles:
		if marble and is_instance_valid(marble):
			marble.gravity_scale = 0.0  # Stop gravity
			marble.linear_velocity = Vector2.ZERO  # Stop movement
			marble.angular_velocity = 0.0  # Stop rotation
			marble.freeze = true  # Completely freeze the marble
	
	print("Froze ", all_marbles.size(), " marbles")
	
	# Also update the UI button to reflect stopped state
	var ui_control = ui.get_node_or_null("GameUI")
	if ui_control:
		ui_control.is_flow_active = false
		var start_button = ui_control.get_node_or_null("FlowControl/StartStopButton")
		if start_button:
			start_button.text = "START FLOW"
			start_button.modulate = Color(0.6, 1.0, 0.6, 1.0)  # Green tint

func show_completion_message():
	# Create a custom popup window with a working button
	var popup = PopupPanel.new()
	popup.size = Vector2(400, 200)
	add_child(popup)
	
	# Create content container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(margin)
	
	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(content_vbox)
	
	# Add title
	var title = Label.new()
	title.text = "Level Complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	content_vbox.add_child(title)
	
	# Add message
	var message = Label.new()
	message.text = "Well done! You collected all the marbles!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(message)
	
	# Add button
	var button = Button.new()
	button.text = "Good Job!"
	button.custom_minimum_size = Vector2(150, 40)
	
	# Create button container for centering
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_child(button)
	content_vbox.add_child(button_container)
	
	# Connect button to return to title screen
	button.pressed.connect(func(): 
		print("Good Job button pressed! Returning to title screen...")
		popup.queue_free()
		_return_to_menu()
	)
	
	# Show popup
	popup.popup_centered()
	print("Custom completion popup created and shown")

# Remove the old function since we're using a lambda now
# func _on_completion_dialog_confirmed(dialog: Window):

func _return_to_menu():
	print("Returning to main menu...")
	
	# Use the TitleScreen.tscn file consistently
	SceneManager.go_to_title()

func _reconnect_ui_to_goal():
	print("Reconnecting UI to goal...")
	var ui_control = ui.get_node_or_null("GameUI")
	if ui_control and ui_control.has_method("_connect_to_fluid_goal"):
		ui_control._connect_to_fluid_goal()
		print("UI reconnected to goal")

func setup_ui_connections():
	print("Setting up UI connections...")
	print("Building system exists: ", building_system != null)
	
	# The UI.tscn is now loaded as GameUI under the CanvasLayer
	var ui_control = ui.get_node_or_null("GameUI")
	if ui_control:
		if ui_control != null:
			print("Found UI control: ", ui_control.name)
		else:
			print("UI control is null after getting node")
			return
			
		if ui_control.has_method("set_building_system"):
			# If UI has a method to set building system, use it
			ui_control.set_building_system(building_system)
			print("Called set_building_system method")
		else:
			# Otherwise set it directly
			ui_control.building_system = building_system
			print("Set building_system directly")
	else:
		print("UI control not found!")
	
	print("UI connections setup complete")

func _on_building_button_pressed(block_type: BuildingBlock.BlockType):
	if building_system:
		building_system.set_current_block_type(block_type)
		print("Selected building block type: ", block_type)

func _input(event):
	# Allow ESC key to return to menu
	if event.is_action_pressed("ui_cancel"):
		_return_to_menu()
