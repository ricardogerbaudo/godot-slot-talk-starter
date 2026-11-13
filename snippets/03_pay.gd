# Step 9: in main.gd, replace the pay() function with this block.
@export var wild: Texture2D

const PAYS := {3: 2, 4: 5, 5: 10}


func pay() -> int:
	var win := 0
	for row in 3:
		var count := count_line(row)
		if count >= 3:
			win += line_bet * PAYS[count]
			for i in count:
				%Reels.get_child(i).highlight(row)
	if win > 0:
		%Anubis.play("action")
	return win


func count_line(row: int) -> int:
	var target: Texture2D = null
	var count := 0
	for reel in %Reels.get_children():
		var symbol: Texture2D = reel.get_symbol(row)
		if symbol != wild:
			if target == null:
				target = symbol
			elif symbol != target:
				break
		count += 1
	return count


func _on_anubis_animation_finished() -> void:
	%Anubis.play("idle")
