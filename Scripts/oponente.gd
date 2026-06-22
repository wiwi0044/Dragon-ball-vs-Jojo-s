extends CharacterBody2D

@onready var barra_vida: ProgressBar = $"../CanvasLayer2/PanelContainer/HBoxContainer/VBoxContainer/enemigoVida"
@onready var ataque: CollisionShape2D=$HiboxAtaque/CollisionShape2D
@export var vida_maxima: float = 500.0
var vida_actual: float = 500.0

var colores_vida = [
	Color("ff3b30"),
	Color("ff9500"),
	Color("ffcc00"),
	Color("4cd964"),
	Color("5ac8fa")
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HiboxAtaque
@onready var hitbox_shape: CollisionShape2D = $HiboxAtaque/CollisionShape2D
@export var objetivo: Node2D

var golpeando: bool = false
var siendo_golpeado: bool = false
var tiempo_golpe: float = 0.0
const DURACION_GOLPE: float = 0.3

func _ready() -> void:
	objetivo = get_node("../Personaje")
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_golpe_conectado)
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.play("default")


func _physics_process(delta: float) -> void:
	actualizar_barra_por_capas(barra_vida, vida_actual, vida_maxima, colores_vida)
	if objetivo:
		sprite.flip_h = objetivo.global_position.x < global_position.x
	
	if siendo_golpeado:
		tiempo_golpe += delta
		if not is_on_floor():
			velocity.y += 980 * delta  # gravedad
		if tiempo_golpe >= DURACION_GOLPE:
			siendo_golpeado = false
			tiempo_golpe = 0.0
			velocity = Vector2.ZERO
	
	move_and_slide()

		
func _input(event: InputEvent) -> void:
	if siendo_golpeado:
		return
		
	if Input.is_action_just_pressed("golpe") and not golpeando:
		golpeando = true
		sprite.play("golpe")

func _on_frame_changed() -> void:
	if golpeando:
		var ultimo_frame := sprite.sprite_frames.get_frame_count("golpe") - 1
		if sprite.frame == ultimo_frame:
			hitbox_shape.disabled = false
			var offset_x := 30.0 if not sprite.flip_h else -30.0
			hitbox.position = Vector2(offset_x, 0)
		else:
			hitbox_shape.disabled = true

func _on_animation_finished() -> void:
	if sprite.animation == "golpe":
		golpeando = false
		hitbox_shape.disabled = true
		sprite.play("default")

func _on_golpe_conectado(body: Node) -> void:
	if body == objetivo:
		objetivo.recibir_daño(10)

func recibir_daño(cantidad: float) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	if vida_actual == 0:
		print("Oponente derrotado")

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
			
func desactivar_hitbox() -> void:
	golpeando = false
	sprite.play("default")
	hitbox_shape.set_deferred("disabled", true)
	
func activar_hitbox() -> void:
	golpeando = false
	sprite.play("golpe")
	hitbox_shape.set_deferred("disabled", false)
	
func recibir_daño_especial(cantidad: float) -> void:
	vida_actual = max(vida_actual - cantidad, 0)
	if vida_actual == 0:
		print("Oponente derrotado")
		

func recibir_golpe_kaioken(cantidad: float, impulso: Vector2) -> void:
	recibir_daño(cantidad)
	velocity = impulso
	siendo_golpeado = true
	tiempo_golpe = -0.6
