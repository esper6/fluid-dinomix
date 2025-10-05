extends Node2D
class_name FluidSystem

@export var max_particles: int = 500
var current_particles: int = 0
var particle_scene: PackedScene

func _ready():
	print("FluidSystem ready - creating particles programmatically")

func spawn_fluid_particle(pos: Vector2):
	print("FluidSystem: spawn_fluid_particle called at ", pos)
	if current_particles >= max_particles:
		print("Max particles reached: ", current_particles)
		return
		
	var particle = create_fluid_particle()
	add_child(particle)
	particle.global_position = pos + Vector2(randf_range(-8, 8), 0)
	
	# Add some random velocity
	particle.linear_velocity = Vector2(randf_range(-50, 50), randf_range(-20, 20))
	
	current_particles += 1
	print("Particle created at ", particle.global_position, " - Total particles: ", current_particles)
	
	# Connect to clean up counter when particle is freed
	particle.tree_exited.connect(_on_particle_removed)

func create_fluid_particle() -> FluidParticle:
	var particle = FluidParticle.new()
	particle.gravity_scale = 2.0
	particle.contact_monitor = true
	particle.max_contacts_reported = 10
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	particle.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(0.5, 0.5)
	sprite.name = "Sprite2D"
	# Create particle texture programmatically
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Draw a circle
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x - 8, y - 8).length()
			if dist <= 6:
				var alpha = 1.0 - (dist / 6.0) * 0.3
				image.set_pixel(x, y, Color(0.3, 0.7, 1.0, alpha))
	
	texture.set_image(image)
	sprite.texture = texture
	particle.add_child(sprite)
	
	# Add life timer
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.autostart = true
	timer.name = "LifeTimer"
	particle.add_child(timer)
	timer.timeout.connect(particle._on_life_timer_timeout)
	
	# Note: RigidBody2D doesn't have body_entered or area_entered signals
	# Collision detection is handled in FluidParticle script using _physics_process
	
	return particle

func _on_particle_removed():
	current_particles -= 1
