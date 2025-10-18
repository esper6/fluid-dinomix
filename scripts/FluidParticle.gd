extends RigidBody2D
class_name FluidParticle

# --- Tuning knobs ---
@export var super_bounce: float = 1000000000000.25	# > 1.0 = more than elastic
@export var min_impact_speed: float = 40  # only boost if impact is this strong
@export var max_speed: float = 1400.0	 # safety clamp to avoid runaway speeds

var collected: bool = false
var bounce_factor: float = 1.0			# leave material at 1.0 (ignored by custom bounce)
var rolling_friction: float = 0.0
var marble_size: float = 4.0

func _ready():
	print("FluidParticle (Marble) _ready() called")
	# Physics material (not used for >1 effect, but keep sane defaults)
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce   = bounce_factor   # 0..1 (docs)
	physics_material_override.friction = rolling_friction

	# We take over integration so we can add >1.0 bounce
	custom_integrator = true

	# Remove energy loss from damping (docs suggest this for energy preservation)
	linear_damp_mode  = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp	   = 0.0
	angular_damp	  = 0.0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if collected:
		return

	# 1) Apply gravity ourselves (use engine-provided gravity)
	#	(The direct body state exposes step time and total gravity.)
	state.linear_velocity += state.total_gravity * state.step

	# 2) Look for a contact whose normal faces our movement (incoming)
	var v := state.linear_velocity
	var contact_count := state.get_contact_count()
	for i in contact_count:
		var n: Vector2 = state.get_contact_local_normal(i) # Outward normal at contact
		var incoming_speed := -v.dot(n)					# speed along the normal, positive if hitting into the surface
		if incoming_speed > min_impact_speed:
			# 3) Compute mirror bounce and multiply it for >1.0 effect
			var v_reflect := v.bounce(n)				   # standard reflection across normal
			v = v_reflect * super_bounce

			# 4) Soft clamp to avoid numerical blowups
			var sp := v.length()
			if sp > max_speed:
				v = v * (max_speed / sp)

			# Only boost once per step to avoid compounding across multiple contacts
			break

	state.linear_velocity = v

func collect():
	if not collected:
		collected = true
		remove_from_group("fluid_particles")
		queue_free()

func _on_life_timer_timeout():
	remove_from_group("fluid_particles")
	queue_free()
