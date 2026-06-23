extends Node2D

@onready var inicio: Sprite2D = $SpriteInicio
@onready var medio: Sprite2D = $SpriteMedio
@onready var fin: Sprite2D = $SpriteFin
@onready var explosion: AnimatedSprite2D = $SpriteExplosion
@onready var colision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area: Area2D = $Area2D

var ancho_inicio: float = 80.0
var ancho_medio_base: float = 100.0
var ancho_fin: float = 80.0
var daño_total: float = 80.0
var impactado: bool = false
var velocidad: float = 450.0
var distancia_objetivo: float = 0.0
var largo_medio_actual: float = 0.0
var dir_x: float = 1.0
var alto_medio: float = 2.188

var en_choque: bool = false
var poder: float = 0.0
var rival: Node = null
var dueño: Node = null
var punto_choque: float = 0.0
var velocidad_choque: float = 0.001
var choque_resuelto: bool = false

func inicializar(oponente_pos: Vector2, p_dir_x: float, daño: float, p_dueño: Node = null) -> void:
	daño_total = daño
	poder = daño
	dir_x = p_dir_x
	dueño = p_dueño
	scale.x = dir_x
	explosion.visible = false
	medio.region_enabled = false

	var direccion := (oponente_pos - global_position).normalized()
	rotation = direccion.angle()
	if dir_x < 0:
		rotation += PI

	distancia_objetivo = global_position.distance_to(oponente_pos)
	largo_medio_actual = ancho_medio_base

	explosion.animation_finished.connect(_on_explosion_finished)
	area.body_entered.connect(_on_body_entered)
	area.area_entered.connect(_on_area_entered)

func _actualizar_medio(largo: float, sobrepaso: float = 370.0) -> void:
	var largo_total := largo + sobrepaso
	medio.scale = Vector2(largo_total / medio.texture.get_width(), alto_medio)
	medio.position.x = ancho_inicio + largo / 2.0
	fin.position.x = ancho_inicio + largo

func _physics_process(delta: float) -> void:
	if impactado:
		return

	if en_choque and rival:
		punto_choque = move_toward(punto_choque, 0.5, velocidad_choque * delta)
		var dist_total: float = global_position.distance_to(rival.global_position)
		largo_medio_actual = clamp(punto_choque * dist_total, ancho_medio_base, dist_total - ancho_fin)

		_actualizar_medio(largo_medio_actual)

		var ancho_total: float = ancho_inicio + largo_medio_actual + ancho_fin
		(colision.shape as RectangleShape2D).size = Vector2(ancho_total + 100, 60)
		colision.position.x = ancho_total / 2.0
		explosion.position.x = ancho_total

		if not choque_resuelto:
			if punto_choque >= 0.95:
				choque_resuelto = true
				rival.choque_resuelto = true
				rival.impactado = true
				var rival_dueño = rival.get("dueño")
				rival.queue_free()
				if dueño and dueño.has_method("kamehameha_termino"):
					dueño.kamehameha_termino()
				if rival_dueño and rival_dueño.has_method("recibir_daño_especial"):
					rival_dueño.recibir_daño_especial(100)
				_explotar()
			elif punto_choque <= 0.05:
				choque_resuelto = true
				rival.choque_resuelto = true
				var rival_dueño = rival.get("dueño")
				rival.queue_free()
				if rival_dueño and rival_dueño.has_method("kamehameha_termino"):
					rival_dueño.kamehameha_termino()
				if dueño and dueño.has_method("recibir_daño_especial"):
					dueño.recibir_daño_especial(100)
				_explotar()
		return

	var factor: float = max(1.0, (distancia_objetivo - largo_medio_actual) / distancia_objetivo * 3.0)
	largo_medio_actual = min(largo_medio_actual + velocidad * delta * factor, distancia_objetivo - ancho_inicio - ancho_fin)
	largo_medio_actual = max(largo_medio_actual, ancho_medio_base)

	_actualizar_medio(largo_medio_actual)

	var ancho_total: float = ancho_inicio + largo_medio_actual + ancho_fin
	(colision.shape as RectangleShape2D).size = Vector2(ancho_total, 40)
	colision.position.x = ancho_total / 2.0
	explosion.position.x = ancho_total

	if largo_medio_actual >= distancia_objetivo - ancho_inicio - ancho_fin:
		_explotar()

func _on_area_entered(otra_area: Area2D) -> void:
	if impactado or en_choque:
		return
	var otro = otra_area.get_parent()
	if otro == self:
		return
	if otro.has_method("agregar_poder"):
		en_choque = true
		rival = otro
		otro.en_choque = true
		otro.rival = self
		punto_choque = 0.5
		otro.punto_choque = 0.5
		if dueño and dueño.has_method("entrar_choque_kamehameha"):
			dueño.entrar_choque_kamehameha()
		if otro.get("dueño") and otro.dueño.has_method("entrar_choque_kamehameha"):
			otro.dueño.entrar_choque_kamehameha()

func _on_body_entered(body: Node) -> void:
	if impactado: return
	if en_choque: return
	if body == dueño: return
	if rival and rival.get("dueño") == body: return
	if body.has_method("recibir_daño_especial"):
		impactado = true
		body.recibir_daño_especial(120)
		_explotar()

func recibir_empuje(cantidad: float) -> void:
	poder -= cantidad
	if poder <= 0:
		en_choque = false
		rival = null
		impactado = true
		_explotar()

func agregar_poder(cantidad: float) -> void:
	if en_choque:
		punto_choque += 0.05
		if rival:
			rival.punto_choque -= 0.05

func _explotar() -> void:
	impactado = true
	inicio.visible = false
	medio.visible = false
	fin.visible = false
	colision.set_deferred("disabled", true)
	explosion.visible = true
	explosion.play("explosion")

func _on_explosion_finished() -> void:
	if dueño and dueño.has_method("kamehameha_termino"):
		dueño.kamehameha_termino()
	queue_free()

func destruir() -> void:
	queue_free()
