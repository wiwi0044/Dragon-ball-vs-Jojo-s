extends PersonajeBaseDBZ

var rafaga_scene = preload("res://Scenes/personajes/freezer/rafaga.tscn")
var laser_scene = preload("res://Scenes/personajes/freezer/Laser.tscn")
var bola_gigante_scene = preload("res://Scenes/personajes/freezer/bolaGiante.tscn")
var bola_gigante_activa: bool = false
var cargando_bola: bool = false
var tiempo_bola_presionado: float = 0.0
const TIEMPO_CARGA_BOLA: float = 1.5
var bola_precargada: Node = null
var ultima_rafaga: int = 1
var disparando: bool = false


func _ready() -> void:
	super._ready()

func _input(event: InputEvent) -> void:
	if estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2, Estado.LASER]:
		return
	if estado_actual == Estado.CHOQUE:
		if Input.is_action_just_pressed("disparar" + sufijo):
			for hijo in get_parent().get_children():
				if hijo.has_method("agregar_poder") and hijo.get("en_choque") and hijo.get("dueño") == self:
					hijo.agregar_poder(50)
					break
		return
	if estado_actual == Estado.BOLA_GIGANTE:
		if Input.is_action_just_released("disparar" + sufijo):
			cargando_bola = false
			_lanzar_bola_gigante()
		return
	super._input(event)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if cargando_bola:
		tiempo_bola_presionado += delta
		if tiempo_bola_presionado >= TIEMPO_CARGA_BOLA and estado_actual != Estado.BOLA_GIGANTE:
			if ki_actual >= 100:
				cambiar_estado(Estado.BOLA_GIGANTE)
			else:
				cargando_bola = false
				tiempo_bola_presionado = 0.0

func _input_especial(event: InputEvent) -> void:
	if Input.is_action_just_pressed("disparar" + sufijo):
		cargando_bola = true
		tiempo_bola_presionado = 0.0
	if Input.is_action_just_released("disparar" + sufijo) and cargando_bola:
		cargando_bola = false
		if ki_actual >= 15:
			_lanzar_rafaga()
		tiempo_bola_presionado = 0.0
	if Input.is_action_just_pressed("especial1" + sufijo):
		if ki_actual >= 30:
			ki_actual -= 30
			_lanzar_laser()


func _on_cambiar_estado(nuevo_estado: Estado) -> void:
	match nuevo_estado:
		Estado.IDLE:
			sprite.play("default")
		Estado.ADELANTE:
			sprite.play("adelante")
		Estado.ATRAS:
			sprite.play("atras")
		Estado.BAJAR:
			sprite.play("bajar")
		Estado.RAPIDO_ADELANTE:
			sprite.play("rapidoAdelante")
		Estado.GOLPE1:
			sprite.play("golpe1")
			anim_player.play("golpe1")
		Estado.GOLPE2:
			anim_player.stop()
			sprite.play("golpe2")
			anim_player.play("golpe2")
		Estado.GOLPE3:
			sprite.play("golpe3")
			anim_player.play("golpe3")
		Estado.PATADA1:
			sprite.play("patada1")
			anim_player.play("patada1")
		Estado.RAFAGA1:
			sprite.play("rafaga1")
		Estado.RAFAGA2:
			sprite.play("rafaga2")
		Estado.LASER:
			sprite.play("laser")
		Estado.BOLA_GIGANTE:
			sprite.play("bolaGigante")
			sprite.pause()
			sprite.frame = 0
			bola_precargada = bola_gigante_scene.instantiate()
			get_parent().add_child(bola_precargada)
			bola_precargada.global_position = punto_disparo.global_position + Vector2(0, -100)
			bola_precargada.dueño = self
		_:
			super._on_cambiar_estado(nuevo_estado)

var bola_lista: bool = false

func _on_bola_carga_completa() -> void:
	bola_lista = true

func _on_animation_finished() -> void:
	if estado_actual == Estado.PATADA1:
		hitbox_shape.disabled = true
		siguiente_patada = 0
		cambiar_estado(Estado.IDLE)
		return
	if estado_actual == Estado.RAFAGA1 or estado_actual == Estado.RAFAGA2:
		disparando = false
	if estado_actual == Estado.LASER:
		disparando = false
		sprite.rotation = 0.0
		cambiar_estado(Estado.IDLE)
		return
	if estado_actual == Estado.BOLA_GIGANTE:
			if sprite.animation == "bolaGiganteCarga":
				sprite.pause()
				sprite.frame = sprite.sprite_frames.get_frame_count("bolaGiganteCarga") - 1
				bola_lista = true
			return
	super._on_animation_finished()

func _lanzar_rafaga() -> void:
	disparando = true
	ki_actual -= 15
	if ultima_rafaga == 1:
		ultima_rafaga = 2
		cambiar_estado(Estado.RAFAGA1)
	else:
		ultima_rafaga = 1
		cambiar_estado(Estado.RAFAGA2)
	var dir = punto_disparo.global_position.direction_to(oponente.global_position)
	sprite.rotation = dir.angle()
	if sprite.scale.x < 0:
		sprite.rotation += PI
	
	var r = rafaga_scene.instantiate()
	r.global_position = punto_disparo.global_position
	r.direccion = dir
	r.dueño = self
	if sufijo == "J1":
		r.collision_layer = 16  # layer 5
		r.collision_mask = 2    # detecta jugador2
	else:
		r.collision_layer = 32  # layer 6
		r.collision_mask = 1    # detecta jugador1
	get_parent().add_child(r)
	
func _lanzar_laser() -> void:
	disparando = true
	var dir = punto_disparo.global_position.direction_to(oponente.global_position)
	sprite.rotation = dir.angle()
	if sprite.scale.x < 0:
		sprite.rotation += PI
	cambiar_estado(Estado.LASER)
	var l = laser_scene.instantiate()
	l.dueño = self
	get_parent().add_child(l)
	l.inicializar(punto_disparo.global_position, oponente.global_position)

func _lanzar_bola_gigante() -> void:
	if bola_precargada == null:
		cambiar_estado(Estado.IDLE)
		return
	if ki_actual < 100:
		bola_precargada.queue_free()
		bola_precargada = null
		cambiar_estado(Estado.IDLE)
		return
	ki_actual -= 100
	bola_gigante_activa = true
	sprite.frame = 1
	sprite.play("bolaGigante")
	if sufijo == "J1":
		bola_precargada.collision_layer = 16
		bola_precargada.collision_mask = 2 | 4 | 16
	else:
		bola_precargada.collision_layer = 32
		bola_precargada.collision_mask = 1 | 4 | 16
	bola_precargada.inicializar(oponente.global_position, sprite.scale.x, 100.0, self)
	bola_precargada = null

func bola_gigante_termino() -> void:
	bola_gigante_activa = false
	cambiar_estado(Estado.IDLE)
	
func entrar_choque_kamehameha() -> void:
	cambiar_estado(Estado.CHOQUE)

func orientar_a_oponente() -> void:
	if disparando:
		return
	super.orientar_a_oponente()
