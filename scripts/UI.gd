extends Control
class_name GameUI

var building_system: BuildingSystem

func _ready():
	# Get reference to building system
	var main = get_node("/root/Main")
	if main:
		building_system = main.building_system

func _on_solid_button_pressed():
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.SOLID)

func _on_ramp_right_button_pressed():
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.RAMP_RIGHT)

func _on_ramp_left_button_pressed():
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.RAMP_LEFT)

func _on_pipe_h_button_pressed():
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.PIPE_HORIZONTAL)

func _on_pipe_v_button_pressed():
	if building_system:
		building_system.set_current_block_type(BuildingBlock.BlockType.PIPE_VERTICAL)
