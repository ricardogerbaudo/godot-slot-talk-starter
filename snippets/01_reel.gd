# Step 6: attach to the Reel root node (reel.gd).
extends Control

@export var symbols: Array[Texture2D]


func _ready() -> void:
	fill()


func fill() -> void:
	var cells := $Strip.get_children()
	for cell in cells:
		cell.texture = symbols.pick_random()
	for i in 3:
		cells[i].texture = cells[i + 6].texture


func spin() -> void:
	fill()
	$AnimationPlayer.play("spin")


func stop() -> void:
	$AnimationPlayer.play("stop")


func get_symbol(row: int) -> Texture2D:
	return $Strip.get_child(6 + row).texture


func highlight(row: int) -> void:
	$Strip.get_child(6 + row).get_node("AnimationPlayer").play("win")
