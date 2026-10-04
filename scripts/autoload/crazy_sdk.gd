extends Node
## Thin wrapper around the CrazyGames HTML5 SDK v3.
##
## The JavaScript side (window.CGBridge) is injected through the export preset's
## head include, see export_presets.cfg. Outside the web build, or when the SDK
## is unavailable, every call is a harmless no-op and ads finish immediately.

signal ad_finished(ok: bool)

var _bridge: JavaScriptObject
var _ad_callback: JavaScriptObject
var _gameplay := false
var _ad_running := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		_bridge = JavaScriptBridge.get_interface("CGBridge")
		_ad_callback = JavaScriptBridge.create_callback(_on_ad_done)


func is_available() -> bool:
	return _bridge != null and bool(_bridge.ok())


func environment() -> String:
	return str(_bridge.env) if _bridge else "none"


func loading_stop() -> void:
	if _bridge:
		_bridge.loadingStop()


## Call when the player is actively playing (not in menus or pause screens).
func gameplay_start() -> void:
	if _gameplay:
		return
	_gameplay = true
	if _bridge:
		_bridge.gameplayStart()


func gameplay_stop() -> void:
	if not _gameplay:
		return
	_gameplay = false
	if _bridge:
		_bridge.gameplayStop()


## A celebratory moment, e.g. finishing a job.
func happytime() -> void:
	if _bridge:
		_bridge.happytime()


## Shows a midgame ad when possible. Pauses the game and mutes audio while it
## plays. Always emits ad_finished, even when no ad is shown.
func request_midgame_ad() -> void:
	_request_ad("midgame")


func request_rewarded_ad() -> void:
	_request_ad("rewarded")


func _request_ad(kind: String) -> void:
	if _ad_running:
		return
	if not is_available():
		ad_finished.emit.call_deferred(kind == "midgame")
		return
	_ad_running = true
	var was_playing := _gameplay
	gameplay_stop()
	get_tree().paused = true
	Sfx.set_muted(true)
	set_meta("resume_gameplay", was_playing)
	_bridge.requestAd(kind, _ad_callback)


func _on_ad_done(args: Array) -> void:
	_ad_running = false
	get_tree().paused = false
	Sfx.set_muted(false)
	if get_meta("resume_gameplay", false):
		gameplay_start()
	var result := str(args[0]) if args.size() > 0 else "error"
	ad_finished.emit(result == "finished")
