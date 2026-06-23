extends Area2D 

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var velocidad: float = 800.0
var direccion: Vector2 = Vector2.ZERO
var daño_total: float = 50.0
var impactado: bool = false

func _ready() -> void:
	sprite.play("kienzanDisparo")
	body_entered.connect(_on_body_entered)

func inicializar(oponente_pos: Vector2, dir_x: float, daño: float) -> void:
	daño_total = daño
	
	# Tomamos la lógica de tu Kamehameha: calculamos la dirección real en 2D hacia el oponente
	direccion = (oponente_pos - global_position).normalized()
	
	# Rotamos el Area2D para que el hitbox y el sprite miren hacia esa diagonal
	rotation = direccion.angle()

func _physics_process(delta: float) -> void:
	if impactado: 
		return
	global_position += direccion * velocidad * delta

func _on_body_entered(body: Node) -> void:
	if impactado: 
		return
		
	if body.name == "Oponente" or body.has_method("recibir_daño_especial"):
		impactado = true
		body.recibir_daño_especial(daño_total)
		queue_free() # Se destruye inmediatamente al golpear

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
