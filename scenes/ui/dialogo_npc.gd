# ============================================================
# dialogo_npc.gd - URBE Rangers: Eco-Quest
# UI de dialogo: panel inferior que muestra texto del NPC.
# ============================================================
extends CanvasLayer

@onready var nombre_label : Label = $Panel/NombreLabel
@onready var texto_label  : Label = $Panel/TextoLabel
@onready var hint_label   : Label = $Panel/HintLabel

var _dialogos : PackedStringArray = []
var _indice   : int = 0


func _ready() -> void:
	add_to_group("ui_dialogo")
	hide()


func iniciar(nombre_npc: String, textos: PackedStringArray) -> void:
	_dialogos = textos
	_indice   = 0
	nombre_label.text = nombre_npc
	_mostrar_linea()
	show()


func _mostrar_linea() -> void:
	texto_label.text = _dialogos[_indice]
	var es_ultimo    = (_indice >= _dialogos.size() - 1)
	hint_label.text  = "[E] Cerrar" if es_ultimo else "[E] Continuar"


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interactuar"):
		_indice += 1
		if _indice >= _dialogos.size():
			hide()
			_indice = 0
		else:
			_mostrar_linea()
		get_viewport().set_input_as_handled()