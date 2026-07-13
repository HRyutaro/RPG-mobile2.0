class_name CenarioFloresta
extends Node3D
## Preenche o campo visivel com props de floresta (LowpolyNature),
## evitando a zona de combate central.

const COLORMAP := "res://models/cenario/colormap.png"
const ARVORES := ["SpringTree_01", "SpringTree_02", "SpringTree_03", "SpringTree_04", "SpringTree_05", "SpringTree_06", "FallenTree_01"]
const MIUDOS := ["Bush_01", "Bush_02", "Bush_03", "Rock_01", "Rock_02", "Rock_03", "Mushroom_03", "Mushroom_08"]

# zona de combate a preservar (retangulo folgado em torno de heroi/inimigos/camera)
const COMBATE_X := 6.5
const COMBATE_Z_MIN := -10.0
const COMBATE_Z_MAX := 6.0

var _mat: StandardMaterial3D
var _rng := RandomNumberGenerator.new()
var total := 0

func montar(_centro := Vector3.ZERO) -> void:
	_rng.seed = 20260710 # RNG local: layout estavel sem travar o RNG global (contagem de inimigos)
	_mat = StandardMaterial3D.new()
	_mat.albedo_texture = load(COLORMAP)
	_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED # normais dos FBX podem vir invertidas
	# arvores preenchendo o campo (fundo + flancos) ao redor da clareira — bem denso
	total += _fill(ARVORES, -28.0, 28.0, -36.0, 9.0, 240, 0.28, 0.55)
	# miudos mais perto/densos
	total += _fill(MIUDOS, -20.0, 20.0, -22.0, 9.0, 140, 0.4, 0.8)

func _fill(nomes: Array, x0: float, x1: float, z0: float, z1: float, qtd: int, s_min: float, s_max: float) -> int:
	var ok := 0
	var tentativas := 0
	while ok < qtd and tentativas < qtd * 4:
		tentativas += 1
		var x := _rng.randf_range(x0, x1)
		var z := _rng.randf_range(z0, z1)
		# pula a zona de combate
		if absf(x) < COMBATE_X and z > COMBATE_Z_MIN and z < COMBATE_Z_MAX:
			continue
		var nome: String = nomes[_rng.randi() % nomes.size()]
		var ps = load("res://models/cenario/%s.fbx" % nome)
		if ps == null:
			continue
		var inst = ps.instantiate()
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = _mat
		inst.position = Vector3(x, 0, z)
		inst.rotation.y = _rng.randf() * TAU
		inst.scale = Vector3.ONE * _rng.randf_range(s_min, s_max)
		add_child(inst)
		ok += 1
	return ok
