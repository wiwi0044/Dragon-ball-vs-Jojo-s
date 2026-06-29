extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO
var impactado: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	sprite.play("default")
	body_entered.connect(_on_body_entered)
	colision.position = Vector2(20, 10)
	if direccion.x < 0:
		sprite.flip_h = true
		colision.position = Vector2(-20, 10)

func _physics_process(delta: float) -> void:
	if not impactado:
		global_position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	if impactado:
		return
	if body.has_method("recibir_daño"):
		body.recibir_daño(15)
		_explotar()
	elif body is TileMap or body is StaticBody2D:
		_explotar()

func _explotar() -> void:
	impactado = true
	colision.set_deferred("disabled", true)
	queue_free()
