extends Node
class_name LevelManager

signal level_completed
signal level_failed

var current_level: int = 1
var goals_completed: int = 0
var total_goals: int = 0

func setup_level(_sources: Array[FluidSource], goals: Array[FluidGoal]):
	total_goals = goals.size()
	goals_completed = 0
	
	# Connect goal signals
	for goal in goals:
		goal.goal_completed.connect(_on_goal_completed)

func _on_goal_completed():
	goals_completed += 1
	print("Goals completed: ", goals_completed, "/", total_goals)
	
	if goals_completed >= total_goals:
		level_completed.emit()

func reset_level():
	goals_completed = 0

func next_level():
	current_level += 1
	reset_level()

func fail_level():
	# Called when level conditions are not met (e.g., time limit, particle limit)
	level_failed.emit()
