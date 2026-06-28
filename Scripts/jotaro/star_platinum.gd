extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox_area: Area2D = $Area2D
@onready var hitbox_shape: CollisionShape2D = $Area2D/hitboxAtaque
@onready var punto_disparo: Marker2D = $Marker2D

var emerald_splash = preload("res://Scenes/personajes/jotario/EmeraldSplash.tscn")
var emerald_diagonal = preload("res://Scenes/personajes/jotario/EmeraldDiagonal.tscn")
var magicians_red = preload("res://Scenes/personajes/jotario/MagiciansRed.tscn")

var mi_layer: int = 4
var mi_mask: int = 2

var oponente: Node2D = null
var jotaro: Node2D = null 
var is_active := false

func _ready() -> void:
	sprite.visible = false
	hitbox_shape.disabled = true
	hitbox_area.body_entered.connect(_on_golpe_conectado)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)

func ejecutar_rafaga() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("rafaga")
	hitbox_player.play("rafaga")

func ejecutar_golpe() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("golpe")
	hitbox_player.play("golpe")

func ejecutar_agarre() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("agarre")
	hitbox_player.play("agarre")

func ejecutar_bloqueo() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("bloqueo")

func detener_bloqueo() -> void:
	is_active = false
	sprite.visible = false
	sprite.stop()

func ejecutar_ultimate() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("ultimate")
	hitbox_player.play("ultimate")


func ejecutar_avdul() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("avdul")
	var dir_x := -1.0 if sprite.flip_h else 1.0
	var k = magicians_red.instantiate()
	k.global_position = punto_disparo.global_position
	get_parent().add_child(k)
	var area = k.get_node("Area2D")
	if area:
		area.collision_layer = mi_layer | 16
		area.collision_mask = mi_mask | 16
	if k.has_method("inicializar"):
		k.inicializar(oponente.global_position, dir_x, 80.0, jotaro)

func ejecutar_kakyoin() -> void:
	if oponente == null:
		return
	is_active = true
	sprite.visible = true
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.play("kakyoin")
	# Igual que rafaga3 de Goku, lanza dos diagonales en frames específicos
	# Esto se maneja en _on_frame_changed

func _on_frame_changed() -> void:
	if sprite.animation == "kakyoin":
		var dir_x := -1.0 if sprite.flip_h else 1.0
		if sprite.frame == 1:
			_instanciar_emerald_recta(dir_x)
		elif sprite.frame == 2:
			_instanciar_emerald_diagonal(dir_x)

func _instanciar_emerald_recta(dir_x: float) -> void:
	var bola = emerald_splash.instantiate()
	bola.direccion = Vector2(dir_x, 0)
	bola.global_position = punto_disparo.global_position
	bola.collision_layer = mi_layer
	bola.collision_mask = mi_mask
	get_parent().add_child(bola)

func _instanciar_emerald_diagonal(dir_x: float) -> void:
	if oponente:
		var dir_x2 : float = sign(oponente.global_position.x - global_position.x)
		if dir_x2 == 0: dir_x2 = 1.0
		var bola = emerald_diagonal.instantiate()
		bola.global_position = punto_disparo.global_position
		bola.direccion = Vector2(dir_x2, 0.5).normalized()
		bola.collision_layer = mi_layer
		bola.collision_mask = mi_mask
		get_parent().add_child(bola)

func _on_golpe_conectado(body: Node) -> void:
	if body == oponente and is_active:
		match sprite.animation:
			"agarre":
				golpear_oponente_especial(40)
			"ultimate":
				golpear_oponente_especial(100)
			_:
				golpear_oponente(20)

func golpear_oponente(cantidad: float) -> void:
	if oponente and oponente.has_method("recibir_daño"):
		oponente.recibir_daño(cantidad)

func golpear_oponente_especial(cantidad: float) -> void:
	if oponente and oponente.has_method("recibir_daño_especial"):
		oponente.recibir_daño_especial(cantidad)


func _process(_delta: float) -> void:
	if jotaro == null:
		return
	var dir_to_oponente: float = sign(jotaro.oponente.global_position.x - jotaro.global_position.x)
	position.x = abs(position.x) * dir_to_oponente
	sprite.flip_h = dir_to_oponente < 0

func _on_animation_finished() -> void:
	is_active = false
	sprite.visible = false
	hitbox_shape.disabled = true
