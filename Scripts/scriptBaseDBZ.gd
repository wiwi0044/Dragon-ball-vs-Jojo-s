class_name PersonajeBaseDBZ
extends CharacterBody2D

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

var sonidos = {
	"golpe1": preload("res://Assets/Luchadores/goku/sonidos/golpe1.wav"),
	"golpe2": preload("res://Assets/Luchadores/goku/sonidos/golpe2.wav"),
	"patada": preload("res://Assets/Luchadores/goku/sonidos/patada.wav"),
	"patada2": preload("res://Assets/Luchadores/goku/sonidos/patada2.wav"),
	"disparo": preload("res://Assets/Luchadores/goku/sonidos/disparo.wav"),
	"disparo2": preload("res://Assets/Luchadores/goku/sonidos/disparo2.wav"),
	"explosion": preload("res://Assets/Luchadores/goku/sonidos/explosion.wav"),
	"cubrirse": preload("res://Assets/Luchadores/goku/sonidos/cubierto.wav"),
	"cubrirse2": preload("res://Assets/Luchadores/goku/sonidos/cubrirse2.wav"),
	"cubrirse3": preload("res://Assets/Luchadores/goku/sonidos/curbirse3.wav"),
	"movimiento_rapido": preload("res://Assets/Luchadores/goku/sonidos/movimientoRapido.wav"),
	"movimiento_rapido2": preload("res://Assets/Luchadores/goku/sonidos/movimientoRapido2.wav"),
	"bola_freezer": preload("res://Assets/Luchadores/goku/sonidos/bolaFreezer.wav"),
	"bola_viajando": preload("res://Assets/Luchadores/goku/sonidos/bolaViajando.wav"),
	"inicio_carga": preload("res://Assets/Luchadores/goku/sonidos/inicioCarga.wav"),
	"bucle_carga": preload("res://Assets/Luchadores/goku/sonidos/bucleCarga.wav"),
	"laser": preload("res://Assets/Luchadores/goku/sonidos/laser.wav")
}

enum Estado { INTRO, IDLE, ADELANTE, ATRAS, VOLAR, BAJAR, 
	RAPIDO_ADELANTE, RAPIDO_ATRAS, RAPIDO_VOLAR, RAPIDO_BAJAR,
	GOLPE1, GOLPE2, GOLPE3, PATADA1, PATADA2, RAFAGA1, RAFAGA2,
	RECARGAR, CUBRIRSE, DERROTADO, GOLPEADO, MUY_GOLPEADO, LASER, BOLA_GIGANTE, CHOQUE}
var estado_actual: Estado = Estado.INTRO
var estado_previo: Estado = Estado.IDLE
var sufijo: String = "J1"
var tiempo_ultimo_tap := {}
const TIEMPO_DOBLE_TAP := 0.3
var siguiente_golpe: int = 0
var siguiente_patada: int = 0

@export var barra_vida: ProgressBar
var vida_total_actual: float = 500.0
@export var vida_total_maxima: float = 500.0

@export var barra_ki: ProgressBar
@export var ki_maximo: float = 300.0
var ki_actual: float = 100.0
@export var velocidad_recarga: float = 30.0

var daño_reciente: float = 0.0
var tiempo_daño: float = 0.0
const UMBRAL_GOLPEADO: float = 30.0
const VENTANA_DAÑO: float = 1.5

var colores_vida = [
	Color("ff3b30"), Color("ff9500"), Color("ffcc00"),
	Color("4cd964"), Color("5ac8fa")
]
var colores_ki = [
	Color("0033aa"), Color("0055ff"), Color("33ccff")
]

@export var velocidad_maxima: float = 500.0
@export var aceleracion: float = 2000.0
@export var friccion: float = 12000.0

@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $HitboxAtaque
@onready var hitbox_shape: CollisionShape2D = $HitboxAtaque/CollisionShape2D
@onready var punto_disparo: Marker2D = $AnimatedSprite2D/PuntoDisparo

@export var oponente: Node2D
@export var fondo_blanco: ColorRect

var mi_layer: int = 4
var mi_mask: int = 2
var inputs_desactivados: bool = false
var mostrando_bajar: bool = false

func _ready() -> void:
	_inicializar_tiempos_tap()
	sprite.animation_finished.connect(_on_animation_finished)
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_golpe_conectado)
	cambiar_estado(Estado.INTRO)

func _inicializar_tiempos_tap() -> void:
	tiempo_ultimo_tap = {
		"izquierda" + sufijo: -1.0,
		"derecha" + sufijo: -1.0,
		"arriba" + sufijo: -1.0,
		"abajo" + sufijo: -1.0
	}

func _physics_process(delta: float) -> void:
	if barra_vida:
		actualizar_barra_por_capas(barra_vida, vida_total_actual, vida_total_maxima, colores_vida)
	if barra_ki:
		actualizar_barra_por_capas(barra_ki, ki_actual, ki_maximo, colores_ki)
	orientar_a_oponente()

	if daño_reciente > 0:
		tiempo_daño += delta
	if tiempo_daño > VENTANA_DAÑO:
		daño_reciente = 0.0
		tiempo_daño = 0.0

	if estado_actual == Estado.RECARGAR:
		ki_actual = min(ki_actual + velocidad_recarga * delta, ki_maximo)

	var dir := Vector2(
		Input.get_axis("izquierda" + sufijo, "derecha" + sufijo),
		Input.get_axis("arriba" + sufijo, "abajo" + sufijo)
	).normalized()

	procesar_movimiento(dir, delta)
	move_and_slide()

	match estado_actual:
		Estado.INTRO:
			pass
		_:
			actualizar_estado(dir)

func _input(event: InputEvent) -> void:
	if inputs_desactivados:
		return
	if estado_actual in [Estado.DERROTADO, Estado.INTRO]:
		return

	if Input.is_action_just_pressed("recargar" + sufijo):
		cambiar_estado(Estado.RECARGAR)
	if Input.is_action_just_released("recargar" + sufijo):
		cambiar_estado(Estado.IDLE)
		audio.stop()
	if estado_actual == Estado.RECARGAR:
		return

	_detectar_doble_tap("izquierda" + sufijo)
	_detectar_doble_tap("derecha" + sufijo)
	_detectar_doble_tap("arriba" + sufijo)
	_detectar_doble_tap("abajo" + sufijo)

	if Input.is_action_just_pressed("golpe" + sufijo):
		_registrar_golpe()
	if Input.is_action_just_pressed("patada" + sufijo):
		_registrar_patada()
	if Input.is_action_just_pressed("cubrirse" + sufijo):
		cambiar_estado(Estado.CUBRIRSE)
	if Input.is_action_just_released("cubrirse" + sufijo):
		cambiar_estado(Estado.IDLE)

	_input_especial(event)

func _input_especial(_event: InputEvent) -> void:
	pass

func _detectar_doble_tap(accion: String) -> void:
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		return
	if not tiempo_ultimo_tap.has(accion):
		return
	if Input.is_action_just_pressed(accion):
		var ahora := Time.get_ticks_msec() / 1000.0
		if ahora - tiempo_ultimo_tap[accion] < TIEMPO_DOBLE_TAP:
			_activar_rapido(accion)
			tiempo_ultimo_tap[accion] = -1.0
		else:
			tiempo_ultimo_tap[accion] = ahora

func _activar_rapido(accion: String) -> void:
	var dir_op: float = sign(oponente.global_position.x - global_position.x) if oponente else 1.0
	var hacia_oponente: bool = (accion == "derecha" + sufijo and dir_op > 0) or (accion == "izquierda" + sufijo and dir_op < 0)
	if accion == "derecha" + sufijo or accion == "izquierda" + sufijo:
		if hacia_oponente:
			cambiar_estado(Estado.RAPIDO_ADELANTE)
			velocity = Vector2(dir_op * velocidad_maxima * 2.5, 0)
		else:
			cambiar_estado(Estado.RAPIDO_ATRAS)
			velocity = Vector2(-dir_op * velocidad_maxima * 2.5, 0)
	elif accion == "arriba" + sufijo:
		cambiar_estado(Estado.RAPIDO_VOLAR)
		velocity = Vector2(0, -velocidad_maxima * 2.5)
	elif accion == "abajo" + sufijo:
		cambiar_estado(Estado.RAPIDO_BAJAR)
		velocity = Vector2(0, velocidad_maxima * 2.5)

func cambiar_estado(nuevo_estado: Estado) -> void:
	estado_previo = estado_actual
	estado_actual = nuevo_estado
	_on_cambiar_estado(nuevo_estado)

func _on_cambiar_estado(nuevo_estado: Estado) -> void:
	match nuevo_estado:
		Estado.INTRO: sprite.play("intro")
		Estado.IDLE:
			sprite.offset = Vector2(0, 0)
			mostrando_bajar = false
			sprite.play("default")
		Estado.ADELANTE: sprite.play("adelante")
		Estado.ATRAS: sprite.play("atras")
		Estado.VOLAR: sprite.play("volar")
		Estado.BAJAR:
			if not mostrando_bajar:
				mostrando_bajar = true
				sprite.play("bajar")
				sprite.frame = 0
		Estado.RAPIDO_ADELANTE:
			sprite.play("rapidoAdelante")
			reproducir("movimiento_rapido")
		Estado.RAPIDO_ATRAS:
			sprite.play("rapidoAtras")
			reproducir("movimiento_rapido")
		Estado.RAPIDO_VOLAR:
			sprite.play("rapidoVolar")
			reproducir("movimiento_rapido2")
		Estado.RAPIDO_BAJAR:
			sprite.play("rapidoBajar")
			reproducir("movimiento_rapido2")
		Estado.RECARGAR:
			sprite.play("recargar1")
			reproducir("inicio_carga")

		Estado.GOLPE1: sprite.play("golpe1")
		Estado.GOLPE2: sprite.play("golpe2")
		Estado.GOLPE3: sprite.play("golpe3")
		Estado.PATADA1: sprite.play("patada1")
		Estado.PATADA2: sprite.play("patada2")
		Estado.CUBRIRSE: sprite.play("cubrirse")
		Estado.GOLPEADO: sprite.play("golpeado")
		Estado.MUY_GOLPEADO: sprite.play("muyGolpeado")
		Estado.DERROTADO:
			sprite.play("derrotado")
			hitbox_shape.set_deferred("disabled", true)
			if oponente and oponente.has_method("desactivar_inputs"):
				oponente.desactivar_inputs()
			var pelea = get_parent()
			if pelea and pelea.has_method("efecto_victoria"):
				pelea.efecto_victoria(oponente)
			if oponente and oponente.has_method("play_victoria"):
				oponente.play_victoria()
				

func procesar_movimiento(dir: Vector2, delta: float) -> void:
	if inputs_desactivados:
		velocity = Vector2.ZERO
		return
	if estado_actual == Estado.INTRO:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		return
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * velocidad_maxima, aceleracion * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)
	if estado_actual in [Estado.RECARGAR, Estado.CUBRIRSE]:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.GOLPEADO, Estado.MUY_GOLPEADO, Estado.DERROTADO]:
		if not is_on_floor():
			velocity.y += 980 * delta
		velocity.x = move_toward(velocity.x, 0, friccion * delta)
		return
	if estado_actual in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3, Estado.PATADA1, Estado.PATADA2, Estado.RAFAGA1, Estado.RAFAGA2, Estado.LASER, Estado.BOLA_GIGANTE]:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2]:
		velocity = Vector2.ZERO
		return
	if estado_actual == Estado.CHOQUE:
		velocity= Vector2.ZERO
		return

func actualizar_estado(dir: Vector2) -> void:
	if inputs_desactivados:
		return
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		return
	if estado_actual in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3]:
		return
	if estado_actual in [Estado.PATADA1, Estado.PATADA2]:
		return
	if estado_actual in [Estado.RECARGAR, Estado.CUBRIRSE]:
		return
	if estado_actual in [Estado.GOLPEADO, Estado.MUY_GOLPEADO, Estado.DERROTADO]:
		return
	if estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2, Estado.LASER, Estado.BOLA_GIGANTE]:
		return
	if estado_actual == Estado.CHOQUE:
		return

	var hacia_oponente: float = 0.0
	if oponente:
		hacia_oponente = velocity.x * sign(oponente.global_position.x - global_position.x)
	else:
		hacia_oponente = velocity.x

	if velocity.length() < 10 and dir == Vector2.ZERO:
		cambiar_estado(Estado.IDLE)
	elif hacia_oponente > 0:
		cambiar_estado(Estado.ADELANTE)
	elif hacia_oponente < 0:
		cambiar_estado(Estado.ATRAS)
	elif dir.y < 0:
		cambiar_estado(Estado.VOLAR)
	elif dir.y > 0 and not is_on_floor():
		if estado_actual != Estado.BAJAR:
			cambiar_estado(Estado.BAJAR)
		elif mostrando_bajar:
			sprite.pause()
			sprite.frame = sprite.sprite_frames.get_frame_count("bajar") - 1

	if is_on_floor() and estado_actual == Estado.BAJAR:
		cambiar_estado(Estado.IDLE)

func orientar_a_oponente() -> void:
	if oponente == null:
		return
	var direction = oponente.global_position.x < global_position.x
	sprite.rotation = 0.0
	sprite.scale.x = -2.0 if direction else 2.0

func _on_animation_finished() -> void:
	match estado_actual:
		Estado.INTRO:
			cambiar_estado(Estado.IDLE)
		Estado.BAJAR:
			sprite.pause()
			sprite.frame = sprite.sprite_frames.get_frame_count("bajar") - 1
		Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR:
			cambiar_estado(estado_previo)
		Estado.GOLPE1:
			hitbox_shape.disabled = true
			if siguiente_golpe == 2:
				siguiente_golpe = 0
				cambiar_estado(Estado.GOLPE2)
			else:
				cambiar_estado(Estado.IDLE)
		Estado.GOLPE2:
			hitbox_shape.disabled = true
			if siguiente_golpe == 3:
				siguiente_golpe = 0
				cambiar_estado(Estado.GOLPE3)
			else:
				cambiar_estado(Estado.IDLE)
		Estado.GOLPE3:
			hitbox_shape.disabled = true
			siguiente_golpe = 0
			cambiar_estado(Estado.IDLE)
		Estado.PATADA1:
			hitbox_shape.disabled = true
			if siguiente_patada == 2:
				siguiente_patada = 0
				cambiar_estado(Estado.PATADA2)
			else:
				cambiar_estado(Estado.IDLE)
		Estado.PATADA2:
			hitbox_shape.disabled = true
			siguiente_patada = 0
			cambiar_estado(Estado.IDLE)
		Estado.RECARGAR:
			if sprite.animation == "recargar1":
				sprite.play("recargarBucle")
				reproducir("bucle_carga")

		Estado.GOLPEADO:
			cambiar_estado(Estado.IDLE)
		Estado.MUY_GOLPEADO:
			cambiar_estado(Estado.IDLE)
		Estado.DERROTADO:
			if oponente and oponente.has_method("desactivar_inputs"):
				oponente.desactivar_inputs()
			sprite.pause()
			sprite.frame = sprite.sprite_frames.get_frame_count("derrotado") - 1
			hitbox_shape.disabled = true
		Estado.RAFAGA1, Estado.RAFAGA2:
			cambiar_estado(Estado.IDLE)
			if estado_actual == Estado.DERROTADO:
				sprite.pause()
				sprite.frame = sprite.sprite_frames.get_frame_count("derrotado") - 1
				hitbox_shape.set_deferred("disabled", true)

func _registrar_golpe() -> void:
	if estado_actual not in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3]:
		cambiar_estado(Estado.GOLPE1)
		return
	if estado_actual == Estado.GOLPE1:
		siguiente_golpe = 2
	elif estado_actual == Estado.GOLPE2:
		siguiente_golpe = 3

func _registrar_patada() -> void:
	if estado_actual not in [Estado.PATADA1, Estado.PATADA2]:
		cambiar_estado(Estado.PATADA1)
		return
	if estado_actual == Estado.PATADA1:
		siguiente_patada = 2

func _on_golpe_conectado(body: Node) -> void:
	if body == oponente:
		oponente.recibir_daño(10)
		if estado_actual == Estado.GOLPE1:
			reproducir("golpe1")
		elif estado_actual == Estado.GOLPE2:
			reproducir("golpe2")
		elif estado_actual == Estado.GOLPE3:
			reproducir("golpe1")
		elif estado_actual == Estado.PATADA1:
			reproducir("patada")
		elif estado_actual == Estado.PATADA2:
			reproducir("patada2")

func actualizar_barra_por_capas(barra: ProgressBar, valor_actual: float, valor_maximo: float, lista_colores: Array) -> void:
	var capa_actual: int = 0
	var valor_en_capa: float = 0.0
	if valor_actual > 0:
		capa_actual = int(ceil(valor_actual / 100.0)) - 1
		capa_actual = clampi(capa_actual, 0, lista_colores.size() - 1)
		valor_en_capa = fmod(valor_actual, 100.0)
		if valor_en_capa == 0.0:
			valor_en_capa = 100.0
	barra.max_value = 100.0
	barra.value = valor_en_capa
	var estilo_fill: StyleBoxFlat = barra.get_theme_stylebox("fill")
	var estilo_bg: StyleBoxFlat = barra.get_theme_stylebox("background")
	if estilo_fill and estilo_bg:
		estilo_fill.bg_color = lista_colores[capa_actual]
		if capa_actual > 0:
			estilo_bg.bg_color = lista_colores[capa_actual - 1]
		else:
			estilo_bg.bg_color = Color("222222")

func recibir_daño(cantidad: float) -> void:
	if estado_actual == Estado.CUBRIRSE:
		cantidad *= 0.2
		var cubiertas = ["cubrirse", "cubrirse3"]
		reproducir(cubiertas[randi() % cubiertas.size()])
	vida_total_actual = max(vida_total_actual - cantidad, 0)
	if vida_total_actual == 0:
		cambiar_estado(Estado.DERROTADO)
		return
	daño_reciente += cantidad
	tiempo_daño = 0.0
	if daño_reciente >= UMBRAL_GOLPEADO:
		daño_reciente = 0.0
		cambiar_estado(Estado.GOLPEADO)

func recibir_daño_especial(cantidad: float) -> void:
	vida_total_actual = max(vida_total_actual - cantidad, 0)
	if vida_total_actual == 0:
		cambiar_estado(Estado.DERROTADO)
		return
	cambiar_estado(Estado.MUY_GOLPEADO)

func recibir_golpe_kaioken(cantidad: float, impulso: Vector2) -> void:
	cambiar_estado(Estado.GOLPEADO)
	vida_total_actual = max(vida_total_actual - cantidad, 0)
	if vida_total_actual == 0:
		cambiar_estado(Estado.DERROTADO)
		return
	desactivar_inputs()
	if impulso.y < 0:
		cambiar_estado(Estado.GOLPEADO)
		sprite.pause()
		var pos_arriba := global_position.y - 200
		var pos_abajo := global_position.y
		var tween = create_tween()
		tween.tween_property(self, "global_position:y", pos_arriba, 0.5)
		tween.tween_interval(0.3)
		tween.tween_property(self, "global_position:y", pos_abajo, 0.5)
		tween.tween_callback(func():
			cambiar_estado(Estado.MUY_GOLPEADO)
			activar_inputs()
		)
	else:
		velocity = impulso

func desactivar_inputs() -> void:
	inputs_desactivados = true

func activar_inputs() -> void:
	inputs_desactivados = false

func ajustar_colision(pos: Vector2) -> void:
	colision.position = pos

func configurar(config: Dictionary) -> void:
	if config.has("sufijo"):
		sufijo = config["sufijo"]
		_inicializar_tiempos_tap()
	if config.has("barra_vida"):
		barra_vida = config["barra_vida"]
	if config.has("barra_ki"):
		barra_ki = config["barra_ki"]
	if config.has("fondo_blanco"):
		fondo_blanco = config["fondo_blanco"]
	if config.has("oponente"):
		oponente = config["oponente"]
	if config.has("layer"):
		mi_layer = config["layer"]
	if config.has("mask"):
		mi_mask = config["mask"]

func reproducir(sonido: String) -> void:
	if not is_inside_tree():
		return
	if sonidos.has(sonido) and audio:
		audio.stream = sonidos[sonido]
		audio.play()

func play_victoria() -> void:
	sprite.play("victoria")
