extends Area2D
class_name FluidGoal

@export var fluid_required: int = 10
var fluid_collected: int = 0

signal goal_completed

func _ready():
	print("FluidGoal _ready() called")

func _on_area_entered(area):
	if area.has_method("collect"):
		collect_fluid()

func collect_fluid():
	fluid_collected += 1
	print("Fluid collected: ", fluid_collected, "/", fluid_required)
	
	if fluid_collected >= fluid_required:
		goal_completed.emit()
		print("Goal completed!")

func reset():
	fluid_collected = 0
