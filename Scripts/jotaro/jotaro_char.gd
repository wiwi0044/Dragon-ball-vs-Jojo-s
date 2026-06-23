extends CharacterBody2D

@onready var animation_player: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_stand: AnimatedSprite2D = $Node2D/StarPlatinum

@onready var hitbox_shape: CollisionShape2D=$Area2D/hitboxAtaque
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 800.0
const DOUBLE_TAP_WINDOW := 1.0
var inputs_desactivados: bool = false

var attack_count := 0
var attack_timer := 0.0
var is_attacking := false
var is_stand_attacking := false

var dash_count_left := 0
var dash_count_right := 0
var dash_timer_left := 0.0
var dash_timer_right := 0.0
var is_dashing := false
var dash_direction := 0.0
var dash_duration := 0.2
var dash_timer_duration := 0.0

var sufijo: String = "J1"

@export var oponente: Node2D
@export var barra_vida: ProgressBar
@export var vida_maxima: float = 500.0
var vida_actual: float = 500.0

var colores_vida = [
	Color("ff3b30"),
	Color("ff9500"),
	Color("ffcc00"),
	Color("4cd964"),
	Color("5ac8fa")
]

func _ready() -> void:
	animation_stand.visible = false

var tiempo_kaioken: float = 0.0

func _physics_process(delta: float) -> void:
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
				animation_player.flip_h = true
				animation_player.play("Dash")
		if Input.is_action_just_pressed("derecha" + sufijo):
			dash_count_right += 1
			if dash_count_right == 1:
				dash_timer_right = DOUBLE_TAP_WINDOW
			elif dash_count_right >= 2 and dash_timer_right > 0:
				dash_count_right = 0
				is_dashing = true
				dash_direction = 1.0
				dash_timer_duration = dash_duration
				animation_player.flip_h = false
				animation_player.play("Dash")

	if dash_timer_left <= 0:
		dash_count_left = 0
	if dash_timer_right <= 0:
		dash_count_right = 0

	if Input.is_action_just_pressed("especial1" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		attack_count = 0
		is_stand_attacking = true
		animation_stand.visible = true
		animation_stand.play("Rafaga")
		animation_player.play("Parado")

	if Input.is_action_just_pressed("golpe" + sufijo) and Input.is_action_pressed("arriba" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		attack_count = 0
		is_stand_attacking = true
		animation_stand.visible = true
		animation_player.play("Parado")
		animation_stand.play("Uppercut")

	if Input.is_action_just_pressed("golpe" + sufijo) and is_on_floor() and not is_dashing and not is_stand_attacking:
		attack_count += 1
		attack_timer = DOUBLE_TAP_WINDOW
		is_attacking = true
		if attack_count == 1:
			animation_player.play("Golpe")
		elif attack_count == 2:
			animation_player.play("Patada")
		elif attack_count >= 3:
			attack_count = 0
			is_attacking = false
			is_stand_attacking = true
			animation_stand.visible = true
			animation_stand.play("Golpe")
			animation_player.play("Parado")

	if attack_timer <= 0:
		attack_count = 0

	if is_attacking and not animation_player.is_playing():
		is_attacking = false

	if is_stand_attacking and not animation_stand.is_playing():
		is_stand_attacking = false
		animation_stand.visible = false

	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y < 0:
			animation_player.play("SaltoSubida")
		else:
			animation_player.play("SaltoCaida")
		is_attacking = false
		is_stand_attacking = false
		animation_stand.visible = false

	if Input.is_action_just_pressed("arriba" + sufijo) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("izquierda" + sufijo, "derecha" + sufijo)
	if is_dashing:
		velocity.x = dash_direction * DASH_SPEED
	elif is_attacking or is_stand_attacking:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif direction:
		velocity.x = direction * SPEED
		animation_player.flip_h = direction < 0
		animation_stand.flip_h = direction < 0
		if is_on_floor():
			animation_player.play("Caminar")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor():
			animation_player.play("Parado")

	move_and_slide()

	if barra_vida:
		actualizar_barra_por_capas(barra_vida, vida_actual, vida_maxima, colores_vida)

	if oponente:
		var dir_to_oponente = sign(oponente.global_position.x - global_position.x)
		if not is_dashing and not is_attacking and not is_stand_attacking and is_on_floor():
			animation_player.flip_h = dir_to_oponente < 0
			animation_stand.flip_h = dir_to_oponente < 0

func recibir_daño(cantidad: float) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	if vida_actual == 0:
		print("Jotaro derrotado")

func recibir_daño_especial(cantidad: float) -> void:
	recibir_daño(cantidad)

func recibir_golpe_kaioken(cantidad: float, impulso: Vector2) -> void:
	recibir_daño(cantidad)
	velocity=impulso
	desactivar_inputs()

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
	if config.has("oponente"):
		oponente = config["oponente"]

func desactivar_inputs() -> void:
	inputs_desactivados = true

func activar_inputs() -> void:
	inputs_desactivados = false
