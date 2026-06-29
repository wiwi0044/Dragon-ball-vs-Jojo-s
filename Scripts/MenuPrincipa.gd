extends Control

@onready var musica: AudioStreamPlayer = $Musica

func _ready() -> void:
	musica.stream = preload("res://Assets/Luchadores/goku/sonidos/8Bits_DbzOpening.mp3")
	musica.play()

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SeleccionPersonaje.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
