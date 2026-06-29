extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO
var impactado: bool = false
var dueño: Node = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	sprite.play("disparo")
	sprite.animation_finished.connect(_on_animation_finished)
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	if not impactado:
		global_position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	if impactado:
		return
	if body == dueño:
		return
	if body.has_method("recibir_daño"):
		body.recibir_daño(20)
		_explotar()
	elif body is StaticBody2D:
		_explotar()

func _explotar() -> void:
	impactado = true
	colision.set_deferred("disabled", true)
	sprite.play("explosion")
	await sprite.animation_finished
	queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == "disparo":
		sprite.play("viajando")
