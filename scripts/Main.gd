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
	print("Scene tree: ", get_tree().current_scene.name)
	
	# Hide the game UI initially
	if has_node("UI"):
		ui = get_node("UI")
		ui.visible = false
	
	# Check if we should show title screen first
	if should_show_title_screen():
		show_title_screen()
	else:
		setup_game()

func should_show_title_screen() -> bool:
	# Show title screen if this is the first load
	return not has_meta("game_started")

func show_title_screen():
	# Create title screen programmatically to avoid loading issues
	var title_screen = create_title_screen_ui()
	add_child(title_screen)

func _on_title_play_pressed(title_screen):
	# Remove title screen and start game
	title_screen.queue_free()
	set_meta("game_started", true)
	
	# Show the game UI
	if ui:
		ui.visible = true
	
	setup_game()

func create_title_screen_ui() -> Control:
	# Create title screen entirely in code
	var title_screen = Control.new()
	title_screen.name = "TitleScreen"
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Background
	var background = ColorRect.new()
	background.color = Color(0.1, 0.15, 0.3, 1)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(background)
	
	# Center container
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(center_container)
	
	# Main layout
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 400)
	center_container.add_child(vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = "FLUID DINOMIX"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1, 1))
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle_label = Label.new()
	subtitle_label.text = "A Fluid Physics Puzzle Game"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer1)
	
	# Play button
	var play_button = Button.new()
	play_button.text = "PLAY"
	play_button.custom_minimum_size = Vector2(200, 50)
	play_button.pressed.connect(_on_title_play_pressed.bind(title_screen))
	vbox.add_child(play_button)
	
	# Settings button
	var settings_button = Button.new()
	settings_button.text = "SETTINGS"
	settings_button.custom_minimum_size = Vector2(200, 50)
	settings_button.pressed.connect(_on_title_settings_pressed)
	vbox.add_child(settings_button)
	
	# Quit button
	var quit_button = Button.new()
	quit_button.text = "QUIT"
	quit_button.custom_minimum_size = Vector2(200, 50)
	quit_button.pressed.connect(_on_title_quit_pressed)
	vbox.add_child(quit_button)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer2)
	
	# Version
	var version_label = Label.new()
	version_label.text = "v1.0"
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.modulate = Color(0.7, 0.7, 0.7, 1)
	vbox.add_child(version_label)
	
	return title_screen

func _on_title_settings_pressed():
	print("Settings button pressed")
	show_message("Settings menu coming soon!")

func _on_title_quit_pressed():
	print("Quit button pressed")
	get_tree().quit()

func show_message(text: String):
	# Create a simple popup message
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func setup_game():
	print("Setting up game...")
	
	# Debug: Print all child nodes
	print("Available child nodes:")
	for child in get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
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
	
	# Connect area signal
	goal.area_entered.connect(goal._on_area_entered)
	
	return goal

func _on_fluid_spawned(spawn_position: Vector2):
	fluid_system.spawn_fluid_particle(spawn_position)

func _on_level_completed():
	print("Level completed! Well done!")
	show_completion_message()

func show_completion_message():
	# Create a completion dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Level completed! Well done!\n\nClick OK to return to menu."
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(_return_to_menu)

func _return_to_menu():
	# Hide the game UI before returning to menu
	if ui:
		ui.visible = false
	SceneManager.go_to_title()

func setup_ui_connections():
	print("Setting up UI connections...")
	print("Building system exists: ", building_system != null)
	
	# The UI.tscn is now loaded as GameUI under the CanvasLayer
	var ui_control = ui.get_node_or_null("GameUI")
	if ui_control:
		print("Found UI control: ", ui_control.name)
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
