extends CharacterBody2D

@onready var hitbox_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox_area: Area2D = $Area2D
@onready var hitbox_area2: Area2D = $Area2D2
@onready var hitbox_shape: CollisionShape2D = $Area2D/hitboxAtaque
@onready var hitbox_shape2: CollisionShape2D = $Area2D2/hitboxAtaqueStand
@onready var collision_body: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var star_platinum: Node2D = $StarPlatinum
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var timer: Timer = $Timer

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 800.0
const DOUBLE_TAP_WINDOW := 1.0
var inputs_desactivados: bool = false
var sp_offset_x: float = 0.0

var tiempo_disparo_presionado: float = 0.0
const TIEMPO_CARGA_AVDUL: float = 0.7
var cargando_disparo: bool = false

var is_active := false
var attack_count := 0
var attack_timer := 0.0
var is_attacking := false
var is_stand_attacking := false
var is_recharging := false

var dash_count_left := 0
var dash_count_right := 0
var dash_timer_left := 0.0
var dash_timer_right := 0.0
var is_dashing := false
var dash_direction := 0.0
var dash_duration := 0.2
var dash_timer_duration := 0.0

var sufijo: String = "J1"

var sonidos = {
	"ORA": preload("res://Assets/Luchadores/jotaro/sonidos/ORAcorto.wav"),
	"RAFAGA": preload("res://Assets/Luchadores/jotaro/sonidos/ORArafaga.wav")
}

@export var oponente: Node2D
@export var barra_vida: ProgressBar
@export var barra_ki: ProgressBar
@export var vida_maxima: float = 500.0
var vida_actual: float = 500.0

@export var ki_maximo: float = 300.0
var ki_actual: float = 100.0
@export var velocidad_recarga: float = 30.0

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

func _ready() -> void:
	hitbox_area.body_entered.connect(_on_golpe_conectado)
	hitbox_area2.body_entered.connect(_on_golpe_conectado2)
	sprite.play("Parado")
	star_platinum.oponente = oponente
	sprite.animation_finished.connect(_on_animation_finished)
	star_platinum.jotaro = self
	sp_offset_x = abs(star_platinum.position.x)
	print("sp_offset_x inicial: ", sp_offset_x)
	


var tiempo_kaioken: float = 0.0

func _physics_process(delta: float) -> void:
	# --- Actualizar barras ---
	if barra_vida:
		actualizar_barra_por_capas(barra_vida, vida_actual, vida_maxima, colores_vida)
	if barra_ki:
		actualizar_barra_por_capas(barra_ki, ki_actual, ki_maximo, colores_ki)

	# --- Recarga de Ki ---
	if is_recharging:
		ki_actual = min(ki_actual + velocidad_recarga * delta, ki_maximo)

	if inputs_desactivados:
		tiempo_kaioken += delta
		if not is_on_floor() or tiempo_kaioken < 0.1:
			velocity += get_gravity() * delta
		else:
			activar_inputs()
			velocity = Vector2.ZERO
			tiempo_kaioken = 0.0
		move_and_slide()
		return

	if attack_timer > 0:
		attack_timer -= delta
	if dash_timer_left > 0:
		dash_timer_left -= delta
	if dash_timer_right > 0:
		dash_timer_right -= delta
	if dash_timer_duration > 0:
		dash_timer_duration -= delta
	else:
		is_dashing = false

	# --- Recargar Ki con tecla ---
	if Input.is_action_just_pressed("recargar" + sufijo) and is_on_floor() and not is_attacking and not is_stand_attacking and not is_dashing:
		is_recharging = true
		sprite.play("Cargar")
	if Input.is_action_just_released("recargar" + sufijo):
		is_recharging = false
		sprite.play("Parado")
	if is_recharging:
		move_and_slide()
		return

	# --- Dash (doble tap) ---
	if not is_dashing and is_on_floor():
		if Input.is_action_just_pressed("izquierda" + sufijo):
			dash_count_left += 1
			if dash_count_left == 1:
				dash_timer_left = DOUBLE_TAP_WINDOW
			elif dash_count_left >= 2 and dash_timer_left > 0:
				dash_count_left = 0
				is_dashing = true
				dash_direction = -1.0
				dash_timer_duration = dash_duration
				sprite.play("Dash")
		if Input.is_action_just_pressed("derecha" + sufijo):
			dash_count_right += 1
			if dash_count_right == 1:
				dash_timer_right = DOUBLE_TAP_WINDOW
			elif dash_count_right >= 2 and dash_timer_right > 0:
				dash_count_right = 0
				is_dashing = true
				dash_direction = 1.0
				dash_timer_duration = dash_duration
				sprite.play("Dash")

	if dash_timer_left <= 0:
		dash_count_left = 0
	if dash_timer_right <= 0:
		dash_count_right = 0

	# --- Disparo: Kakyoin rápido / Avdul mantenido ---
	if Input.is_action_just_pressed("disparar" + sufijo) and not is_attacking and not is_stand_attacking and not is_dashing and is_on_floor():
		cargando_disparo = true
		tiempo_disparo_presionado = 0.0

	if cargando_disparo:
		tiempo_disparo_presionado += delta

	if Input.is_action_just_released("disparar" + sufijo) and cargando_disparo:
		cargando_disparo = false
		if tiempo_disparo_presionado >= TIEMPO_CARGA_AVDUL:
			if ki_actual >= 100:
				ki_actual -= 100
				is_stand_attacking = true
				sprite.play("Llamar")
				star_platinum.ejecutar_avdul()
		else:
			if ki_actual >= 15:
				ki_actual -= 15
				is_stand_attacking = true
				sprite.play("Llamar")
				star_platinum.ejecutar_kakyoin()

	# --- Ráfaga de Star Platinum (especial1) ---
	if Input.is_action_just_pressed("especial1" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		if ki_actual >= 100:
			ki_actual -= 100
			attack_count = 0
			is_stand_attacking = true
			sprite.play("Llamar")
			reproducir("RAFAGA")
			hitbox_player.play("rafaga")
			star_platinum.ejecutar_rafaga()
			hitbox_shape2.disabled = true
			timer.start(0.5)

	# --- Uppercut (golpe + arriba) ---
	if Input.is_action_just_pressed("golpe" + sufijo) and Input.is_action_pressed("arriba" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		if ki_actual >= 50:
			ki_actual -= 50
			attack_count = 0
			is_stand_attacking = true
			sprite.play("Golpe")
			hitbox_player.play("Golpe1")

	# --- Combo de golpes ---
	if Input.is_action_just_pressed("golpe" + sufijo) and not Input.is_action_pressed("arriba" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking:
		attack_count += 1
		attack_timer = DOUBLE_TAP_WINDOW
		is_attacking = true
		if attack_count == 1:
			sprite.play("Golpe")
			hitbox_player.play("Golpe1")
		elif attack_count == 2:
			sprite.play("Patada")
			hitbox_player.play("Patada1")
		elif attack_count >= 3:
			attack_count = 0
			is_attacking = false
			is_stand_attacking = true
			sprite.play("Llamar")
			hitbox_player.play("golpe")
			reproducir("ORA")
			star_platinum.ejecutar_golpe()

	if attack_timer <= 0:
		attack_count = 0

	if is_attacking and not sprite.is_playing():
		is_attacking = false

	if is_stand_attacking and not sprite.is_playing():
		is_stand_attacking = false

	# --- Agarre de Star Platinum (patada) ---
	if Input.is_action_just_pressed("patada" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		if ki_actual >= 50:
			ki_actual -= 50
			is_stand_attacking = true
			sprite.play("Parado")
			star_platinum.ejecutar_agarre()

	# --- Ultimate (especial2) ---
	if Input.is_action_just_pressed("especial2" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		if ki_actual >= 200:
			ki_actual -= 200
			is_stand_attacking = true
			sprite.play("Parado")
			star_platinum.ejecutar_ultimate()

	# --- Bloqueo automático con cubrirse ---
	if Input.is_action_just_pressed("cubrirse" + sufijo) and not is_attacking and not is_stand_attacking:
		sprite.play("Cubrirse")
		star_platinum.ejecutar_bloqueo()
	if Input.is_action_just_released("cubrirse" + sufijo):
		sprite.play("Parado")
		star_platinum.detener_bloqueo()

	# --- Aire ---
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y < 0:
			sprite.play("SaltoSubida")
		else:
			sprite.play("SaltoCaida")
		is_attacking = false
		is_stand_attacking = false
		is_recharging = false
		cargando_disparo = false

	# --- Salto ---
	if Input.is_action_just_pressed("arriba" + sufijo) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- Movimiento horizontal ---
	var direction := Input.get_axis("izquierda" + sufijo, "derecha" + sufijo)
	var dir_to_oponente: float = 0.0
	var moviendose_atras: bool = false
	if oponente:
		dir_to_oponente = sign(oponente.global_position.x - global_position.x)
		moviendose_atras = direction != 0 and sign(direction) != sign(dir_to_oponente)
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
	elif is_attacking or is_stand_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
		if is_on_floor():
			sprite.play("Caminar")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			sprite.play("Parado")
	
	move_and_slide()

	if oponente:
		if not is_dashing and not is_attacking and not is_stand_attacking and is_on_floor():
			if moviendose_atras:
				sprite.flip_h = dir_to_oponente > 0
			else:
				sprite.flip_h = dir_to_oponente < 0

		hitbox_shape.position.x = abs(hitbox_shape.position.x) * dir_to_oponente
		hitbox_area2.position = star_platinum.position
		hitbox_shape2.position.x = abs(hitbox_shape2.position.x) * dir_to_oponente
		hitbox_shape2.position.x = 15.0 * dir_to_oponente
		star_platinum.sprite.flip_h = dir_to_oponente < 0
		star_platinum.position.x = 37.0 * dir_to_oponente



func golpear_oponente(cantidad: float) -> void:
	if oponente and oponente.has_method("recibir_daño"):
		oponente.recibir_daño(cantidad)

func golpear_oponente_especial(cantidad: float) -> void:
	if oponente and oponente.has_method("recibir_daño_especial"):
		oponente.recibir_daño_especial(cantidad)

func recibir_daño(cantidad: float) -> void:
	if Input.is_action_pressed("cubrirse" + sufijo):
		cantidad *= 0.2
		sprite.play("Cubrirse")
	
	vida_actual = max(vida_actual - cantidad, 0)
	
	if vida_actual == 0:
		_activar_derrota()
		return
	
	sprite.play("Dano")


func _activar_derrota() -> void:
	inputs_desactivados = true
	is_attacking = false
	is_stand_attacking = false
	is_recharging = false
	cargando_disparo = false
	hitbox_shape.set_deferred("disabled", true)
	hitbox_shape2.set_deferred("disabled", true)
	sprite.play("Derrota")
	
	# Notificar al oponente para que celebre
	if oponente and oponente.has_method("desactivar_inputs"):
		oponente.desactivar_inputs()
	if oponente and oponente.has_method("play_victoria"):
		oponente.play_victoria()
		oponente.desactivar_inputs()
	
	# Notificar a la escena padre (para efecto de victoria, igual que Goku)
	var pelea = get_parent()
	if pelea and pelea.has_method("efecto_victoria"):
		pelea.efecto_victoria(oponente)


func recibir_daño_especial(cantidad: float) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	
	if vida_actual == 0:
		_activar_derrota()
		return
	
	sprite.play("MuchoDano")

func recibir_golpe_kaioken(cantidad: float, impulso: Vector2) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	
	if vida_actual == 0:
		_activar_derrota()
		return
	
	velocity = impulso
	desactivar_inputs()
	sprite.play("Dano")

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

func configurar(config: Dictionary) -> void:
	if config.has("sufijo"):
		sufijo = config["sufijo"]
	if config.has("barra_vida"):
		barra_vida = config["barra_vida"]
	if config.has("barra_ki"):
		barra_ki = config["barra_ki"]
	if config.has("oponente"):
		oponente = config["oponente"]
	if config.has("oponente"):
		oponente = config["oponente"]
		star_platinum.oponente = oponente

func _on_golpe_conectado(body: Node) -> void:
	if body == oponente:
		if is_attacking:
			golpear_oponente(10)
		elif is_stand_attacking:
			golpear_oponente_especial(30)


func _on_golpe_conectado2(body: Node) -> void:
	if body == oponente:
		if star_platinum.is_active:
			golpear_oponente_especial(20)


func desactivar_inputs() -> void:
	inputs_desactivados = true

func activar_inputs() -> void:
	inputs_desactivados = false

func reproducir(sonido: String) -> void:
	if sonidos.has(sonido):
		audio.stream = sonidos[sonido]
		audio.play()

func _on_animation_finished() -> void:
	if sprite.animation == "Derrota":
		sprite.pause()
		sprite.frame = sprite.sprite_frames.get_frame_count("Derrota") - 1
		desactivar_inputs()

func _on_timer_timeout() -> void:
	hitbox_shape2.disabled = false
