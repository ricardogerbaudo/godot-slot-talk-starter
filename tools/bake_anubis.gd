@tool
extends EditorScript
## Open this script in the Script editor and use File > Run (Ctrl+Shift+X).
## Pick the Crowns of Kemet pack folder and the browser renders the Anubis
## frames into res://art/anubis. Requires your own Spine Editor license.


func _run() -> void:
	var baker: Node = load("res://tools/anubis_baker.gd").new()
	EditorInterface.get_base_control().add_child(baker)
