extends Control

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.5
	vb.anchor_top = 0.5
	vb.position = Vector2(-120, -120)
	add_child(vb)
	vb.add_child(_btn("Paladina", CombatEnums.CharacterType.PALADINO))
	vb.add_child(_btn("Maga", CombatEnums.CharacterType.MAGO))
	vb.add_child(_btn("Gatuna", CombatEnums.CharacterType.GATUNA))

func _btn(txt: String, tipo: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(220, 52)
	b.pressed.connect(func():
		GameState.classe_escolhida = tipo
		get_tree().change_scene_to_file("res://scenes/Level1.tscn"))
	return b
