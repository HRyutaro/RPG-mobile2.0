class_name CenarioFloresta
extends Node3D
## Espalha props de floresta (LowpolyNature) num anel ao redor da arena.

const COLORMAP := "res://models/cenario/colormap.png"
const ARVORES := ["SpringTree_01", "SpringTree_02", "SpringTree_03", "SpringTree_04", "SpringTree_05", "SpringTree_06", "FallenTree_01"]
const MIUDOS := ["Bush_01", "Bush_02", "Bush_03", "Rock_01", "Rock_02", "Rock_03", "Mushroom_03", "Mushroom_08"]

var _mat: StandardMaterial3D
var total := 0

func montar(centro: Vector3) -> void:
	seed(20260710)
	_mat = StandardMaterial3D.new()
	_mat.albedo_texture = load(COLORMAP)
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST # atlas de cor: sem bleeding
	# arvores mais afastadas e menores; miudos mais perto
	total += _scatter(ARVORES, centro, 7.0, 20.0, 30, 0.30, 0.45)
	total += _scatter(MIUDOS, centro, 5.0, 13.0, 20, 0.40, 0.75)

func _scatter(nomes: Array, centro: Vector3, r_in: float, r_out: float, qtd: int, s_min: float, s_max: float) -> int:
	var ok := 0
	for i in qtd:
		var nome: String = nomes[randi() % nomes.size()]
		var ps = load("res://models/cenario/%s.fbx" % nome)
		if ps == null:
			continue
		var inst = ps.instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = _mat
		var ang := randf() * TAU
		var r: float = lerpf(r_in, r_out, randf())
		inst.position = centro + Vector3(cos(ang) * r, 0, sin(ang) * r)
		inst.rotation.y = randf() * TAU
		inst.scale = Vector3.ONE * randf_range(s_min, s_max)
		add_child(inst)
		ok += 1
	return ok
