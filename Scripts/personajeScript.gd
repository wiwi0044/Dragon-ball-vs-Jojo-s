extends CharacterBody2D

enum Estado { INTRO, IDLE, ADELANTE, ATRAS, VOLAR, BAJAR, RAPIDO_ADELANTE, RAPIDO_ATRAS, RAPIDO_VOLAR, RAPIDO_BAJAR, GOLPE1, GOLPE2, GOLPE3
, PATADA1, PATADA2, RECARGAR, CUBRIRSE, DERROTADO, GOLPEADO, MUY_GOLPEADO, RAFAGA1, RAFAGA2, RAFAGA3, KAMEHAMEHA_CARGA, KAMEHAMEHA_DISPARO
, KIENZAN_CARGA, KIENZAN_DISPARO, TAIOKEN, KAIOKEN}
var estado_actual: Estado = Estado.INTRO
var estado_previo: Estado = Estado.IDLE
var tiempo_ultimo_tap := {"adelante": -1.0, "retroceder": -1.0, "volar": -1.0, "bajar": -1.0}
const TIEMPO_DOBLE_TAP := 0.3
var conteo_golpes: int = 0
var tiempo_ultimo_golpe: float = 0.0
const TIEMPO_COMBO: float = 0.8
var siguiente_patada: int = 0

@onready var barra_vida: ProgressBar = $"../CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/BarraVIda"
var vida_total_actual: float = 500.0
@export var vida_total_maxima: float = 500.0

@onready var barra_ki: ProgressBar = $"../CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/BarraKi"
@export var ki_maximo: float = 300.0
var ki_actual: float = 100
@export var velocidad_recarga: float = 30.0

var daño_reciente: float = 0.0
var tiempo_daño: float = 0.0
const UMBRAL_GOLPEADO: float = 30.0
const VENTANA_DAÑO: float = 1.5

@onready var punto_disparo: Marker2D = $PuntoDisparo
var bola_recta = preload("res://Scenes/BolaRecta.tscn")
var bola_diagonal = preload("res://Scenes/BolaDiagonal.tscn")
var kamehameha_scene = preload("res://Scenes/KamehamehaRayo.tscn")
var ultima_rafaga: int = 2
var tiempo_ki_presionado: float = 0.0
const TIEMPO_CARGA_KAMEHAMEHA: float = 0.4
var cargando_ki: bool = false
var kamehameha_disparado: bool = false

var kienzan_scene = preload("res://Scenes/Kienzan.tscn")
var kienzan_disparado: bool = false

@onready var fondo_blanco: ColorRect = get_node("../CapaCegera/Fondo_blanco") 

var frames_kaioken_golpeados: Array = []
const FRAMES_KAIOKEN = {
	3: Vector2(0, 0),
	5: Vector2(0, 0),
	10: Vector2(0, -1000),  # manda arriba
	14: Vector2(0, 1500)    # manda abajo
}
var kaioken_conecto: bool = false

var colores_vida = [
	Color("ff3b30"),
	Color("ff9500"),
	Color("ffcc00"),
	Color("4cd964"),
	Color("5ac8fa")
]

var colores_ki = [
	Color("0033aa"),
	Color("0055ff"),
	Color("33ccff")
]

@export var velocidad_maxima: float = 500.0
@export var aceleracion: float = 2000.0
@export var friccion: float = 12000.0
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var oponente: Node2D
@onready var hitbox: Area2D = $HitboxAtaque
@onready var hitbox_shape: CollisionShape2D = $HitboxAtaque/CollisionShape2D

var mostrando_bajar: bool = false
var siguiente_golpe: int = 0

func _ready() -> void:
	oponente = get_node("../Oponente")
	sprite.animation_finished.connect(_on_animation_finished)
	cambiar_estado(Estado.INTRO)
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_golpe_conectado)
	sprite.frame_changed.connect(_on_frame_changed)

func _physics_process(delta: float) -> void:
	actualizar_barra_por_capas(barra_vida, vida_total_actual, vida_total_maxima, colores_vida)
	actualizar_barra_por_capas(barra_ki, ki_actual, ki_maximo, colores_ki)
	orientar_a_oponente()

	if daño_reciente > 0:
		tiempo_daño += delta
	if tiempo_daño > VENTANA_DAÑO:
		daño_reciente = 0.0
		tiempo_daño = 0.0

	if cargando_ki:
		tiempo_ki_presionado += delta
		if tiempo_ki_presionado >= TIEMPO_CARGA_KAMEHAMEHA and estado_actual != Estado.KAMEHAMEHA_CARGA:
			cambiar_estado(Estado.KAMEHAMEHA_CARGA)

	var dir := Vector2(
		Input.get_axis("retroceder", "adelante"),
		Input.get_axis("volar", "bajar")
	).normalized()

	procesar_movimiento(dir, delta)

	if estado_actual == Estado.RECARGAR:
		ki_actual = min(ki_actual + velocidad_recarga * delta, ki_maximo)

	move_and_slide()

	match estado_actual:
		Estado.INTRO:
			pass
		_:
			actualizar_estado(dir)

func _input(event: InputEvent) -> void:
	if estado_actual == Estado.DERROTADO:
		return
	if estado_actual == Estado.INTRO:
		return
	_detectar_doble_tap("adelante")
	_detectar_doble_tap("retroceder")
	_detectar_doble_tap("volar")
	_detectar_doble_tap("bajar")
	if Input.is_action_just_pressed("golpe"):
		_registrar_golpe()
	if Input.is_action_just_pressed("patada"):
		_registrar_patada()
	if Input.is_action_just_pressed("recargar"):
		cambiar_estado(Estado.RECARGAR)
	if Input.is_action_just_released("recargar"):
		cambiar_estado(Estado.IDLE)
	if Input.is_action_just_pressed("cubrirse"):
		cambiar_estado(Estado.CUBRIRSE)
	if Input.is_action_just_released("cubrirse"):
		cambiar_estado(Estado.IDLE)
	if Input.is_action_just_pressed("ki"):
		cargando_ki = true
		tiempo_ki_presionado = 0.0
	if Input.is_action_just_released("ki"):
		if cargando_ki:
			if ki_actual >= 100 and tiempo_ki_presionado >= TIEMPO_CARGA_KAMEHAMEHA:
				cambiar_estado(Estado.KAMEHAMEHA_DISPARO)
			else:
				_lanzar_rafaga()
		cargando_ki = false
		tiempo_ki_presionado = 0.0
	if Input.is_action_pressed("volar") and Input.is_action_just_pressed("ki"):
		cambiar_estado(Estado.KIENZAN_CARGA)
		cargando_ki = false 
	
	if Input.is_action_pressed("taioken"):
		if estado_actual == Estado.IDLE or estado_actual == Estado.VOLAR:
			cargando_ki = false
			ejecutar_taioken()
	
	if Input.is_action_just_pressed("kaioken"):
		if ki_actual >= 100:
			ki_actual -= 100
			cambiar_estado(Estado.KAIOKEN)

func _detectar_doble_tap(accion: String) -> void:
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
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
	var hacia_oponente: bool = (accion == "adelante" and dir_op > 0) or (accion == "retroceder" and dir_op < 0)
	if accion == "adelante" or accion == "retroceder":
		if hacia_oponente:
			cambiar_estado(Estado.RAPIDO_ADELANTE)
			velocity = Vector2(dir_op * velocidad_maxima * 2.5, 0)
		else:
			cambiar_estado(Estado.RAPIDO_ATRAS)
			velocity = Vector2(-dir_op * velocidad_maxima * 2.5, 0)
	elif accion == "volar":
		cambiar_estado(Estado.RAPIDO_VOLAR)
		velocity = Vector2(0, -velocidad_maxima * 2.5)
	elif accion == "bajar":
		cambiar_estado(Estado.RAPIDO_BAJAR)
		velocity = Vector2(0, velocidad_maxima * 2.5)

func cambiar_estado(nuevo_estado: Estado) -> void:
	estado_previo = estado_actual
	estado_actual = nuevo_estado
	match estado_actual:
		Estado.INTRO:
			sprite.play("intro")
		Estado.IDLE:
			sprite.offset = Vector2(0, 0)
			mostrando_bajar = false
			sprite.play("default")
		Estado.ADELANTE:
			mostrando_bajar = false
			sprite.play("adelante")
		Estado.ATRAS:
			mostrando_bajar = false
			sprite.play("atras")
		Estado.VOLAR:
			mostrando_bajar = false
			sprite.play("volar")
		Estado.BAJAR:
			if not mostrando_bajar:
				mostrando_bajar = true
				sprite.play("bajar")
				sprite.frame = 0
		Estado.RAPIDO_ADELANTE:
			mostrando_bajar = false
			sprite.play("rapidoAdelante")
		Estado.RAPIDO_ATRAS:
			mostrando_bajar = false
			sprite.play("rapidoAtras")
		Estado.RAPIDO_VOLAR:
			mostrando_bajar = false
			sprite.play("rapidoVolar")
		Estado.RAPIDO_BAJAR:
			mostrando_bajar = false
			sprite.play("rapidoBajar")
		Estado.GOLPE1:
			sprite.play("golpe1")
		Estado.GOLPE2:
			sprite.play("golpe2")
		Estado.GOLPE3:
			sprite.play("golpe3")
		Estado.PATADA1:
			sprite.play("patada1")
		Estado.PATADA2:
			sprite.play("patada2")
		Estado.RECARGAR:
			sprite.play("recargar1")
		Estado.CUBRIRSE:
			sprite.play("cubrirse")
		Estado.GOLPEADO:
			sprite.play("golpeado")
		Estado.MUY_GOLPEADO:
			sprite.play("muyGolpeado")
		Estado.DERROTADO:
			sprite.play("derrotado")
		Estado.RAFAGA1:
			sprite.play("rafaga1")
			var dir_x := -1.0 if sprite.flip_h else 1.0
			_instanciar_bola_recta(dir_x)
		Estado.RAFAGA2:
			sprite.play("rafaga2")
			var dir_x := -1.0 if sprite.flip_h else 1.0
			_instanciar_bola_recta(dir_x)
		Estado.RAFAGA3:
			sprite.play("rafaga3")
		Estado.KAMEHAMEHA_CARGA:
			if ki_actual >= 100:
				sprite.play("kamehameha_carga")
		Estado.KAMEHAMEHA_DISPARO:
			kamehameha_disparado = false
			sprite.play("kamehameha_disparo")
		Estado.KIENZAN_CARGA:
			kienzan_disparado = false 
			sprite.play("kienzanCarga")
		Estado.TAIOKEN: 
			sprite.play("taioken")
		Estado.KAIOKEN:
			frames_kaioken_golpeados = []
			kaioken_conecto = false 
			sprite.play("kaioken")

func procesar_movimiento(dir: Vector2, delta: float) -> void:
	if estado_actual == Estado.INTRO:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		return
	if estado_actual == Estado.KAIOKEN:
		return
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * velocidad_maxima, aceleracion * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friccion * delta)
	if estado_actual == Estado.RECARGAR:
		velocity = Vector2.ZERO
		return
	if estado_actual == Estado.CUBRIRSE:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.GOLPEADO, Estado.MUY_GOLPEADO, Estado.DERROTADO]:
		if not is_on_floor():
			velocity.y += 980 * delta
		velocity.x = move_toward(velocity.x, 0, friccion * delta)
		return
	if estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2, Estado.RAFAGA3]:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.KAMEHAMEHA_CARGA, Estado.KAMEHAMEHA_DISPARO]:
		velocity = Vector2.ZERO
		return
	if estado_actual in [Estado.KIENZAN_CARGA, Estado.KIENZAN_DISPARO, Estado.TAIOKEN]:
		velocity = Vector2.ZERO
		return

func actualizar_estado(dir: Vector2) -> void:
	if estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		return
	if estado_actual in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3]:
		return
	if estado_actual in [Estado.PATADA1, Estado.PATADA2]:
		return
	if estado_actual == Estado.RECARGAR:
		return
	if estado_actual == Estado.CUBRIRSE:
		return
	if estado_actual in [Estado.GOLPEADO, Estado.MUY_GOLPEADO, Estado.DERROTADO]:
		return
	if estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2, Estado.RAFAGA3]:
		return
	if estado_actual in [Estado.KAMEHAMEHA_CARGA, Estado.KAMEHAMEHA_DISPARO]:
		return
	if estado_actual in [Estado.KIENZAN_CARGA, Estado.KIENZAN_DISPARO, Estado.TAIOKEN]:
		return
	if estado_actual == Estado.KAIOKEN:
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
		
	sprite.flip_h = oponente.global_position.x < global_position.x
	sprite.rotation = 0.0 
	
	if estado_actual in [Estado.IDLE, Estado.ADELANTE, Estado.ATRAS, Estado.VOLAR, Estado.BAJAR, Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		if sprite.flip_h:
			ajustar_colision(Vector2(-40, 0)) 
			sprite.offset = Vector2(0, 0)
		else:
			ajustar_colision(Vector2(0, 0))
			sprite.offset = Vector2(0, 0)
			
	# 2. Estados de ataque cuerpo a cuerpo
	elif estado_actual in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3, Estado.PATADA1, Estado.PATADA2]:
		if sprite.flip_h:
			ajustar_colision(Vector2(-10, 0))
		else:
			ajustar_colision(Vector2(-25, 0))
			
	# 3. Estado de recarga
	elif estado_actual == Estado.RECARGAR:
		if sprite.flip_h:
			ajustar_colision(Vector2(-45, 5))
			sprite.offset = Vector2(-10, -30)
		else:
			ajustar_colision(Vector2(0, 0))
			sprite.offset = Vector2(10, -30)
			
	# 4. Estado de defensa
	elif estado_actual == Estado.CUBRIRSE:
		if sprite.flip_h:
			ajustar_colision(Vector2(-40, 10))
			sprite.offset = Vector2(-10, 10)
		else:
			ajustar_colision(Vector2(-10, 10))
			sprite.offset = Vector2(10, 10)
			
	# 5. Estados de daño recibido
	elif estado_actual in [Estado.GOLPEADO, Estado.MUY_GOLPEADO]:
		if sprite.flip_h:
			ajustar_colision(Vector2(0, 0))
			sprite.offset = Vector2(0, 10)
		else:
			ajustar_colision(Vector2(0, 0))
			sprite.offset = Vector2(0, 10)
			
	# 6. Ataques especiales (Kamehameha)
	elif estado_actual in [Estado.KAMEHAMEHA_DISPARO]:
		var angulo := global_position.direction_to(oponente.global_position).angle()
		punto_disparo.position = Vector2(0, 0)
		
		if sprite.flip_h:
			sprite.offset = Vector2(25, 0)
			sprite.rotation = angulo + PI
			ajustar_colision(Vector2(-40, 0))
		else:
			sprite.rotation = angulo
			ajustar_colision(Vector2(0, 0))
			
	# 7. Ataques especiales (Kienzan)
	elif estado_actual in [Estado.KIENZAN_CARGA, Estado.KIENZAN_DISPARO]:
		var angulo := global_position.direction_to(oponente.global_position).angle()
		if sprite.flip_h:
			ajustar_colision(Vector2(-10, 10))
			sprite.rotation = angulo + PI
		else:
			ajustar_colision(Vector2(-20, 10))
			sprite.rotation = angulo
	

func _on_animation_finished() -> void:
	if estado_actual == Estado.INTRO and sprite.animation == "intro":
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.BAJAR:
		sprite.pause()
		sprite.frame = sprite.sprite_frames.get_frame_count("bajar") - 1
	elif estado_actual in [Estado.RAPIDO_ADELANTE, Estado.RAPIDO_ATRAS, Estado.RAPIDO_VOLAR, Estado.RAPIDO_BAJAR]:
		cambiar_estado(estado_previo)
	elif estado_actual == Estado.GOLPE1:
		hitbox_shape.disabled = true
		if siguiente_golpe == 2:
			siguiente_golpe = 0
			cambiar_estado(Estado.GOLPE2)
		else:
			cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.GOLPE2:
		hitbox_shape.disabled = true
		if siguiente_golpe == 3:
			siguiente_golpe = 0
			cambiar_estado(Estado.GOLPE3)
		else:
			cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.GOLPE3:
		hitbox_shape.disabled = true
		siguiente_golpe = 0
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.PATADA1:
		hitbox_shape.disabled = true
		if siguiente_patada == 2:
			siguiente_patada = 0
			cambiar_estado(Estado.PATADA2)
		else:
			cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.PATADA2:
		hitbox_shape.disabled = true
		siguiente_patada = 0
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.RECARGAR and sprite.animation == "recargar1":
		sprite.play("recargarBucle")
	elif estado_actual == Estado.GOLPEADO:
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.MUY_GOLPEADO:
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.DERROTADO:
		oponente.desactivar_hitbox()
		sprite.pause()
		sprite.frame = sprite.sprite_frames.get_frame_count("derrotado") - 1
		hitbox_shape.disabled = true
		await get_tree().create_timer(0.1).timeout
		get_tree().paused = true
	elif estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2, Estado.RAFAGA3]:
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.KAMEHAMEHA_DISPARO:
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.KIENZAN_CARGA:
		cambiar_estado(Estado.IDLE)
	elif estado_actual == Estado.KAIOKEN:
		oponente.activar_hitbox()
		cambiar_estado(Estado.IDLE)

func ajustar_colision(pos: Vector2) -> void:
	colision.position = pos

func _registrar_golpe() -> void:
	if estado_actual not in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3]:
		cambiar_estado(Estado.GOLPE1)
		return
	if estado_actual == Estado.GOLPE1:
		siguiente_golpe = 2
	elif estado_actual == Estado.GOLPE2:
		siguiente_golpe = 3

func _intentar_golpe() -> void:
	match conteo_golpes:
		1: cambiar_estado(Estado.GOLPE1)
		2: cambiar_estado(Estado.GOLPE2)
		_: cambiar_estado(Estado.GOLPE3)
	conteo_golpes = 0

func _on_frame_changed() -> void:
	if estado_actual in [Estado.GOLPE1, Estado.GOLPE2, Estado.GOLPE3]:
		var ultimo_frame := sprite.sprite_frames.get_frame_count(sprite.animation) - 1
		if sprite.frame == ultimo_frame:
			hitbox_shape.disabled = false
			var offset_x := 0.0
			var offset_y := 0.0
			if estado_actual == Estado.GOLPE1:
				offset_x = 0.0 if not sprite.flip_h else -84.0
				offset_y = 10
			elif estado_actual == Estado.GOLPE2:
				offset_x = -8 if not sprite.flip_h else -83
				offset_y = 0
			elif estado_actual == Estado.GOLPE3:
				offset_x = 0.0 if not sprite.flip_h else -80
				offset_y = 0
			hitbox.position = Vector2(offset_x, offset_y)
		else:
			hitbox_shape.disabled = true
	elif estado_actual in [Estado.PATADA1, Estado.PATADA2]:
		var frame_activacion := 0
		if estado_actual == Estado.PATADA1:
			frame_activacion = 1
		elif estado_actual == Estado.PATADA2:
			frame_activacion = 2
		if sprite.frame == frame_activacion:
			hitbox_shape.disabled = false
			var offset_x := 0.0
			var offset_y := 0.0
			if estado_actual == Estado.PATADA1:
				offset_x = 10 if not sprite.flip_h else -85
				offset_y = -10
			elif estado_actual == Estado.PATADA2:
				offset_x = 10 if not sprite.flip_h else -85
				offset_y = 0.0
			hitbox.position = Vector2(offset_x, offset_y)
		else:
			hitbox_shape.disabled = true
	elif estado_actual in [Estado.RAFAGA1, Estado.RAFAGA2]:
		var dir_x := -1.0 if sprite.flip_h else 1.0
		
	elif estado_actual == Estado.RAFAGA3:
		var dir_x := -1.0 if sprite.flip_h else 1.0
		if sprite.frame == 1:
			_instanciar_bola_diagonal(dir_x)
		elif sprite.frame == 2:
			_instanciar_bola_diagonal(dir_x)
		
	elif estado_actual == Estado.KAMEHAMEHA_DISPARO:
		if sprite.frame == 0 and not kamehameha_disparado:
			kamehameha_disparado = true
			_disparar_kamehameha()
			
	elif estado_actual == Estado.KIENZAN_CARGA:
		var ultimo_frame := sprite.sprite_frames.get_frame_count("kienzanCarga") - 1
		if sprite.frame == ultimo_frame and not kienzan_disparado:
			kienzan_disparado = true
			_disparar_kienzan()
	elif estado_actual == Estado.TAIOKEN and sprite.frame == 4:
		_activar_destello_taioken()
	elif estado_actual == Estado.KAIOKEN:
		if sprite.frame == 1:
			var dir_oponente: float = sign(oponente.global_position.x - global_position.x) if oponente else 1.0
			velocity = Vector2(dir_oponente * velocidad_maxima * 5.0, 0)
		elif sprite.frame == 2:
			velocity = Vector2.ZERO 
			hitbox_shape.disabled = false
			if sprite.flip_h:
				hitbox.position = Vector2(-110, 0) 
			else:
				hitbox.position = Vector2(20.0, 0)
		elif sprite.frame == 4:
			hitbox_shape.disabled = true
			if not kaioken_conecto:
				cambiar_estado(Estado.IDLE)
				
		if kaioken_conecto and sprite.frame > 3 and sprite.frame in FRAMES_KAIOKEN and sprite.frame not in frames_kaioken_golpeados:
			frames_kaioken_golpeados.append(sprite.frame)
			var impulso: Vector2 = FRAMES_KAIOKEN[sprite.frame]
			oponente.recibir_golpe_kaioken(40, impulso)
			if sprite.frame == 10:
				velocity = impulso
			elif sprite.frame == 14:
				velocity = Vector2.ZERO

func _on_golpe_conectado(body: Node) -> void:
	if body == oponente:
		if estado_actual == Estado.KAIOKEN and not kaioken_conecto:
			kaioken_conecto = true
			oponente.desactivar_hitbox()
			if 3 in FRAMES_KAIOKEN:
				frames_kaioken_golpeados.append(3)
				oponente.recibir_golpe_kaioken(20, FRAMES_KAIOKEN[3])
		elif estado_actual != Estado.KAIOKEN:
			oponente.recibir_daño(10)

func _registrar_patada() -> void:
	if estado_actual not in [Estado.PATADA1, Estado.PATADA2]:
		cambiar_estado(Estado.PATADA1)
		return
	if estado_actual == Estado.PATADA1:
		siguiente_patada = 2

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
	cambiar_estado(Estado.MUY_GOLPEADO)

func _instanciar_bola_recta(dir_x: float) -> void:
	if ki_actual < 15: return
	ki_actual = max(ki_actual - 15, 0)
	var bola = bola_recta.instantiate()
	bola.direccion = Vector2(dir_x, 0)
	bola.global_position = punto_disparo.global_position
	get_parent().add_child(bola)

func _instanciar_bola_diagonal(dir_x: float) -> void:
	if ki_actual < 15: return
	ki_actual = max(ki_actual - 15, 0)
	if oponente:
		dir_x = sign(oponente.global_position.x - global_position.x)
		if dir_x == 0: dir_x = 1.0
	var bola = bola_diagonal.instantiate()
	bola.global_position = punto_disparo.global_position
	bola.direccion = Vector2(dir_x, 0.5).normalized()
	get_parent().add_child(bola)

func _lanzar_rafaga() -> void:
	if oponente and global_position.y < oponente.global_position.y - 30:
		cambiar_estado(Estado.RAFAGA3)
	else:
		if ultima_rafaga == 1:
			ultima_rafaga = 2
			cambiar_estado(Estado.RAFAGA2)
		else:
			ultima_rafaga = 1
			cambiar_estado(Estado.RAFAGA1)

func _disparar_kamehameha() -> void:
	var daño: float = ki_actual * 0.8
	ki_actual = 0.0
	var k = kamehameha_scene.instantiate()
	k.global_position = punto_disparo.global_position
	get_parent().add_child(k)
	var dir_x := -1.0 if sprite.flip_h else 1.0
	k.inicializar(oponente.global_position, dir_x, daño)

func _disparar_kienzan() -> void:
	if ki_actual < 40: return # Costo de Ki para el Kienzan
	ki_actual = max(ki_actual - 40, 0)
	var k = kienzan_scene.instantiate()
	var offset_local = punto_disparo.position
	if sprite.flip_h:
		offset_local.x = -abs(offset_local.x)
	k.global_position = global_position + offset_local.rotated(sprite.rotation)
	get_parent().add_child(k)
	var dir_hacia_oponente = global_position.direction_to(oponente.global_position)
	k.rotation = dir_hacia_oponente.angle()
	if "direccion" in k:
		k.direccion = dir_hacia_oponente
	
	var dir_x := -1.0 if sprite.flip_h else 1.0
	if k.has_method("inicializar"):
		k.inicializar(oponente.global_position, dir_x, 50.0) # 50 de daño base

func ejecutar_taioken() -> void:
	cambiar_estado(Estado.TAIOKEN)

func _activar_destello_taioken() -> void:
	var tween = create_tween()
	tween.tween_property(fondo_blanco, "modulate:a", 1.0, 0.05)
	tween.tween_callback(func(): cambiar_estado(Estado.IDLE))
	tween.tween_interval(1.5)
	tween.tween_property(fondo_blanco, "modulate:a", 0.0, 2.0)
