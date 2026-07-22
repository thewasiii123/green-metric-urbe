# ============================================================
# WindowManager.gd — URBE Rangers: Eco-Quest
# Autoload global. F11 = pantalla completa / ventana.
# Usa _input (no _unhandled_input) para garantizar la captura
# del evento aunque otro nodo lo haya procesado primero.
# ============================================================
extends Node


func _ready() -> void:
	# Forzar ventana maximizada al arrancar si no está ya en fullscreen
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey): return
	if not event.pressed or event.echo: return

	if event.keycode == KEY_F11:
		get_viewport().set_input_as_handled()
		_toggle_fullscreen()

	elif (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER) \
			and event.alt_pressed:
		get_viewport().set_input_as_handled()
		_toggle_fullscreen()


func _toggle_fullscreen() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func esta_en_fullscreen() -> bool:
	var modo := DisplayServer.window_get_mode()
	return modo == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
