@tool
extends Node
## Renders the Anubis Spine animations from the Crowns of Kemet pack into PNG
## frames and a SpriteFrames resource, using the default web browser.
## Using a Spine runtime requires your own Spine Editor license.

signal finished(ok: bool, message: String)

const RUNTIME_URL := "https://raw.githubusercontent.com/EsotericSoftware/spine-runtimes/3.8/spine-ts/build/spine-webgl.js"
const PORT := 8791
const TIMEOUT_MS := 120000

var pack_dir := ""
var out_dir := "res://art/anubis"
var fps := 30
var open_browser := true

var _server := TCPServer.new()
var _clients: Array[Dictionary] = []
var _files := {}
var _saved := 0
var _started := 0
var _last_activity := 0


func _ready() -> void:
	if pack_dir.is_empty():
		_ask_for_pack()
	else:
		_start()


func _ask_for_pack() -> void:
	var dialog := FileDialog.new()
	dialog.title = "Select the Crowns of Kemet pack folder"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.dir_selected.connect(func(dir: String) -> void:
		pack_dir = dir
		_start())
	dialog.canceled.connect(func() -> void: _finish(false, "Canceled."))
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


func _start() -> void:
	_started = Time.get_ticks_msec()
	var spine_dir := pack_dir.path_join("Spine").path_join("character_anubis")
	for ext in ["json", "atlas", "png"]:
		var path := spine_dir.path_join("character_anubis." + ext)
		if not FileAccess.file_exists(path):
			_finish(false, "Missing %s. Select the pack root folder." % path)
			return
		_files["/data/character_anubis." + ext] = FileAccess.get_file_as_bytes(path)

	var out := ProjectSettings.globalize_path(out_dir)
	DirAccess.make_dir_recursive_absolute(out)
	for file in DirAccess.get_files_at(out):
		if file.ends_with(".png") or file.ends_with(".png.import") or file == "anubis_frames.tres":
			DirAccess.remove_absolute(out.path_join(file))

	print("Downloading the Spine 3.8 web runtime...")
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_runtime_downloaded)
	http.request(RUNTIME_URL)


func _on_runtime_downloaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish(false, "Could not download the Spine runtime (HTTP %d)." % code)
		return
	_files["/spine-webgl.js"] = body
	_files["/"] = PAGE.replace("__FPS__", str(fps)).replace("__RES__", out_dir).to_utf8_buffer()
	if _server.listen(PORT, "127.0.0.1") != OK:
		_finish(false, "Port %d is busy." % PORT)
		return
	_last_activity = Time.get_ticks_msec()
	var url := "http://127.0.0.1:%d/" % PORT
	print("Rendering frames in the browser: ", url)
	if open_browser:
		OS.shell_open(url)


func _process(_delta: float) -> void:
	if not _server.is_listening():
		return
	while _server.is_connection_available():
		_clients.append({"peer": _server.take_connection(), "buffer": PackedByteArray(), "header_end": -1})
	for client in _clients.duplicate():
		if _read(client):
			_clients.erase(client)
	if _server.is_listening() and Time.get_ticks_msec() - _last_activity > TIMEOUT_MS:
		_finish(false, "No response from the browser in %d seconds." % (TIMEOUT_MS / 1000))


# Reads one HTTP request from the client. Returns true once it was answered.
func _read(client: Dictionary) -> bool:
	var peer: StreamPeerTCP = client.peer
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return true
	var available := peer.get_available_bytes()
	if available > 0:
		client.buffer.append_array(peer.get_data(available)[1])
		_last_activity = Time.get_ticks_msec()
	var buffer: PackedByteArray = client.buffer
	if client.header_end < 0:
		client.header_end = _find_header_end(buffer)
		if client.header_end < 0:
			return false
	var lines := buffer.slice(0, client.header_end).get_string_from_utf8().split("\r\n")
	var length := 0
	for line in lines:
		if line.to_lower().begins_with("content-length:"):
			length = line.get_slice(":", 1).strip_edges().to_int()
	var body_start: int = client.header_end + 4
	if buffer.size() < body_start + length:
		return false
	var request := lines[0].split(" ")
	_handle(peer, request[0], request[1], buffer.slice(body_start, body_start + length))
	peer.disconnect_from_host()
	return true


func _find_header_end(buffer: PackedByteArray) -> int:
	for i in mini(buffer.size(), 8192) - 3:
		if buffer[i] == 13 and buffer[i + 1] == 10 and buffer[i + 2] == 13 and buffer[i + 3] == 10:
			return i
	return -1


func _handle(peer: StreamPeerTCP, method: String, target: String, body: PackedByteArray) -> void:
	var path := target.get_slice("?", 0)
	var query := target.get_slice("?", 1)
	if method == "GET":
		if _files.has(path):
			_respond(peer, 200, _files[path])
		else:
			_respond(peer, 404, PackedByteArray())
		return
	match path:
		"/save":
			var name := query.trim_prefix("name=").uri_decode().get_file()
			var file := FileAccess.open(ProjectSettings.globalize_path(out_dir).path_join(name), FileAccess.WRITE)
			file.store_buffer(body)
			file.close()
			if name.ends_with(".png"):
				_saved += 1
				if _saved % 20 == 0:
					print("  %d frames" % _saved)
		"/log":
			print("  ", body.get_string_from_utf8())
		"/done":
			_finish(true, "Done: %d frames and anubis_frames.tres in %s (%d s)." % [_saved, out_dir, (Time.get_ticks_msec() - _started) / 1000])
		"/fail":
			_finish(false, "Rendering failed: " + body.get_string_from_utf8())
	_respond(peer, 200, PackedByteArray())


func _respond(peer: StreamPeerTCP, status: int, body: PackedByteArray) -> void:
	var header := "HTTP/1.1 %d %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [status, "OK" if status == 200 else "Not Found", body.size()]
	peer.put_data(header.to_utf8_buffer())
	if not body.is_empty():
		peer.put_data(body)


func _finish(ok: bool, message: String) -> void:
	_server.stop()
	if ok:
		print(message)
	else:
		push_error(message)
	var editor: Object = Engine.get_singleton("EditorInterface") if Engine.is_editor_hint() else null
	if editor:
		editor.get_resource_filesystem().scan()
	finished.emit(ok, message)
	if editor:
		queue_free()


const PAGE := """<!doctype html><html><head><meta charset="utf-8"><title>Anubis baker</title>
<script src="spine-webgl.js"></script></head>
<body style="font:16px sans-serif;background:#222;color:#eee;padding:24px"><p id="status">Rendering...</p><script>
const FPS = __FPS__, RES = "__RES__";
const post = (path, body) => fetch(path, {method: "POST", body});
const status = m => { document.getElementById("status").textContent = m; };
const log = m => { status(m); return post("/log", m); };
async function run() {
  const canvas = document.createElement("canvas");
  const ctx = new spine.webgl.ManagedWebGLRenderingContext(canvas, {alpha: true, premultipliedAlpha: true, preserveDrawingBuffer: true});
  const gl = ctx.gl;
  gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  const assets = new spine.webgl.AssetManager(ctx);
  assets.loadTextureAtlas("data/character_anubis.atlas");
  assets.loadText("data/character_anubis.json");
  while (!assets.isLoadingComplete()) {
    if (assets.hasErrors()) throw new Error(JSON.stringify(assets.getErrors()));
    await new Promise(r => setTimeout(r, 20));
  }
  const json = new spine.SkeletonJson(new spine.AtlasAttachmentLoader(assets.get("data/character_anubis.atlas")));
  const data = json.readSkeletonData(assets.get("data/character_anubis.json"));
  const skeleton = new spine.Skeleton(data);
  const state = new spine.AnimationState(new spine.AnimationStateData(data));
  const renderer = new spine.webgl.SceneRenderer(canvas, ctx, true);
  const anims = data.animations.map(a => ({name: a.name, frames: Math.round(a.duration * FPS)}));
  const pose = (name, t) => {
    skeleton.setToSetupPose(); state.clearTracks(); state.setAnimation(0, name, true);
    state.update(t); state.apply(skeleton); skeleton.updateWorldTransform();
  };

  let minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
  const off = new spine.Vector2(), size = new spine.Vector2();
  for (const a of anims) for (let f = 0; f < a.frames; f++) {
    pose(a.name, f / FPS); skeleton.getBounds(off, size, []);
    minX = Math.min(minX, off.x); minY = Math.min(minY, off.y);
    maxX = Math.max(maxX, off.x + size.x); maxY = Math.max(maxY, off.y + size.y);
  }
  const W = Math.ceil(maxX - minX) + 2, H = Math.ceil(maxY - minY) + 2;
  canvas.width = W; canvas.height = H;
  const draw = (name, f) => {
    pose(name, f / FPS);
    gl.viewport(0, 0, W, H); gl.clearColor(0, 0, 0, 0); gl.clear(gl.COLOR_BUFFER_BIT);
    renderer.camera.position.x = minX + W / 2; renderer.camera.position.y = minY + H / 2;
    renderer.camera.setViewport(W, H);
    renderer.begin(); renderer.drawSkeleton(skeleton, true); renderer.end();
  };

  // Crop every frame to the union of the visible pixels.
  let x0 = W, y0 = H, x1 = 0, y1 = 0;
  const pixels = new Uint8Array(W * H * 4);
  for (const a of anims) for (let f = 0; f < a.frames; f++) {
    draw(a.name, f);
    gl.readPixels(0, 0, W, H, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
      if (pixels[(y * W + x) * 4 + 3] > 0) {
        const top = H - 1 - y;
        if (x < x0) x0 = x; if (x > x1) x1 = x; if (top < y0) y0 = top; if (top > y1) y1 = top;
      }
    }
  }
  const cw = x1 - x0 + 1, ch = y1 - y0 + 1;
  const crop = document.createElement("canvas"); crop.width = cw; crop.height = ch;
  const c2d = crop.getContext("2d");
  await log(`Rendering ${anims.map(a => a.name + " (" + a.frames + " frames)").join(", ")} at ${cw}x${ch}`);

  const ext = [], sections = [];
  for (const a of anims) {
    const refs = [];
    for (let f = 0; f < a.frames; f++) {
      draw(a.name, f);
      c2d.clearRect(0, 0, cw, ch);
      c2d.drawImage(canvas, x0, y0, cw, ch, 0, 0, cw, ch);
      const name = `${a.name}_${String(f).padStart(3, "0")}.png`;
      await post(`/save?name=${name}`, await new Promise(r => crop.toBlob(r, "image/png")));
      ext.push(`[ext_resource type="Texture2D" path="${RES}/${name}" id="${ext.length + 1}"]`);
      refs.push(`{\\n"duration": 1.0,\\n"texture": ExtResource("${ext.length}")\\n}`);
      status(`${a.name}: frame ${f + 1} of ${a.frames}`);
    }
    sections.push(`{\\n"frames": [${refs.join(", ")}],\\n"loop": ${a.name === "idle"},\\n"name": &"${a.name}",\\n"speed": ${FPS}.0\\n}`);
  }
  const tres = `[gd_resource type="SpriteFrames" load_steps=${ext.length + 1} format=3]\\n\\n${ext.join("\\n")}\\n\\n[resource]\\nanimations = [${sections.join(", ")}]\\n`;
  await post("/save?name=anubis_frames.tres", tres);
  await post("/done", "");
  status("Done. You can close this tab.");
}
run().catch(e => { status("Failed: " + e); post("/fail", String(e && e.stack || e)); });
</script></body></html>
"""
