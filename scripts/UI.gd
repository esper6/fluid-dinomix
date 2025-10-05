extends Control
class_name GameUI

var building_system: BuildingSystem
var current_selected_button: Button

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
	
	print("UI: Final building_system reference: ", building_system)

func set_building_system(bs: BuildingSystem):
	building_system = bs
	print("UI building system set directly")

func _set_default_selection():
	var solid_button = get_node_or_null("BuildingPalette/SolidButton")
	if solid_button:
		update_button_selection(solid_button)

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
	print("UI: update_button_selection called with button: ", selected_button.name if selected_button else "null")
	
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
