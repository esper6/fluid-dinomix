extends RigidBody2D
class_name FluidParticle

var collected: bool = false

# Marble physics properties - simpler than water
var bounce_factor: float = 0.7  # How bouncy marbles are
var rolling_friction: float = 0.1  # Friction when rolling
var marble_size: float = 4.0  # Radius of marble collision

func _ready():
	print("FluidParticle (Marble) _ready() called")
	# Add to fluid particle group for easy finding
	add_to_group("fluid_particles")
	
	# Set marble physics properties
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = bounce_factor
	physics_material_override.friction = rolling_friction

# Simple physics process - marbles don't need complex goal checking
func _physics_process(delta):
	if collected:
		return
	
	# Marbles are collected by the bucket's collision detection
	# No need to check for goals here

func collect():
	if not collected:
		collected = true
		# Remove from group before deletion
		remove_from_group("fluid_particles")
		queue_free()

func _on_life_timer_timeout():
	# Remove from group before deletion
	remove_from_group("fluid_particles")
	queue_free()
