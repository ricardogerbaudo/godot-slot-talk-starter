# Step 8: attach to the Main root node (main.gd).
extends Control

var line_bet := 10


func _on_spin_button_pressed() -> void:
	%SpinButton.disabled = true
	await spin()
	var win := pay()
	print("Win: ", win)
	%SpinButton.disabled = false


func spin() -> void:
	var reels := %Reels.get_children()
	for reel in reels:
		reel.spin()
	await get_tree().create_timer(0.8).timeout
	for reel in reels:
		reel.stop()
		await get_tree().create_timer(0.25).timeout


func pay() -> int:
	return 0
