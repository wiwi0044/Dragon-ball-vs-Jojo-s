extends Node2D

@onready var escenario: Sprite2D = $Sprite2D
@onready var jotaro: CharacterBody2D = $Jotaro


var limite_min: Vector2
var limite_max: Vector2

func _ready() -> void:
	_calcular_limites()

func _calcular_limites() -> void:
	# Obtiene el tamano de la textura del Sprite2D
	var textura = escenario.texture
	if textura == null:
		push_error("El Sprite2D no tiene textura asignada.")
		return

	var tamano = textura.get_size() * escenario.scale
	var origen = escenario.global_position

	# Por defecto Sprite2D centra la textura en su posicion
	# Si tienes centered = true (default):
	limite_min = origen - tamano / 2
	limite_max = origen + tamano / 2

func _process(_delta: float) -> void:
	_aplicar_limites()



func _aplicar_limites() -> void:
	jotaro.global_position.x = clamp(
		jotaro.global_position.x,
		limite_min.x,
		limite_max.x
	)
	jotaro.global_position.y = clamp(
		jotaro.global_position.y,
		limite_min.y,
		limite_max.y
	)
