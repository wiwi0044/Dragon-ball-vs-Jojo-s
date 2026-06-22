extends Area2D

@export var velocidad: float = 600.0
var direccion: Vector2 = Vector2.ZERO
var impactado: bool = false
var en_vuelo: bool = false


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	sprite.play("lanzamiento")
	body_entered.connect(_on_body_entered)
	sprite.animation_finished.connect(_on_animation_finished)
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
	en_vuelo = false
	colision.set_deferred("disabled", true)
	if sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.disconnect(_on_animation_finished)
	sprite.play("explosion")
	
	await sprite.animation_finished
	queue_free()

func _on_animation_finished() -> void:
	if sprite.animation == "lanzamiento":
		sprite.play("viajando")
	elif sprite.animation == "explosion":
		queue_free()
