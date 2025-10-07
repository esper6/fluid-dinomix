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
	
	# Create realistic marble texture programmatically
	create_marble_texture(image, randf()) # Pass random seed for variation
	
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
	
	# Marbles don't split like water, so no collision signal needed
	# particle.body_entered.connect(particle._on_body_entered)
	
	return particle

func create_marble_texture(image: Image, variation_seed: float):
	# Create a realistic marble with varied colors, highlights, and patterns
	var center = Vector2(8, 8)
	var max_radius = 6.0
	
	# Marble color variations - different marble types
	var marble_types = [
		# Classic glass marbles
		[Color(0.8, 0.2, 0.2, 1.0), Color(1.0, 0.4, 0.4, 1.0)],  # Red marble
		[Color(0.2, 0.8, 0.2, 1.0), Color(0.4, 1.0, 0.4, 1.0)],  # Green marble
		[Color(0.2, 0.2, 0.8, 1.0), Color(0.4, 0.4, 1.0, 1.0)],  # Blue marble
		[Color(0.8, 0.8, 0.2, 1.0), Color(1.0, 1.0, 0.4, 1.0)],  # Yellow marble
		[Color(0.8, 0.4, 0.8, 1.0), Color(1.0, 0.6, 1.0, 1.0)],  # Purple marble
		[Color(0.9, 0.6, 0.3, 1.0), Color(1.0, 0.8, 0.5, 1.0)],  # Orange marble
		[Color(0.7, 0.7, 0.7, 1.0), Color(0.9, 0.9, 0.9, 1.0)]   # Silver marble
	]
	
	# Choose marble type based on variation seed
	var marble_index = int(variation_seed * marble_types.size()) % marble_types.size()
	var marble_colors = marble_types[marble_index]
	var base_color = marble_colors[0]
	var highlight_color = marble_colors[1]
	
	# Size variation per marble
	var size_variation = 0.8 + variation_seed * 0.4  # 0.8 to 1.2 size multiplier
	max_radius *= size_variation
	
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				# Calculate distance ratio for falloff
				var dist_ratio = dist / max_radius
				
				# Create marble edge with sharp falloff (glass-like)
				var alpha_falloff = 1.0 - smoothstep(0.85, 1.0, dist_ratio)
				
				# Add marble pattern (swirls and internal reflections)
				var pattern_x = sin(x * 0.5 + variation_seed * 10) * 0.3
				var pattern_y = cos(y * 0.7 + variation_seed * 15) * 0.3
				var swirl_factor = sin((x + y) * 0.4 + variation_seed * 8) * 0.2
				
				# Combine patterns for marble-like internal structure
				var pattern_intensity = (pattern_x + pattern_y + swirl_factor + 1.0) / 2.0
				pattern_intensity = clamp(pattern_intensity, 0.0, 1.0)
				
				# Blend base color with pattern
				var marble_color = base_color.lerp(highlight_color, pattern_intensity * 0.6)
				
				# Add glass-like highlight (strong specular reflection)
				var highlight_pos = Vector2(5 + variation_seed * 2, 4 + variation_seed * 1.5)
				var highlight_dist = pos.distance_to(highlight_pos)
				var highlight_strength = max(0, 1.0 - highlight_dist / 2.5)
				
				# Strong highlight for glass marble effect
				if highlight_strength > 0.4:
					var highlight_intensity = 0.7 + variation_seed * 0.3
					marble_color = marble_color.lerp(Color.WHITE, highlight_strength * highlight_intensity)
				
				# Add subtle edge darkening for 3D effect
				if dist_ratio > 0.6:
					var edge_darkening = (dist_ratio - 0.6) / 0.4
					marble_color = marble_color.lerp(Color.BLACK, edge_darkening * 0.3)
				
				# Apply alpha falloff
				marble_color.a = alpha_falloff
				
				image.set_pixel(x, y, marble_color)
			else:
				# Transparent outside the marble
				image.set_pixel(x, y, Color.TRANSPARENT)

func _on_particle_removed():
	current_particles -= 1
