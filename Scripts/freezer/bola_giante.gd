extends Area2D
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D
var pos_inicial: Vector2 = Vector2.ZERO
var pos_choque: Vector2 = Vector2.ZERO
var daño_total: float = 100.0
var velocidad: float = 300.0
var impactado: bool = false
var dueño: Node = null
var direccion: Vector2 = Vector2.ZERO
var en_choque: bool = false
var rival: Node = null
var punto_choque: float = 0.5
var velocidad_choque: float = 0.05
var choque_resuelto: bool = false

func _ready() -> void:
	sprite.play("bolaGiganteCarga")
	sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if sprite.animation == "bolaGiganteCarga":
		sprite.pause()
		sprite.frame = sprite.sprite_frames.get_frame_count("bolaGiganteCarga") - 1
	elif sprite.animation == "explosion":
		if dueño and dueño.has_method("bola_gigante_termino"):
			dueño.bola_gigante_termino()
		queue_free()

func inicializar(oponente_pos: Vector2, p_dir_x: float, daño: float, p_dueño: Node = null) -> void:
	daño_total = daño
	dueño = p_dueño
	direccion = global_position.direction_to(oponente_pos)
	rotation = direccion.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	sprite.play("bolaBucle")
	
	
func _physics_process(delta: float) -> void:
	if impactado:
		return
	
	if en_choque and rival:
		punto_choque = move_toward(punto_choque, 0.5, velocidad_choque * delta)
		if not choque_resuelto:
			var rival_dueño = rival.get("dueño")
			var pos_freezer = dueño.global_position if dueño else pos_inicial
			var pos_goku = rival_dueño.global_position if rival_dueño else rival.global_position
			var avance = clamp(punto_choque, 0.1, 0.9)
			global_position = pos_freezer.lerp(pos_goku, avance)
			if punto_choque >= 0.9:
				var pelea = get_parent()
				if pelea and pelea.has_method("detener_temblor"):
					pelea.detener_temblor()
				choque_resuelto = true
				if dueño and dueño.get("oponente"):
					dueño.oponente.recibir_daño_especial(240)
				if rival:
					rival.choque_resuelto = true
					rival.en_choque = false
					rival.rival = null
					rival.queue_free()
				_explotar()
			elif punto_choque <= 0.1:
				var pelea = get_parent()
				if pelea and pelea.has_method("detener_temblor"):
					pelea.detener_temblor()
				choque_resuelto = true
				if dueño and dueño.has_method("bola_gigante_termino"):
					dueño.bola_gigante_termino()
				if rival:
					rival.choque_resuelto = true
					rival.en_choque = false
					rival.rival = null
				queue_free()
		return
	global_position += direccion * velocidad * delta

func _on_area_entered(otra_area: Area2D) -> void:
	var pelea = get_parent()
	if pelea and pelea.has_method("temblar_camara"):
		pelea.temblar_camara(8.0, 0.4)
	if impactado or en_choque:
		return
	var otro = otra_area
	if not otro.has_method("agregar_poder"):
		otro = otra_area.get_parent()
	if otro == self:
		return
	if otro.has_method("agregar_poder"):
		en_choque = true
		rival = otro
		otro.en_choque = true
		otro.rival = self
		punto_choque = 0.4
		otro.punto_choque = 0.6
		pos_inicial = global_position
		if dueño and dueño.has_method("entrar_choque_kamehameha"):
			dueño.entrar_choque_kamehameha()
			if pelea and pelea.has_method("iniciar_temblor"):
				pelea.iniciar_temblor(6.0)
		var rival_dueño = otro.get("dueño")
		if rival_dueño and rival_dueño.has_method("entrar_choque_kamehameha"):
			rival_dueño.entrar_choque_kamehameha()

func _on_body_entered(body: Node) -> void:
	if impactado: return
	if en_choque: return
	if body == dueño: return
	if rival and rival.get("dueño") == body: return
	if body.has_method("recibir_daño_especial"):
		impactado = true
		body.recibir_daño_especial(120)
		_explotar()
	elif body is StaticBody2D:
		_explotar()

func agregar_poder(cantidad: float) -> void:
	if en_choque:
		var fuerza_click: float = 0.04
		punto_choque = clamp(punto_choque + fuerza_click, 0.0, 1.0)
		if rival:
			rival.punto_choque = clamp(rival.punto_choque - fuerza_click, 0.0, 1.0)

func _explotar() -> void:
	z_index = 10
	impactado = true
	colision.set_deferred("disabled", true)
	audio.stream = preload("res://Assets/Luchadores/goku/sonidos/explosion.wav")
	audio.play()
	sprite.play("explosion")
	await sprite.animation_finished
	if dueño and dueño.has_method("bola_gigante_termino"):
		dueño.bola_gigante_termino()
	queue_free()
