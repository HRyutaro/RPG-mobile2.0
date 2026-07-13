class_name LanesChao
extends Node3D
## 3 faixas no chao (uma por lane). Invisiveis por padrao; "pintam" a lane
## ameacada durante o ataque inimigo (telegrafo no mundo, nao na tela).

const LANE_W := 2.0

var _lanes := {}

func montar(z_centro := -3.0) -> void:
	for lane in [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.9, 12.0)
		mi.mesh = q
		mi.rotation_degrees.x = -90.0 # deita no chao (encara +Y)
		mi.position = Vector3(lane * LANE_W, 0.03, z_centro)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.visible = false
		add_child(mi)
		_lanes[lane] = mi

func mostrar(lanes: Array) -> void:
	for lane in _lanes:
		_lanes[lane].visible = lanes.has(lane)

func esconder() -> void:
	for lane in _lanes:
		_lanes[lane].visible = false
