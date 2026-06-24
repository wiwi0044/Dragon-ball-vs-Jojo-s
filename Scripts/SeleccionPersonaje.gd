extends Control

var personajes = ["goku", "jotaro"]
var escenarios = [
	{"nombre": "Coliseo", "ruta": "res://Assets/fondos/EscenarioColiseo.png"},
	{"nombre": "Morioh", "ruta": "res://Assets/fondos/moriohEscenario.png"},
	{"nombre": "Torneo", "ruta": "res://Assets/fondos/torneo.png"},
]

var personaje_j1: String = ""
var personaje_j2: String = ""
var cursor_j1: int = 0
var cursor_j2: int = 0
var confirmado_j1: bool = false
var confirmado_j2: bool = false
var cursor_escenario: int = 0

@onready var imagen_escenario: TextureRect = $CenterContainer/VBoxContainer/EscenarioPanel/ImagenEscenario
@onready var label_escenario: Label = $CenterContainer/VBoxContainer/LabelEscenario
@onready var boton_comenzar: Button = $CenterContainer/VBoxContainer/BotonComenzar
@onready var imagen_j1: TextureRect = $ImagenJ1
@onready var imagen_j2: TextureRect = $ImagenJ2
@onready var panel_goku: PanelContainer = $IconoGokuPanel
@onready var panel_jotaro: PanelContainer = $IconoJotaroPanel
@onready var icono_goku: TextureRect = $IconoGokuPanel/IconoGoku
@onready var icono_jotaro: TextureRect = $IconoJotaroPanel/IconoJotaro
@onready var escenario_panel: PanelContainer = $CenterContainer/VBoxContainer/EscenarioPanel

var iconos: Array = []
var paneles: Array = []

func _ready() -> void:
	boton_comenzar.disabled = true
	iconos = [icono_goku, icono_jotaro]
	paneles = [panel_goku, panel_jotaro]

	for i in iconos.size():
		iconos[i].texture = load("res://Assets/Luchadores/" + personajes[i] + "/icono.png")
		iconos[i].mouse_filter = Control.MOUSE_FILTER_IGNORE

	imagen_escenario.texture = load(escenarios[0]["ruta"])
	imagen_escenario.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	imagen_escenario.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_j1.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	imagen_j1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_j2.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	imagen_j2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_resaltar()
	_actualizar_escenario()

func _input(event: InputEvent) -> void:
	if not confirmado_j1:
		if Input.is_action_just_pressed("izquierdaJ1"):
			cursor_j1 = (cursor_j1 - 1 + personajes.size()) % personajes.size()
			_resaltar()
		if Input.is_action_just_pressed("derechaJ1"):
			cursor_j1 = (cursor_j1 + 1) % personajes.size()
			_resaltar()
		if Input.is_action_just_pressed("golpeJ1"):
			confirmado_j1 = true
			personaje_j1 = personajes[cursor_j1]
			imagen_j1.texture = load("res://Assets/Luchadores/" + personaje_j1 + "/preview.png")
			_resaltar()
			_verificar_seleccion()

	if not confirmado_j2:
		if Input.is_action_just_pressed("izquierdaJ2"):
			cursor_j2 = (cursor_j2 - 1 + personajes.size()) % personajes.size()
			_resaltar()
		if Input.is_action_just_pressed("derechaJ2"):
			cursor_j2 = (cursor_j2 + 1) % personajes.size()
			_resaltar()
		if Input.is_action_just_pressed("golpeJ2"):
			confirmado_j2 = true
			personaje_j2 = personajes[cursor_j2]
			imagen_j2.texture = load("res://Assets/Luchadores/" + personaje_j2 + "/preview.png")
			_resaltar()
			_verificar_seleccion()

	if confirmado_j1 and Input.is_action_just_pressed("cubrirseJ1"):
		confirmado_j1 = false
		personaje_j1 = ""
		imagen_j1.texture = null
		_resaltar()
		_verificar_seleccion()

	if confirmado_j2 and Input.is_action_just_pressed("cubrirseJ2"):
		confirmado_j2 = false
		personaje_j2 = ""
		imagen_j2.texture = null
		_resaltar()
		_verificar_seleccion()

	# navegar escenarios con arriba/abajo J1
	if Input.is_action_just_pressed("arribaJ1"):
		cursor_escenario = (cursor_escenario - 1 + escenarios.size()) % escenarios.size()
		_actualizar_escenario()
	if Input.is_action_just_pressed("abajoJ1"):
		cursor_escenario = (cursor_escenario + 1) % escenarios.size()
		_actualizar_escenario()

func _actualizar_escenario() -> void:
	imagen_escenario.texture = load(escenarios[cursor_escenario]["ruta"])
	label_escenario.text = escenarios[cursor_escenario]["nombre"]
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.3)
	estilo.border_color = Color(1, 0.8, 0, 1)
	estilo.set_border_width_all(4)
	escenario_panel.add_theme_stylebox_override("panel", estilo)

func _resaltar() -> void:
	for i in paneles.size():
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(0, 0, 0, 0.3)
		if i == cursor_j1 and i == cursor_j2:
			estilo.border_color = Color(1, 1, 0, 1)
			estilo.set_border_width_all(5)
		elif i == cursor_j1:
			estilo.border_color = Color(0, 0.8, 1, 1) if confirmado_j1 else Color(0.2, 0.5, 1, 1)
			estilo.set_border_width_all(5)
		elif i == cursor_j2:
			estilo.border_color = Color(1, 0.5, 0, 1) if confirmado_j2 else Color(1, 0.2, 0.2, 1)
			estilo.set_border_width_all(5)
		else:
			estilo.border_color = Color(0.3, 0.3, 0.3, 1)
			estilo.set_border_width_all(2)
		paneles[i].add_theme_stylebox_override("panel", estilo)

func _verificar_seleccion() -> void:
	boton_comenzar.disabled = not confirmado_j1 or not confirmado_j2

func _on_boton_comenzar_pressed() -> void:
	GlobalData.personaje_j1 = personaje_j1
	GlobalData.personaje_j2 = personaje_j2
	GlobalData.escenario = escenarios[cursor_escenario]["nombre"]
	get_tree().change_scene_to_file("res://Scenes/Pelea.tscn")
