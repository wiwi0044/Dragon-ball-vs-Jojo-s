extends Node2D

@onready var inicio: Sprite2D = $SpriteInicio
@onready var medio: Sprite2D = $SpriteMedio
@onready var fin: Sprite2D = $SpriteFin
@onready var explosion: AnimatedSprite2D = $SpriteExplosion
@onready var colision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area: Area2D = $Area2D
@onready var choque_sprite: Sprite2D = $SpriteChoque

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
var punto_choque: float = 0.5 # Inicia balanceado en el 50%
var velocidad_choque: float = 0.05 # Qué tan rápido se neutraliza si nadie presiona
var choque_resuelto: bool = false

func inicializar(oponente_pos: Vector2, p_dir_x: float, daño: float, p_dueño: Node = null) -> void:
	daño_total = daño
	poder = daño
	dir_x = p_dir_x
	dueño = p_dueño
	scale.x = dir_x
	explosion.visible = false
	medio.region_enabled = false
	choque_sprite.visible = false

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
		
		# Mantén el límite visual que habías puesto para que no atraviese al jugador
		var punto_visual_limitado: float = clamp(punto_choque, 0.1, 0.9)
		largo_medio_actual = dist_total * punto_visual_limitado 
		
		_actualizar_medio(largo_medio_actual)

		var ajuste_x: float = -7.0 
		var ajuste_y: float = -20.0
		
		choque_sprite.position.x = ancho_inicio + largo_medio_actual + ajuste_x
		choque_sprite.position.y = ajuste_y
		choque_sprite.scale.x = sign(dir_x)

		(colision.shape as RectangleShape2D).size = Vector2(60, 60)
		colision.position.x = ancho_inicio + largo_medio_actual

		if not choque_resuelto:
			# Si logras empujarlo al 90%, ganas y tu rayo se libera para golpearlo
			if punto_choque >= 0.9:
				choque_resuelto = true
				rival.choque_resuelto = true
				
				var rival_dueño = rival.get("dueño")
				if rival_dueño and rival_dueño.has_method("kamehameha_termino"):
					rival_dueño.kamehameha_termino()
				rival.queue_free()
				
				en_choque = false
				rival = null
				choque_sprite.visible = false
				fin.visible = true
				distancia_objetivo = dist_total + 200.0 # Vuela hasta su cuerpo
				
			# Si te empujan al 10%, pierdes
			elif punto_choque <= 0.1:
				choque_resuelto = true
				rival.choque_resuelto = true
				
				if dueño and dueño.has_method("kamehameha_termino"):
					dueño.kamehameha_termino()
				
				rival.en_choque = false
				rival.rival = null
				rival.choque_sprite.visible = false
				rival.fin.visible = true
				rival.distancia_objetivo = dist_total + 200.0 
				
				queue_free()
		return
	var factor: float = max(1.0, (distancia_objetivo - largo_medio_actual) / distancia_objetivo * 3.0)
	largo_medio_actual = min(largo_medio_actual + velocidad * delta * factor, distancia_objetivo - ancho_inicio - ancho_fin)
	largo_medio_actual = max(largo_medio_actual, ancho_medio_base)

	_actualizar_medio(largo_medio_actual)

	(colision.shape as RectangleShape2D).size = Vector2(60, 60)
	colision.position.x = ancho_inicio + largo_medio_actual + ancho_fin - 40

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
		
		fin.visible = false
		otro.fin.visible = false
		
		distancia_objetivo = largo_medio_actual + ancho_inicio + ancho_fin
		otro.distancia_objetivo = otro.largo_medio_actual + otro.ancho_inicio + otro.ancho_fin
		
		if dir_x > 0:
			choque_sprite.visible = true
			otro.choque_sprite.visible = false
			choque_sprite.position.x = ancho_inicio + largo_medio_actual
		else:
			choque_sprite.visible = false
			otro.choque_sprite.visible = true
			otro.choque_sprite.position.x = otro.ancho_inicio + otro.largo_medio_actual
		
		if dueño and dueño.has_method("entrar_choque_kamehameha"):
			dueño.entrar_choque_kamehameha()
			
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

func recibir_empuje(cantidad: float) -> void:
	poder -= cantidad
	if poder <= 0:
		en_choque = false
		rival = null
		impactado = true
		_explotar()

func agregar_poder(cantidad: float) -> void:
	if en_choque:
		# Fuerza por click. Subido ligeramente para compensar el tamaño real.
		var fuerza_click: float = 0.04 
		
		punto_choque = clamp(punto_choque + fuerza_click, 0.0, 1.0)
		if rival:
			rival.punto_choque = clamp(rival.punto_choque - fuerza_click, 0.0, 1.0)

func _explotar() -> void:
	impactado = true
	inicio.visible = false
	medio.visible = false
	fin.visible = false
	colision.set_deferred("disabled", true)
	choque_sprite.visible = false
	explosion.position.x = ancho_inicio + largo_medio_actual
	explosion.visible = true
	explosion.play("explosion")

func _on_explosion_finished() -> void:
	if dueño and dueño.has_method("kamehameha_termino"):
		dueño.kamehameha_termino()
	queue_free()

func destruir() -> void:
	queue_free()
