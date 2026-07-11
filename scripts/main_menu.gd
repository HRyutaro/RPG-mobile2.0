extends Control

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.5
	vb.anchor_top = 0.5
	vb.position = Vector2(-100, -80)
	add_child(vb)
	vb.add_child(_btn("Novo Jogo", func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")))
	vb.add_child(_btn("Sair", func(): get_tree().quit()))

func _btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(200, 48)
	b.pressed.connect(cb)
	return b
