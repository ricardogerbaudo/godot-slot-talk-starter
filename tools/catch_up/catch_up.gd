@tool
extends Node
## Rebuilds the tutorial project as it is at the end of a step: project
## settings, main.tscn, symbol.tscn, reel.tscn, main.gd and reel.gd.

signal finished(ok: bool)

var step := 10
var auto_run := true

const PNG := "res://PNG/"
const FRAMES := "res://art/anubis/anubis_frames.tres"
const FILES := {
	"res://main.tscn": 3,
	"res://symbol.tscn": 5,
	"res://reel.gd": 6,
	"res://reel.tscn": 6,
	"res://main.gd": 8,
}


func _ready() -> void:
	if auto_run:
		await run()
		queue_free()


func run() -> bool:
	var ok := await _build()
	if ok:
		print("The project is now at the end of step %d." % step)
	finished.emit(ok)
	return ok


func _build() -> bool:
	_apply_settings()
	_remove_later_files()
	if step < 3:
		_refresh_editor()
		return true
	if not FileAccess.file_exists(PNG + "background/background.png"):
		push_error("The PNG folder of the art pack is missing. Do step 2 first.")
		return false
	if step >= 4 and not await _ensure_frames():
		return false
	if step >= 5:
		_save_scene(_symbol(), "res://symbol.tscn")
	if step >= 6:
		_save_script(REEL_CODE, "res://reel.gd")
		_save_scene(_reel(), "res://reel.tscn")
	if step >= 8:
		var code := MAIN_CODE
		if step >= 9:
			code = code.replace("func pay() -> int:\n\treturn 0\n", PAY_CODE.substr(PAY_CODE.find("\n") + 1))
		_save_script(code, "res://main.gd")
	_save_scene(_main(), "res://main.tscn")
	_refresh_editor()
	return true


func _apply_settings() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1920)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1080)
	ProjectSettings.set_setting("display/window/size/window_width_override", 1280)
	ProjectSettings.set_setting("display/window/size/window_height_override", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("application/run/main_scene", "res://main.tscn" if step >= 8 else null)
	ProjectSettings.save()


func _remove_later_files() -> void:
	for path in FILES:
		if step < FILES[path]:
			for file in [path, path + ".uid"]:
				if FileAccess.file_exists(file):
					DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _ensure_frames() -> bool:
	if ResourceLoader.exists(FRAMES):
		return true
	if not Engine.is_editor_hint():
		push_error("Missing %s." % FRAMES)
		return false
	print("The Anubis frames are missing. Baking them now.")
	var baker: Node = load("res://tools/anubis_baker.gd").new()
	add_child(baker)
	var result: Array = await baker.finished
	if not result[0]:
		return false
	print("Importing the frames...")
	var fs := EditorInterface.get_resource_filesystem()
	var dir := FRAMES.get_base_dir()
	for i in 240:
		await get_tree().create_timer(0.5).timeout
		if fs.is_scanning():
			continue
		var pending := false
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".png") and not FileAccess.file_exists(dir.path_join(file + ".import")):
				pending = true
				break
		if not pending and ResourceLoader.exists(FRAMES):
			return true
		if i % 6 == 5:
			fs.scan()
	push_error("The Anubis frames were baked but not imported. Run this script again.")
	return false


func _refresh_editor() -> void:
	if not Engine.is_editor_hint():
		return
	EditorInterface.get_resource_filesystem().scan()
	for path in EditorInterface.get_open_scenes():
		if FileAccess.file_exists(path):
			EditorInterface.reload_scene_from_path(path)
	if FileAccess.file_exists("res://main.tscn"):
		EditorInterface.open_scene_from_path("res://main.tscn")


# Scenes

func _main() -> Control:
	var main := Control.new()
	main.name = "Main"
	_full_rect(main)
	main.set("anchors_preset", Control.PRESET_FULL_RECT)
	if step >= 8:
		main.set_script(_load("res://main.gd"))
	if step >= 9:
		main.set("wild", _texture("symbols/wild/wild.png"))

	var background: TextureRect = _add(main, TextureRect.new(), "Background", main)
	background.texture = _texture("background/background.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set("layout_mode", 1)
	_full_rect(background)

	_sprite(main, "LogoLong", "logo/logo_long.png", Vector2(1166, 138), 0.34)
	_sprite(main, "ReelFrameFilled", "reel/reel_frame_filled.png", Vector2(1170, 571), 0.55)

	if step >= 4:
		var anubis: AnimatedSprite2D = _add(main, AnimatedSprite2D.new(), "Anubis", main)
		anubis.unique_name_in_owner = true
		anubis.sprite_frames = load(FRAMES)
		anubis.animation = &"idle"
		anubis.autoplay = "idle"
		anubis.position = Vector2(382, 580)
		anubis.scale = Vector2(1.086, 1.086)
		if step >= 9:
			anubis.animation_finished.connect(Callable(main, "_on_anubis_animation_finished"), CONNECT_PERSIST)

	if step >= 7:
		var reels: HBoxContainer = _add(main, HBoxContainer.new(), "Reels", main)
		reels.unique_name_in_owner = true
		_rect(reels, Vector2(796, 357), Vector2(762, 453))
		reels.add_theme_constant_override("separation", 0)
		var reel_scene: PackedScene = _load("res://reel.tscn")
		for i in 5:
			var reel: Control = _add(reels, reel_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE), "Reel" if i == 0 else "Reel%d" % (i + 1), main)
			reel.set("layout_mode", 2)
	if step >= 8:
		var button: Button = _add(main, Button.new(), "SpinButton", main)
		button.unique_name_in_owner = true
		button.text = "SPIN"
		button.custom_minimum_size = Vector2(220, 90)
		button.add_theme_font_size_override("font_size", 44)
		_rect(button, Vector2(850, 960), Vector2(220, 90))
		if step >= 8:
			button.pressed.connect(Callable(main, "_on_spin_button_pressed"), CONNECT_PERSIST)
	return main


func _symbol() -> TextureRect:
	var symbol := TextureRect.new()
	symbol.name = "Symbol"
	symbol.texture = _texture("symbols/high/high_ankh.png")
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.custom_minimum_size = Vector2(152, 151)
	symbol.pivot_offset = Vector2(76, 75.5)
	var player: AnimationPlayer = _add(symbol, AnimationPlayer.new(), "AnimationPlayer", symbol)
	var library := AnimationLibrary.new()
	library.add_animation("RESET", _animation(0.001, ".:scale", [0.0], [Vector2.ONE]))
	library.add_animation("win", _animation(0.6, ".:scale", [0.0, 0.3, 0.6], [Vector2.ONE, Vector2(1.12, 1.12), Vector2.ONE]))
	player.add_animation_library("", library)
	return symbol


func _reel() -> Control:
	var reel := Control.new()
	reel.name = "Reel"
	reel.custom_minimum_size = Vector2(152, 453)
	reel.clip_contents = true
	reel.set_script(_load("res://reel.gd"))
	var symbols: Array[Texture2D] = []
	for file in ["high/high_ankh", "high/high_eye", "high/high_necklace", "high/high_scarab", "wild/wild"]:
		symbols.append(_texture("symbols/%s.png" % file))
	reel.set("symbols", symbols)

	var strip: VBoxContainer = _add(reel, VBoxContainer.new(), "Strip", reel)
	strip.add_theme_constant_override("separation", 0)
	strip.offset_top = -906
	strip.offset_right = 152
	strip.offset_bottom = 453
	var symbol_scene: PackedScene = _load("res://symbol.tscn")
	for i in 9:
		var symbol: Control = _add(strip, symbol_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE), "Symbol" if i == 0 else "Symbol%d" % (i + 1), reel)
		symbol.set("layout_mode", 2)

	var player: AnimationPlayer = _add(reel, AnimationPlayer.new(), "AnimationPlayer", reel)
	var library := AnimationLibrary.new()
	library.add_animation("RESET", _animation(0.001, "Strip:position", [0.0], [Vector2(0, -906)]))
	var spin := _animation(0.45, "Strip:position", [0.0, 0.45], [Vector2(0, -906), Vector2.ZERO])
	spin.loop_mode = Animation.LOOP_LINEAR
	library.add_animation("spin", spin)
	library.add_animation("stop", _animation(0.3, "Strip:position", [0.0, 0.15, 0.3], [Vector2(0, -836), Vector2(0, -926), Vector2(0, -906)]))
	player.add_animation_library("", library)
	return reel


# Helpers

func _add(parent: Node, node: Node, node_name: String, owner_node: Node) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = owner_node
	return node


func _full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


func _rect(control: Control, position: Vector2, size: Vector2) -> void:
	control.offset_left = position.x
	control.offset_top = position.y
	control.offset_right = position.x + size.x
	control.offset_bottom = position.y + size.y


func _sprite(parent: Node, node_name: String, file: String, position: Vector2, scale: float) -> void:
	var sprite: Sprite2D = _add(parent, Sprite2D.new(), node_name, parent)
	sprite.texture = _texture(file)
	sprite.position = position
	sprite.scale = Vector2(scale, scale)


func _label(parent: Node, owner_node: Node, node_name: String, text: String, align: HorizontalAlignment, settings: LabelSettings) -> void:
	var label: Label = _add(parent, Label.new(), node_name, owner_node)
	label.unique_name_in_owner = true
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.label_settings = settings
	label.custom_minimum_size = Vector2(380, 0)
	label.set("layout_mode", 2)


func _animation(length: float, path: String, times: Array, values: Array) -> Animation:
	var animation := Animation.new()
	animation.length = length
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	for i in times.size():
		animation.track_insert_key(track, times[i], values[i])
	return animation


func _texture(file: String) -> Texture2D:
	return load(PNG + file)


func _load(path: String) -> Resource:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)


func _save_scene(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	packed.pack(root)
	packed.take_over_path(path)
	ResourceSaver.save(packed, path)
	root.free()


func _save_script(code: String, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(code)
	file.close()
	var script := GDScript.new()
	script.source_code = code
	script.reload()
	script.take_over_path(path)


const REEL_CODE := """# Step 6: attach to the Reel root node (reel.gd).
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
"""

const MAIN_CODE := """# Step 8: attach to the Main root node (main.gd).
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
"""

const PAY_CODE := """# Step 9: in main.gd, replace the pay() function with this block.
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
"""
