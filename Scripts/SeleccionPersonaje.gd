extends Control

var personaje_j1: String = ""
var personaje_j2: String = ""
var escenario: String = ""

@onready var imagen_j1: TextureRect = $HBoxContainer/PanelJugador1/ImagenJ1
@onready var imagen_j2: TextureRect = $HBoxContainer/PanelJugador2/ImagenJ2
@onready var imagen_escenario: TextureRect = $HBoxContainer/PanelEscenario/ImagenEscenario
@onready var boton_comenzar: Button = $BotonComenzar

var texturas_personajes = {
	"goku": preload("res://Assets/Luchadores/goku/preview.png"),
	"jotaro": preload("res://Assets/Luchadores/jotaro/preview.png")
}

func _ready() -> void:
	boton_comenzar.disabled = true	

func _verificar_seleccion() -> void:
	boton_comenzar.disabled = personaje_j1 == "" or personaje_j2 == ""



func _on_jotaro_pressed() -> void:
	personaje_j1 = "jotaro"
	imagen_j1.texture = texturas_personajes["jotaro"]
	_verificar_seleccion()

func _on_goku_pressed() -> void:
	personaje_j1 = "goku"
	imagen_j1.texture = texturas_personajes["goku"]
	_verificar_seleccion()

func _on_boton_goku_j_2_pressed() -> void:
	personaje_j2 = "goku"
	imagen_j2.texture = texturas_personajes["goku"]
	_verificar_seleccion()
	
func _on_boton_jotaro_j_2_pressed() -> void:
	personaje_j2 = "jotaro"
	imagen_j2.texture = texturas_personajes["jotaro"]
	_verificar_seleccion()


func _on_boton_comenzar_pressed() -> void:
	GlobalData.personaje_j1 = personaje_j1
	GlobalData.personaje_j2 = personaje_j2
	get_tree().change_scene_to_file("res://Scenes/Pelea.tscn")
