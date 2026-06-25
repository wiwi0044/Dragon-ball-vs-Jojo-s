extends PersonajeBaseDBZ

func _ready() -> void:
	super._ready()

func _on_cambiar_estado(nuevo_estado: Estado) -> void:
	match nuevo_estado:
		Estado.IDLE:
			sprite.play("default")
			anim_player.play("idle")
		Estado.GOLPE1:
			sprite.play("golpe1")
			anim_player.play("golpe1")
		_:
			super._on_cambiar_estado(nuevo_estado)

func _on_animation_finished() -> void:
	super._on_animation_finished()
	if anim_player.is_playing():
		anim_player.stop()
