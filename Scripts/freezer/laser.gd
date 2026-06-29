extends Node2D


var daño: float = 15.0
var dueño: Node = null

@onready var linea: Line2D = $Linea
@onready var borde: Line2D = $LineaBorde

func inicializar(origen: Vector2, destino: Vector2) -> void:
	global_position = origen + Vector2(11,0) 
	var punto_fin = to_local(destino)
	
	borde.add_point(Vector2.ZERO)
	borde.add_point(punto_fin)
	borde.width = 9.0
	borde.default_color = Color("#ed1c24")
	
	linea.add_point(Vector2.ZERO)
	linea.add_point(punto_fin)
	linea.width = 5.0
	linea.default_color = Color("#ffe0e0")
	
	if dueño.oponente and dueño.oponente.has_method("recibir_daño"):
		dueño.oponente.recibir_daño(daño)
	
	await get_tree().create_timer(0.2).timeout
	queue_free()
