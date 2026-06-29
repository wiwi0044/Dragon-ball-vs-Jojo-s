extends Node2D
@onready var camara: Camera2D = $Camera2D
@onready var fondo_rojo: ColorRect = $CanvasLayer3/FondoRojo
var efecto_activo: bool = false

var escenas_personajes = {
	"goku": preload("res://Scenes/personajes/goku/base/Personaje.tscn"),
	"jotaro": preload("res://Scenes/personajes/jotario/JotaroChar.tscn"),
	"freezer": preload("res://Scenes/personajes/freezer/freezer.tscn"),
}

var fondos = {
	"Coliseo": "res://Assets/fondos/EscenarioColiseo.png",
	"Morioh": "res://Assets/fondos/moriohEscenario.png",
	"Torneo": "res://Assets/fondos/torneo.png",
}

@onready var spawn_j1: Marker2D = $SpawnJ1
@onready var spawn_j2: Marker2D = $SpawnJ2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for limite in $LimitesEscena.get_children():
		limite.collision_layer = 4
		limite.collision_mask = 0
		
	print("escenario: '", GlobalData.escenario, "'")
	if GlobalData.escenario in fondos:
		$Fondo.texture = load(fondos[GlobalData.escenario])
	
	var j1 = escenas_personajes[GlobalData.personaje_j1].instantiate()
	var j2 = escenas_personajes[GlobalData.personaje_j2].instantiate()
	add_child(j1)
	add_child(j2)
	j1.global_position = spawn_j1.global_position
	j2.global_position = spawn_j2.global_position
	j2.collision_layer = 2
	j1.collision_layer = 1
	j1.collision_mask = 2 | 4
	j2.collision_mask = 1 | 4
	_configurar_hitbox(j1, 4, 2)
	_configurar_hitbox(j2, 8, 1)

	$"CanvasLayer/PanelContainer/HBoxContainer/TextureRect".texture = load("res://Assets/Luchadores/" + GlobalData.personaje_j1 + "/icono.png")
	$"CanvasLayer2/PanelContainer/HBoxContainer/TextureRect".texture = load("res://Assets/Luchadores/" + GlobalData.personaje_j2 + "/icono.png")

	j1.configurar({
		"sufijo": "J1",
		"layer": 4,
		"mask": 2,
		"oponente": j2,
		"barra_vida": $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/BarraVida",
		"barra_ki": $"CanvasLayer/PanelContainer/HBoxContainer/VBoxContainer/BarraKi",
		"fondo_blanco": $"CapaCegera/Fondo_blanco"
	})
	j2.configurar({
		"sufijo": "J2",
		"layer": 8,
		"mask": 1,
		"oponente": j1,
		"barra_vida": $"CanvasLayer2/PanelContainer/HBoxContainer/VBoxContainer/enemigoVida",
		"barra_ki": $"CanvasLayer2/PanelContainer/HBoxContainer/VBoxContainer/enemigoKi",
		"fondo_blanco": $"CapaCegera/Fondo_blanco"
	})
	
func _configurar_hitbox(nodo: Node, layer: int, mask: int) -> void:
	for hijo in nodo.get_children():
		if hijo is Area2D:
			hijo.collision_layer = layer
			hijo.collision_mask = mask
		_configurar_hitbox(hijo, layer, mask)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and efecto_activo:
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Scenes/SeleccionPersonaje.tscn")

func efecto_victoria(ganador: Node) -> void:
	if efecto_activo:
		return
	efecto_activo = true
	
	Engine.time_scale = 0.3
	
	fondo_rojo.modulate.a = 0.0
	var tween_parpadeo = create_tween()
	tween_parpadeo.set_loops(4)
	tween_parpadeo.tween_property(fondo_rojo, "modulate:a", 0.5, 0.2)
	tween_parpadeo.tween_property(fondo_rojo, "modulate:a", 0.0, 0.2)
	
	await get_tree().create_timer(2.0).timeout
	
	fondo_rojo.modulate.a = 0.0
	Engine.time_scale = 1.0
	
	var tween_camara = create_tween()
	tween_camara.tween_property(camara, "position", ganador.global_position, 0.8)
	tween_camara.parallel().tween_property(camara, "zoom", Vector2(2.5, 2.5), 0.8)
	
	await get_tree().create_timer(0.8).timeout
	
	var fuente = load("res://Scenes/8-bit Arcade In.ttf")
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	var label_winner = Label.new()
	ganador.z_index = 10
	label_winner.text = "WINNER"
	label_winner.add_theme_font_override("font", fuente)
	label_winner.add_theme_font_size_override("font_size", 120)
	label_winner.add_theme_color_override("font_color", Color.YELLOW)
	label_winner.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_winner.add_theme_constant_override("shadow_offset_x", 4)
	label_winner.add_theme_constant_override("shadow_offset_y", 4)
	label_winner.set_anchors_preset(Control.PRESET_CENTER)
	label_winner.position.y -= 170
	label_winner.position.x -= 100
	canvas.add_child(label_winner)
	
	var label_esc = Label.new()
	label_esc.text = "ESC para salir"
	label_esc.add_theme_font_override("font", fuente)
	label_esc.add_theme_font_size_override("font_size", 30)
	label_esc.add_theme_color_override("font_color", Color.WHITE)
	label_esc.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_esc.add_theme_constant_override("shadow_offset_x", 2)
	label_esc.add_theme_constant_override("shadow_offset_y", 2)
	label_esc.set_anchors_preset(Control.PRESET_CENTER)
	label_esc.position.y += 200
	label_esc.position.x -= 100
	canvas.add_child(label_esc)
	
	await get_tree().create_timer(1.5).timeout
	get_tree().paused = true

var temblando: bool = false

func iniciar_temblor(intensidad: float = 5.0) -> void:
	if temblando:
		return
	temblando = true
	var pos_original = camara.position
	while temblando:
		var offset = Vector2(
			randf_range(-intensidad, intensidad),
			randf_range(-intensidad, intensidad)
		)
		camara.position = pos_original + offset
		await get_tree().create_timer(0.05).timeout
	camara.position = pos_original

func detener_temblor() -> void:
	temblando = false
