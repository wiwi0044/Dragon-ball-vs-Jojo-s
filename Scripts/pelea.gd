extends Node2D

var escenas_personajes = {
	"goku": preload("res://Scenes/goku/base/Personaje.tscn"),
	"jotaro": preload("res://Scenes/jotario/JotaroChar.tscn")
}

@onready var spawn_j1: Marker2D = $SpawnJ1
@onready var spawn_j2: Marker2D = $SpawnJ2

func _ready() -> void:
	for limite in $LimitesEscena.get_children():
		limite.collision_layer = 4
		limite.collision_mask = 0
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

	$"CanvasLayer/PanelContainer/HBoxContainer/TextureRect".texture = load("res://Assets/Luchadores/" + GlobalData.personaje_j1 + "/preview.png")
	$"CanvasLayer2/PanelContainer/HBoxContainer/TextureRect".texture = load("res://Assets/Luchadores/" + GlobalData.personaje_j2 + "/preview.png")

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
