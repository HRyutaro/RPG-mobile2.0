class_name BarraVida3D
extends Node3D
## Barra de vida flutuante acima da cabeca (encara a camera).
## Verde normal, vermelha em estado critico (<=10%). Barra de mana azul se houver.

var _c
var _larg := 0.9
var _alt := 0.12
var _cor_hp := Color(0.2, 0.85, 0.25)
var _hp_fill: MeshInstance3D
var _mp_fill: MeshInstance3D

func setup(combatente, largura := 0.9, altura := 0.12, cor_hp := Color(0.2, 0.85, 0.25)) -> void:
	_c = combatente
	_larg = largura
	_alt = altura
	_cor_hp = cor_hp
	_quad(Color(0, 0, 0, 0.8), _larg, _alt, 0.0, 0.0)               # fundo hp
	_hp_fill = _quad(cor_hp, _larg, _alt, 0.005, 0.0)
	if _c != null and _c.max_mana > 0:
		var yoff := -_alt * 1.25
		_quad(Color(0, 0, 0, 0.75), _larg, _alt * 0.7, 0.0, yoff)    # fundo mana
		_mp_fill = _quad(Color(0.25, 0.5, 0.95, 1.0), _larg, _alt * 0.7, 0.005, yoff)

func _quad(cor: Color, w: float, h: float, zoff: float, yoff: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	mi.mesh = q
	mi.position = Vector3(0, yoff, zoff)
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	add_child(mi)
	return mi

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		var alvo := cam.global_position
		alvo.y = global_position.y
		if global_position.distance_to(alvo) > 0.01:
			look_at(alvo, Vector3.UP)
	if _c == null or _c.vitals == null:
		return
	visible = _c.esta_vivo()
	var v = _c.vitals
	var r := clampf(float(v.hp) / float(maxi(1, v.max_hp)), 0.0, 1.0)
	_fill(_hp_fill, r)
	var mat: StandardMaterial3D = _hp_fill.material_override
	mat.albedo_color = Color(1.0, 0.15, 0.15) if r <= 0.1 else _cor_hp
	if _mp_fill != null:
		_fill(_mp_fill, clampf(float(v.mana) / float(maxi(1, v.max_mana)), 0.0, 1.0))

func _fill(mi: MeshInstance3D, r: float) -> void:
	var q: QuadMesh = mi.mesh
	q.size = Vector2(_larg * r, q.size.y)
	mi.position.x = -_larg * (1.0 - r) * 0.5
