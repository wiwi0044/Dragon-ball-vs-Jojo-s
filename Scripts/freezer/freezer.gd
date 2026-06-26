extends PersonajeBaseDBZ

func _ready() -> void:
	super._ready()

func orientar_a_oponente() -> void:
	super.orientar_a_oponente()

func _on_cambiar_estado(nuevo_estado: Estado) -> void:
	match nuevo_estado:
		Estado.IDLE:
			sprite.play("default")
		Estado.ADELANTE:
			sprite.play("adelante")
		Estado.ATRAS:
			sprite.play("atras")
		Estado.BAJAR:
			sprite.play("bajar")
		Estado.RAPIDO_ADELANTE:
			sprite.play("rapidoAdelante")
		Estado.GOLPE1:
			sprite.play("golpe1")
			anim_player.play("golpe1")
		Estado.GOLPE2:
			anim_player.play("golpe2")
			sprite.play("golpe2")
		Estado.GOLPE3:
			sprite.play("golpe3")
			anim_player.play("golpe3")
		Estado.PATADA1:
			sprite.play("patada1")
			anim_player.play("patada1")
		_:
			super._on_cambiar_estado(nuevo_estado)

func _on_animation_finished() -> void:
	if estado_actual == Estado.PATADA1:
		hitbox_shape.disabled = true
		siguiente_patada = 0
		cambiar_estado(Estado.IDLE)
		return
	super._on_animation_finished()
	if anim_player.is_playing():
		anim_player.stop()
