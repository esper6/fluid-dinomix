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
		
	# Create UI programmatically
	if ui != null:
		create_game_ui()
	
	# Initialize building system
	print("Creating building system...")
	building_system = BuildingSystem.new()
	game_area.add_child(building_system)
	print("Building system added to GameArea")
	
	# Initialize level manager
	print("Creating level manager...")
	level_manager = LevelManager.new()
	add_child(level_manager)
	level_manager.level_completed.connect(_on_level_completed)
	print("Level manager created")
	
	# Fluid system script is already attached in the scene
	
	# Create a simple test level
	print("Creating test level...")
	create_test_level()
	print("Game setup complete!")

func create_test_level():
	print("Creating test level programmatically...")
	
	# Create fluid source programmatically
	print("Creating FluidSource...")
	var source = create_fluid_source()
	game_area.add_child(source)
	source.global_position = Vector2(100, 100)
	source.fluid_spawned.connect(_on_fluid_spawned)
	fluid_sources.append(source)
	print("FluidSource created at position: ", source.global_position)
	
	# Create fluid goal programmatically
	print("Creating FluidGoal...")
	var goal = create_fluid_goal()
	game_area.add_child(goal)
	goal.global_position = Vector2(400, 300)
	fluid_goals.append(goal)
	print("FluidGoal created at position: ", goal.global_position)
	
	# Setup level manager
	print("Setting up level manager with ", fluid_sources.size(), " sources and ", fluid_goals.size(), " goals")
	level_manager.setup_level(fluid_sources, fluid_goals)
	print("Test level created successfully!")

func create_fluid_source() -> FluidSource:
	var source = FluidSource.new()
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	source.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.modulate = Color(0.2, 0.6, 1, 1)
	# Create a simple texture
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.CYAN)
	texture.set_image(image)
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
	SceneManager.go_to_title()

func create_game_ui():
	print("Creating game UI programmatically...")
	
	# Create the main UI control
	var game_ui = Control.new()
	game_ui.name = "GameUI"
	game_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(game_ui)
	
	# Create building palette
	var building_palette = VBoxContainer.new()
	building_palette.name = "BuildingPalette"
	building_palette.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	building_palette.position = Vector2(-120, -150)
	building_palette.size = Vector2(100, 300)
	game_ui.add_child(building_palette)
	
	# Add palette label
	var palette_label = Label.new()
	palette_label.text = "Building Blocks:"
	palette_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	building_palette.add_child(palette_label)
	
	# Create building buttons
	var button_configs = [
		{"name": "SolidButton", "text": "Solid Block", "type": BuildingBlock.BlockType.SOLID},
		{"name": "RampRightButton", "text": "Ramp Right", "type": BuildingBlock.BlockType.RAMP_RIGHT},
		{"name": "RampLeftButton", "text": "Ramp Left", "type": BuildingBlock.BlockType.RAMP_LEFT},
		{"name": "PipeHButton", "text": "Pipe H", "type": BuildingBlock.BlockType.PIPE_HORIZONTAL},
		{"name": "PipeVButton", "text": "Pipe V", "type": BuildingBlock.BlockType.PIPE_VERTICAL}
	]
	
	for config in button_configs:
		var button = Button.new()
		button.name = config.name
		button.text = config.text
		button.custom_minimum_size = Vector2(80, 30)
		button.pressed.connect(_on_building_button_pressed.bind(config.type))
		building_palette.add_child(button)
	
	# Create instructions
	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Left Click: Place Block\nRight Click: Remove Block\nGoal: Get fluid from source to target!"
	instructions.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	instructions.position = Vector2(10, -80)
	instructions.size = Vector2(400, 60)
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	game_ui.add_child(instructions)
	
	print("Game UI created successfully")

func _on_building_button_pressed(block_type: BuildingBlock.BlockType):
	if building_system:
		building_system.set_current_block_type(block_type)
		print("Selected building block type: ", block_type)

func _input(event):
	# Allow ESC key to return to menu
	if event.is_action_pressed("ui_cancel"):
		_return_to_menu()
