extends Control
class_name GameUI

var building_system: BuildingSystem
var current_selected_button: Button
var fluid_source: FluidSource
var fluid_goal: FluidGoal
var is_flow_active: bool = false
var is_draw_mode: bool = true

func _ready():
	# Get reference to building system - use call_deferred to ensure Main is ready
	call_deferred("_connect_to_building_system")
	
	# Set default selection to Solid Block
	call_deferred("_set_default_selection")

func _connect_to_building_system():
	print("UI: _connect_to_building_system called")
	# Get reference to building system
	var main = get_node("/root/Main")
	if main and main.building_system:
		building_system = main.building_system
		print("UI connected to building system successfully")
	else:
		print("UI: Main not found or no building_system, trying fallbacks...")
		# Fallback: search for BuildingSystem node
		var building_nodes = get_tree().get_nodes_in_group("building_system")
		if building_nodes.size() > 0:
			building_system = building_nodes[0]
			print("UI found building system via group")
		else:
			print("UI: No building system in group, trying scene tree...")
			# Try to find it in the scene tree
			var game_area = get_node_or_null("/root/Main/GameArea")
			if game_area:
				building_system = game_area.get_node_or_null("BuildingSystem")
				if building_system:
					print("UI found building system via scene tree")
				else:
					print("UI: BuildingSystem not found in GameArea")
			else:
				print("UI: GameArea not found")
	
	# Also try to find the fluid source and goal
	call_deferred("_connect_to_fluid_source")
	call_deferred("_connect_to_fluid_goal")
	
	_apply_mode_state()
	
	print("UI: Final building_system reference: ", building_system)

func set_building_system(bs: BuildingSystem):
	building_system = bs
	print("UI building system set directly")

func _connect_to_fluid_source():
	print("UI: Looking for fluid source...")
	# Use group-based discovery (matches new LevelManager system)
	var sources = get_tree().get_nodes_in_group("FluidSource")
	if sources.size() > 0:
		# Get the first source (typically there's only one per level)
		fluid_source = sources[0] as FluidSource
		if fluid_source:
			print("UI: Found fluid source: ", fluid_source.name)
		else:
			print("UI: Node in FluidSource group is not a FluidSource type")
	else:
		print("UI: No fluid source found in FluidSource group yet")

func _connect_to_fluid_goal():
	print("UI: Looking for fluid goal...")
	# Use group-based discovery (matches new LevelManager system)
	var goals = get_tree().get_nodes_in_group("FluidGoal")
	if goals.size() > 0:
		# Get the first goal (typically there's only one per level)
		fluid_goal = goals[0] as FluidGoal
		if fluid_goal:
			print("UI: Found fluid goal: ", fluid_goal.name)
			# Connect to marble collection signal
			fluid_goal.marble_collected.connect(_on_marble_collected)
			fluid_goal.goal_completed.connect(_on_goal_completed)
			# Initialize counter display
			update_marble_counter(0, fluid_goal.fluid_required)
		else:
			print("UI: Node in FluidGoal group is not a FluidGoal type")
	else:
		print("UI: No fluid goal found in FluidGoal group yet")

func _on_marble_collected(count: int):
	print("UI: Marble collected, count: ", count)
	if fluid_goal:
		update_marble_counter(count, fluid_goal.fluid_required)

func _on_goal_completed():
	print("UI: Goal completed!")
	# You could add celebration effects here
	var count_display = get_node_or_null("MarbleCounter/CountDisplay")
	if count_display:
		count_display.modulate = Color.GREEN
		count_display.text += " - COMPLETE!"

func update_marble_counter(collected: int, required: int):
	var count_display = get_node_or_null("MarbleCounter/CountDisplay")
	if count_display:
		count_display.text = str(collected) + " / " + str(required)
		# Color coding: red if none, yellow if some, green if complete
		if collected == 0:
			count_display.modulate = Color.WHITE
		elif collected >= required:
			count_display.modulate = Color.GREEN
		else:
			count_display.modulate = Color.YELLOW

func _set_default_selection():
	var solid_button = get_node_or_null("BuildingPalette/SolidButton")
	if solid_button:
		update_button_selection(solid_button)
	
	# Set initial Start button appearance
	var start_button = get_node_or_null("FlowControl/StartStopButton")
	if start_button:
		start_button.modulate = Color(0.6, 1.0, 0.6, 1.0)  # Greenish tint to indicate "ready to start"
	
	# Set initial Mode button appearance
	var mode_button = get_node_or_null("FlowControl/ModeToggleButton")
	if mode_button:
		mode_button.modulate = Color(0.8, 0.8, 1.0, 1.0)  # Bluish tint for draw mode

func _on_solid_button_pressed():
	print("UI: Solid button pressed!")
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.SOLID)
		update_button_selection(get_node("BuildingPalette/SolidButton"))
	else:
		print("UI: No building system found!")

func _on_ramp_right_button_pressed():
	print("UI: Ramp Right button pressed!")
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.RAMP_RIGHT)
		update_button_selection(get_node("BuildingPalette/RampRightButton"))
	else:
		print("UI: No building system found!")

func _on_ramp_left_button_pressed():
	print("UI: Ramp Left button pressed!")
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.RAMP_LEFT)
		update_button_selection(get_node("BuildingPalette/RampLeftButton"))
	else:
		print("UI: No building system found!")

func _on_pipe_h_button_pressed():
	print("UI: Pipe H button pressed!")
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.PIPE_HORIZONTAL)
		update_button_selection(get_node("BuildingPalette/PipeHButton"))
	else:
		print("UI: No building system found!")

func _on_pipe_v_button_pressed():
	print("UI: Pipe V button pressed!")
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.PIPE_VERTICAL)
		update_button_selection(get_node("BuildingPalette/PipeVButton"))
	else:
		print("UI: No building system found!")

func update_button_selection(selected_button: Button):
	if selected_button == null:
		print("UI: update_button_selection called with button: null")
		return
	print("UI: update_button_selection called with button: ", selected_button.name)

	
	# Reset all buttons to normal state
	var all_buttons = [
		get_node_or_null("BuildingPalette/SolidButton"),
		get_node_or_null("BuildingPalette/RampRightButton"), 
		get_node_or_null("BuildingPalette/RampLeftButton"),
		get_node_or_null("BuildingPalette/PipeHButton"),
		get_node_or_null("BuildingPalette/PipeVButton")
	]
	
	print("UI: Found buttons: ")
	for b in all_buttons:
		if b:
			print("  - ", b.name)
		else:
			print("  - null")
	
	for button in all_buttons:
		if button:
			button.modulate = Color.WHITE
			# Reset text color to normal
			button.add_theme_color_override("font_color", Color.WHITE)
	
	# Highlight the selected button
	current_selected_button = selected_button
	if current_selected_button:
		print("UI: Highlighting button: ", current_selected_button.name)
		current_selected_button.modulate = Color(1.2, 1.2, 0.8, 1) # Slight yellow tint
		# Make text yellow for selected button
		current_selected_button.add_theme_color_override("font_color", Color.YELLOW)
	else:
		print("UI: No button to highlight!")

func _on_start_stop_button_pressed():
	print("UI: Start/Stop button pressed!")
	
	# Find the fluid source if we don't have it yet
	if not fluid_source:
		_connect_to_fluid_source()
	
	if fluid_source:
		is_flow_active = not is_flow_active
		fluid_source.set_active(is_flow_active)
		
		# Update button text
		var button = get_node_or_null("FlowControl/StartStopButton")
		if button:
			if is_flow_active:
				button.text = "STOP FLOW"
				button.modulate = Color(1.0, 0.6, 0.6, 1.0)  # Reddish tint
			else:
				button.text = "START FLOW"
				button.modulate = Color(0.6, 1.0, 0.6, 1.0)  # Greenish tint
		
		print("UI: Flow is now ", "ACTIVE" if is_flow_active else "STOPPED")
	else:
		print("UI: No fluid source found to control!")

func _on_mode_toggle_button_pressed():
	print("UI: Mode toggle button pressed!")
	
	is_draw_mode = not is_draw_mode
	
	# Update building system mode
	if building_system:
		building_system.set_draw_mode(is_draw_mode)
	
	# Update button appearance and text
	var button = get_node_or_null("FlowControl/ModeToggleButton")
	if button:
		if is_draw_mode:
			button.text = "BLOCK MODE"
			button.modulate = Color(1.0, 0.8, 0.6, 1.0)  # Orange tint for block mode
		else:
			button.text = "DRAW MODE"
			button.modulate = Color(0.8, 0.8, 1.0, 1.0)  # Blue tint for draw mode
	
	# Update building palette visibility
	var palette = get_node_or_null("BuildingPalette")
	if palette:
		palette.visible = not is_draw_mode  # Hide block palette in draw mode
	
	print("UI: Mode is now ", "DRAW" if is_draw_mode else "BLOCK")
	

func _apply_mode_state():
	# Tell the BuildingSystem
	if building_system:
		building_system.set_draw_mode(is_draw_mode)

	# Update the Mode button
	var mode_button = get_node_or_null("FlowControl/ModeToggleButton")
	if mode_button:
		if is_draw_mode:
			mode_button.text = "BLOCK MODE"               # clicking will switch to block mode
			mode_button.modulate = Color(1.0, 0.8, 0.6)   # orange-ish (your existing color)
		else:
			mode_button.text = "DRAW MODE"
			mode_button.modulate = Color(0.8, 0.8, 1.0)   # blue-ish
	
	# Hide/show the block palette
	var palette = get_node_or_null("BuildingPalette")
	if palette:
		palette.visible = not is_draw_mode
