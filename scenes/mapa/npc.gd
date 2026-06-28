# ============================================================
# npc.gd - URBE Rangers: Eco-Quest
# NPC base: detecta proximidad del jugador y lanza dialogo.
# ============================================================
extends Area2D

@export var nombre_npc   : String           = "NPC"
@export var mision_id    : String           = ""
@export var dialogos     : PackedStringArray = PackedStringArray(["Hola."])

signal mision_iniciada(id: String)


func _ready() -> void:
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(body: Node) -> void:
	if body.is_in_group("jugador"):
		body.npc_cercano = self


func _al_salir(body: Node) -> void:
	if body.is_in_group("jugador") and body.npc_cercano == self:
		body.npc_cercano = null


func iniciar_dialogo() -> void:
	var ui = get_tree().get_first_node_in_group("ui_dialogo")
	if ui:
		ui.iniciar(nombre_npc, dialogos)
		if mision_id != "":
			mision_iniciada.emit(mision_id)