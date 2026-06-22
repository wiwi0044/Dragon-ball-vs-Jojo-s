extends Node2D

@onready var inicio: Sprite2D = $SpriteInicio
@onready var medio: Sprite2D = $SpriteMedio
@onready var fin: Sprite2D = $SpriteFin
@onready var explosion: AnimatedSprite2D = $SpriteExplosion
@onready var colision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area: Area2D = $Area2D

var ancho_inicio: float = 80.0
var ancho_medio_base: float = 10.0
var ancho_fin: float = 80.0
var daño_total: float = 80.0
var impactado: bool = false
var velocidad: float = 450.0
var distancia_objetivo: float = 0.0
var largo_medio_actual: float = 0.0
var dir_x: float = 1.0

func inicializar(oponente_pos: Vector2, p_dir_x: float, daño: float) -> void:
	daño_total = daño
	dir_x = p_dir_x
	scale.x = dir_x
	explosion.visible = false

	var direccion := (oponente_pos - global_position).normalized()
	rotation = direccion.angle()
	if dir_x < 0:
		rotation += PI

	distancia_objetivo = global_position.distance_to(oponente_pos)
	largo_medio_actual = ancho_medio_base

	explosion.animation_finished.connect(_on_explosion_finished)
	area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if impactado:
		return

	largo_medio_actual = min(largo_medio_actual + velocidad * delta, distancia_objetivo - ancho_fin)
	largo_medio_actual = max(largo_medio_actual, ancho_medio_base)

	medio.scale.x = largo_medio_actual / medio.texture.get_width()
	medio.position.x = ancho_inicio + largo_medio_actual / 2.0
	fin.position.x = ancho_inicio + largo_medio_actual

	var ancho_total: float = ancho_inicio + largo_medio_actual + ancho_fin
	(colision.shape as RectangleShape2D).size = Vector2(ancho_total, 40)
	colision.position.x = ancho_total / 2.0
	explosion.position.x = ancho_total

	if largo_medio_actual >= distancia_objetivo - ancho_fin:
		_explotar()

func _on_body_entered(body: Node) -> void:
	if impactado: return
	if body.has_method("recibir_daño_especial"):
		impactado = true
		body.recibir_daño_especial(daño_total)
		_explotar()

func _explotar() -> void:
	impactado = true
	inicio.visible = false
	medio.visible = false
	fin.visible = false
	colision.set_deferred("disabled", true)
	explosion.visible = true
	explosion.play("explosion")

func _on_explosion_finished() -> void:
	queue_free()

func destruir() -> void:
	queue_free()
