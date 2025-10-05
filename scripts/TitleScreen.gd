extends Control
class_name TitleScreen

func _ready():
	print("TitleScreen loaded")

func _on_play_button_pressed():
	print("Play button pressed")
	# The connection will be handled by Main.gd

func _on_settings_button_pressed():
	print("Settings button pressed")
	# TODO: Open settings menu
	# For now, just show a simple message
	show_message("Settings menu coming soon!")

func _on_quit_button_pressed():
	print("Quit button pressed")
	# Quit the game
	get_tree().quit()

func show_message(text: String):
	# Create a simple popup message
	var dialog = AcceptDialog.new()
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
