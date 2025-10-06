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
	particle.gravity_scale = 0.8
	particle.contact_monitor = true
	particle.max_contacts_reported = 10
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	particle.add_child(collision)
	
	# Add sprite with realistic fluid appearance
	var sprite = Sprite2D.new()
	sprite.scale = Vector2(0.5, 0.5)
	sprite.name = "Sprite2D"
	# Create realistic fluid texture programmatically
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	
	# Create more realistic fluid droplet with varied shades and transparency
	create_fluid_droplet_texture(image, randf()) # Pass random seed for variation
	
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
	
	# Connect collision signal for splitting behavior
	particle.body_entered.connect(particle._on_body_entered)
	
	# Note: RigidBody2D doesn't have body_entered or area_entered signals
	# Collision detection is handled in FluidParticle script using _physics_process
	
	return particle

# New function to create split particles
func create_split_particle(pos: Vector2, velocity: Vector2):
	if current_particles >= max_particles:
		return
		
	var particle = create_fluid_particle()
	add_child(particle)
	particle.global_position = pos
	particle.linear_velocity = velocity
	
	current_particles += 1
	# Connect to clean up counter when particle is freed
	particle.tree_exited.connect(_on_particle_removed)

func create_fluid_droplet_texture(image: Image, variation_seed: float):
	# Create a realistic water droplet with varied shades, highlights, and natural variations
	var center = Vector2(8, 8)
	var max_radius = 6.0
	
	# Base fluid colors with variation - each particle gets slightly different tones
	var hue_shift = variation_seed * 0.1 - 0.05  # Small hue variation
	var brightness_shift = variation_seed * 0.2 - 0.1  # Brightness variation
	
	var base_colors = [
		Color(0.2 + brightness_shift, 0.6 + brightness_shift, 0.9 + hue_shift, 0.8),   
		Color(0.3 + brightness_shift, 0.7 + brightness_shift, 1.0 + hue_shift, 0.85),  
		Color(0.15 + brightness_shift, 0.55 + brightness_shift, 0.85 + hue_shift, 0.75), 
		Color(0.4 + brightness_shift, 0.8 + brightness_shift, 1.0 + hue_shift, 0.9)    
	]
	
	# Slight size variation per particle
	var size_variation = 0.8 + variation_seed * 0.4  # 0.8 to 1.2 size multiplier
	max_radius *= size_variation
	
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				# Calculate distance ratio for falloff
				var dist_ratio = dist / max_radius
				
				# Create natural edge falloff
				var alpha_falloff = 1.0 - smoothstep(0.6, 1.0, dist_ratio)
				
				# Add some randomness for natural variation (unique per particle)
				var noise_x = sin(x * 0.8 + y * 0.6 + variation_seed * 10) * 0.15
				var noise_y = cos(x * 0.7 + y * 0.9 + variation_seed * 15) * 0.15
				var noise_factor = 0.85 + noise_x + noise_y
				
				# Choose base color with some variation
				var color_index = int((x + y * 0.7 + variation_seed * 4) * 0.3) % base_colors.size()
				var base_color = base_colors[color_index]
				
				# Add highlight effect (simulating light reflection) - varies per particle
				var highlight_pos = Vector2(5 + variation_seed * 2, 4 + variation_seed * 1.5)
				var highlight_dist = pos.distance_to(highlight_pos)
				var highlight_strength = max(0, 1.0 - highlight_dist / 3.0)
				
				# Combine base color with highlight
				var final_color = base_color
				if highlight_strength > 0.3:
					var highlight_intensity = 0.3 + variation_seed * 0.2  # Vary highlight strength
					final_color = final_color.lerp(Color.WHITE, highlight_strength * highlight_intensity)
				
				# Apply noise variation
				final_color.r *= noise_factor
				final_color.g *= noise_factor  
				final_color.b *= noise_factor
				
				# Clamp colors to valid range
				final_color.r = clamp(final_color.r, 0.0, 1.0)
				final_color.g = clamp(final_color.g, 0.0, 1.0)
				final_color.b = clamp(final_color.b, 0.0, 1.0)
				
				# Apply alpha falloff
				final_color.a *= alpha_falloff
				
				# Add subtle edge darkening for depth
				if dist_ratio > 0.7:
					final_color = final_color.lerp(Color(0.1, 0.4, 0.7, final_color.a), 0.3)
				
				image.set_pixel(x, y, final_color)

func _on_particle_removed():
	current_particles -= 1
