class_name BarraVida3D
extends Label3D
## Vida flutuante acima da cabeca (billboard, sempre encara a camera).

var _c

func setup(combatente) -> void:
	_c = combatente
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	pixel_size = 0.0016
	font_size = 96
	outline_size = 24
	outline_modulate = Color(0, 0, 0, 0.9)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(_dt: float) -> void:
	if _c == null or _c.vitals == null:
		return
	var v = _c.vitals
	text = "%d/%d" % [v.hp, v.max_hp]
	modulate = Color(1.0, 0.4, 0.35) if v.hp <= 1 else Color(0.85, 1.0, 0.6)
	visible = _c.esta_vivo()
