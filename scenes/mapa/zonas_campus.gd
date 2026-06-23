# ============================================================
# ZonasCampus.gd
# Detecta cuando el jugador entra a cada zona del campus URBE
# y emite señal con el módulo GreenMetric correspondiente.
# Posiciones basadas en el diseño aprobado del mapa.
# ============================================================
extends Node2D

# Mapeo zona → módulo GreenMetric
const ZONAS : Dictionary = {
	"ZonaEstacionamiento" : {"modulo_id": 5, "nombre": "Transporte",                  "color": Color(0.24, 0.36, 0.40)},
	"ZonaCafetin"         : {"modulo_id": 3, "nombre": "Gestión de Residuos",         "color": Color(0.60, 0.43, 0.06)},
	"ZonaBiblioteca"      : {"modulo_id": 4, "nombre": "Agua",                         "color": Color(0.04, 0.41, 0.50)},
	"ZonaBloqueE"         : {"modulo_id": 1, "nombre": "Entorno e Infraestructura",   "color": Color(0.75, 0.44, 0.16)},
	"ZonaBloqueF"         : {"modulo_id": 1, "nombre": "Entorno e Infraestructura",   "color": Color(0.75, 0.44, 0.16)},
	"ZonaPlazaCentral"    : {"modulo_id": 1, "nombre": "Entorno e Infraestructura",   "color": Color(0.16, 0.48, 0.10)},
	"ZonaBloques_ABCD"    : {"modulo_id": 2, "nombre": "Energía y Cambio Climático",  "color": Color(0.75, 0.44, 0.16)},
	"ZonaRectorado"       : {"modulo_id": 6, "nombre": "Educación e Investigación",   "color": Color(0.10, 0.26, 0.60)},
	"ZonaServicios"       : {"modulo_id": 6, "nombre": "Educación e Investigación",   "color": Color(0.12, 0.12, 0.23)},
}

# Señal que recibe el mapa cuando el jugador entra a una zona
signal zona_activada(modulo_id: int, nombre_modulo: String, color: Color)
signal zona_salida()


func _ready() -> void:
	# Conectar señales de entrada/salida de cada zona
	for nombre_zona in ZONAS.keys():
		var zona = get_node_or_null(nombre_zona)
		if zona == null:
			print("⚠ Zona no encontrada: " + nombre_zona)
			continue
		zona.body_entered.connect(_on_zona_entered.bind(nombre_zona))
		zona.body_exited.connect(_on_zona_exited.bind(nombre_zona))
		print("✅ Zona conectada: " + nombre_zona)


func _on_zona_entered(cuerpo: Node, nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	var datos = ZONAS[nombre_zona]
	print("🏛 Entrando: " + nombre_zona + " → " + datos["nombre"])
	emit_signal("zona_activada", datos["modulo_id"], datos["nombre"], datos["color"])


func _on_zona_exited(cuerpo: Node, nombre_zona: String) -> void:
	if not cuerpo.is_in_group("jugador"):
		return
	emit_signal("zona_salida")
