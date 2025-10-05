extends Area2D
class_name FluidSource

@export var flow_rate: float = 1.0
@export var is_active: bool = true

var spawn_timer: Timer

signal fluid_spawned(position: Vector2)

func _ready():
	print("FluidSource _ready() called")
	# Find the spawn timer that was added programmatically
	spawn_timer = get_node("SpawnTimer")
	if spawn_timer == null:
		print("ERROR: SpawnTimer not found in FluidSource!")
	else:
		print("FluidSource spawn timer found")

func _on_spawn_timer_timeout():
	if is_active:
		spawn_fluid()

func spawn_fluid():
	# Emit signal for fluid system to handle
	print("FluidSource spawning fluid at: ", global_position)
	fluid_spawned.emit(global_position)

func set_active(active: bool):
	is_active = active
	spawn_timer.paused = not active
