extends RigidBody2D
class_name FluidParticle

var collected: bool = false

func _ready():
	print("FluidParticle _ready() called")

# RigidBody2D collision detection using physics queries
# This is the proper way to detect Area2D overlaps from a RigidBody2D
func _physics_process(_delta):
	if collected:
		return
		
	# Check for overlapping areas (like FluidGoal)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 1  # Check default collision layer
	
	var results = space_state.intersect_point(query, 10)
	for result in results:
		var collider = result.collider
		if collider is FluidGoal and not collected:
			collider.collect_fluid()
			collect()
			break

func collect():
	if not collected:
		collected = true
		queue_free()

func _on_life_timer_timeout():
	# Remove particle after lifetime expires
	queue_free()
