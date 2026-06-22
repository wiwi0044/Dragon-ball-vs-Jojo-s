extends CharacterBody2D
@onready var animation_player : AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_stand : AnimatedSprite2D = $Node2D/StarPlatinum
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 800.0
const DOUBLE_TAP_WINDOW := 1.0

# Ataque
var attack_count := 0
var attack_timer := 0.0
var is_attacking := false
var is_stand_attacking := false

# Dash
var dash_count_left := 0
var dash_count_right := 0
var dash_timer_left := 0.0
var dash_timer_right := 0.0
var is_dashing := false
var dash_direction := 0.0
var dash_duration := 0.2
var dash_timer_duration := 0.0

func _ready() -> void:
	animation_stand.visible = false  # Stand oculto al inicio

func _physics_process(delta: float) -> void:
	# --- Temporizadores ---
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

	# --- Detectar doble toque para Dash ---
	if not is_dashing and is_on_floor():
		if Input.is_action_just_pressed("ui_left"):
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
		if Input.is_action_just_pressed("ui_right"):
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

	# Resetear contadores si venció el tiempo
	if dash_timer_left <= 0:
		dash_count_left = 0
	if dash_timer_right <= 0:
		dash_count_right = 0

	if Input.is_action_just_pressed("especial") and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		attack_count = 0
		is_stand_attacking = true
		animation_stand.visible = true        # Mostrar stand
		animation_stand.play("Rafaga")
		animation_player.play("Parado")       # Personaje quieto durante la ráfaga

	if Input.is_action_just_pressed("Golpe") and Input.is_action_pressed("ui_up") and is_on_floor() and not is_dashing and not is_stand_attacking and not is_attacking:
		attack_count = 0
		is_stand_attacking = true
		animation_stand.visible = true
		animation_player.play("Parado")
		animation_stand.play("Uppercut")


	# --- Detectar golpes (combo de 3) ---
	if Input.is_action_just_pressed("Golpe") and is_on_floor() and not is_dashing and not is_stand_attacking:
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
			animation_stand.visible = true       # Mostrar stand
			animation_stand.play("Golpe")
			animation_player.play("Parado")      # Personaje quieto mientras el stand golpea

	# Resetear combo si venció el tiempo
	if attack_timer <= 0:
		attack_count = 0

	# Detectar fin de animación de ataque normal
	if is_attacking and not animation_player.is_playing():
		is_attacking = false

	# Detectar fin del stand y ocultarlo
	if is_stand_attacking and not animation_stand.is_playing():
		is_stand_attacking = false
		animation_stand.visible = false          # Ocultar stand al terminar

	# --- Gravedad y animaciones en el aire ---
	if not is_on_floor():
		velocity += get_gravity() * delta
		if velocity.y < 0:
			animation_player.play("SaltoSubida")
		else:
			animation_player.play("SaltoCaida")
		is_attacking = false
		is_stand_attacking = false
		animation_stand.visible = false

	# --- Salto ---
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- Movimiento ---
	var direction := Input.get_axis("ui_left", "ui_right")
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
