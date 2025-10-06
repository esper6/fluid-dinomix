extends RigidBody2D
class_name FluidParticle

var collected: bool = false

# Water physics properties
var cohesion_radius: float = 20.0
var cohesion_strength: float = 0.3
var visual_radius: float = 15.0
var split_threshold: float = 80.0
var gravity_strength: float = 80.0  # Reduced for slower falling
var surface_tension: float = 0.1

# Nearby particle tracking
var nearby_particles: Array[FluidParticle] = []

func _ready():
	print("FluidParticle _ready() called")
	# Add to fluid particle group for easy finding
	add_to_group("fluid_particles")

# Enhanced physics process with water behavior
func _physics_process(delta):
	if collected:
		return
		
	# Apply natural water forces
	apply_cohesion_forces()
	apply_environmental_forces()
	update_visual_clustering()
	
	# Check for goal collection
	check_goal_collection()

func apply_cohesion_forces():
	# Find nearby particles
	nearby_particles.clear()
	var all_particles = get_tree().get_nodes_in_group("fluid_particles")
	
	for particle in all_particles:
		if particle != self and is_instance_valid(particle):
			var distance = global_position.distance_to(particle.global_position)
			if distance < cohesion_radius:
				nearby_particles.append(particle)
	
	# Apply gentle attraction to nearby particles
	var cohesion_force = Vector2.ZERO
	for particle in nearby_particles:
		var distance = global_position.distance_to(particle.global_position)
		if distance > 2.0: # Avoid division by zero
			# Gentle attraction force
			var attraction = (particle.global_position - global_position).normalized()
			var strength = (cohesion_radius - distance) / cohesion_radius * cohesion_strength
			cohesion_force += attraction * strength
	
	# Apply as gentle force, not overwhelming physics
	apply_central_force(cohesion_force * 15.0)

func apply_environmental_forces():
	# Surface tension - try to maintain roundish movement
	if linear_velocity.length() > 10.0:
		var momentum_force = linear_velocity.normalized() * surface_tension * 5.0
		apply_central_force(momentum_force)

func update_visual_clustering():
	# Scale sprite slightly based on nearby particles
	var nearby_count = nearby_particles.size()
	var scale_factor = 1.0 + (nearby_count * 0.08) # Subtle growth
	scale_factor = clamp(scale_factor, 0.8, 1.8)
	
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Slightly adjust color for "density" effect
		var density_factor = nearby_count / 8.0 # Normalize
		var color_shift = Color(1.0, 1.0 - density_factor * 0.1, 1.0 - density_factor * 0.15, 1.0)
		sprite.modulate = color_shift

func check_goal_collection():
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
		# Remove from group before deletion
		remove_from_group("fluid_particles")
		queue_free()

func _on_life_timer_timeout():
	# Remove from group before deletion
	remove_from_group("fluid_particles")
	queue_free()

# Handle collisions for splitting behavior
func _on_body_entered(body):
	if body is BuildingBlock:
		var impact_velocity = linear_velocity.length()
		
		if impact_velocity > split_threshold:
			# Create splitting effect
			create_split_particles()

func create_split_particles():
	# Get the fluid system to create new particles
	var fluid_system = get_node_or_null("/root/Main/FluidSystem")
	if fluid_system and fluid_system.has_method("create_split_particles"):
		# Create 2-3 smaller particles with scattered velocities
		var split_count = 2 + randi() % 2
		for i in range(split_count):
			var new_pos = global_position + Vector2.from_angle(randf() * TAU) * 8
			var scatter_velocity = Vector2.from_angle(randf() * TAU) * randf_range(20, 50)
			fluid_system.create_split_particle(new_pos, scatter_velocity)
		
		# Remove this particle
		collect()
