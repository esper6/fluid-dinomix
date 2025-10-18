extends Area2D
class_name FluidGoal

@export var fluid_required: int = 10
var fluid_collected: int = 0
var is_completed: bool = false  # Track if goal is already completed

signal goal_completed
signal marble_collected(count: int)  # New signal for UI updates

func _ready():
	# Add to group for discovery by LevelManager
	add_to_group("FluidGoal")
	print("FluidGoal (Bucket) _ready() called")
	# Connect to body entered for marble detection
	body_entered.connect(_on_body_entered)
	
	# Create bucket visual
	create_bucket_visual()

func create_bucket_visual():
	# Create bucket sprite programmatically
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Create bucket texture
	var texture = ImageTexture.new()
	var image = Image.create(64, 48, false, Image.FORMAT_RGBA8)
	
	# Draw bucket shape
	draw_bucket(image)
	
	texture.set_image(image)
	sprite.texture = texture

func draw_bucket(image: Image):
	# Fill with transparent background
	image.fill(Color.TRANSPARENT)
	
	# Bucket colors
	var bucket_color = Color(0.6, 0.4, 0.2, 1.0)  # Brown bucket
	var rim_color = Color(0.8, 0.6, 0.4, 1.0)     # Lighter rim
	var handle_color = Color(0.5, 0.3, 0.1, 1.0)  # Dark handle
	
	# Draw bucket body (trapezoid shape)
	for y in range(48):
		for x in range(64):
			var progress = float(y) / 47.0  # 0 at top, 1 at bottom
			
			# Calculate bucket width at this height (wider at top)
			var top_width = 50
			var bottom_width = 35
			var current_width = top_width - (top_width - bottom_width) * progress
			
			var center_x = 32
			var left_edge = center_x - current_width / 2
			var right_edge = center_x + current_width / 2
			
			# Draw bucket walls and bottom
			if y >= 5:  # Leave space for rim
				if (x >= left_edge and x <= left_edge + 4) or (x >= right_edge - 4 and x <= right_edge):
					# Bucket walls
					image.set_pixel(x, y, bucket_color)
				elif y >= 42 and x >= left_edge and x <= right_edge:
					# Bucket bottom
					image.set_pixel(x, y, bucket_color)
			
			# Draw rim
			if y >= 2 and y <= 7:
				if x >= left_edge - 2 and x <= right_edge + 2:
					image.set_pixel(x, y, rim_color)
	
	# Draw handles
	for handle_x in [8, 56]:  # Left and right handles
		for y in range(15, 25):
			for x in range(handle_x - 2, handle_x + 2):
				if x >= 0 and x < 64:
					image.set_pixel(x, y, handle_color)

func _on_body_entered(body):
	if body is FluidParticle and not body.collected and not is_completed:
		collect_marble()
		body.collect()  # Remove the marble

func collect_marble():
	fluid_collected += 1
	print("Marble collected: ", fluid_collected, "/", fluid_required)
	
	# Emit signal for UI update
	marble_collected.emit(fluid_collected)
	
	# Check if goal is reached for the FIRST time
	if fluid_collected >= fluid_required and not is_completed:
		is_completed = true
		goal_completed.emit()
		print("Goal completed for the first time!")

func reset():
	fluid_collected = 0
	is_completed = false  # Reset completion state
	marble_collected.emit(0)  # Update UI

func get_collected_count() -> int:
	return fluid_collected
