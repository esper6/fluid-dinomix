extends StaticBody2D
class_name BuildingBlock

enum BlockType {
	SOLID,
	RAMP_RIGHT,
	RAMP_LEFT,
	PIPE_HORIZONTAL,
	PIPE_VERTICAL
}

@export var block_type: BlockType = BlockType.SOLID

func _ready():
	print("BuildingBlock _ready() called")
