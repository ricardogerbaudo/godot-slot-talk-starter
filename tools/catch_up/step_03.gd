@tool
extends EditorScript
## File > Run (Cmd+Shift+X / Ctrl+Shift+X): rebuilds the project as it is at the end of step 3.
## Overwrites the tutorial scenes and scripts, and removes the ones that come later.


func _run() -> void:
	var catch_up: Node = load("res://tools/catch_up/catch_up.gd").new()
	catch_up.step = 3
	EditorInterface.get_base_control().add_child(catch_up)
