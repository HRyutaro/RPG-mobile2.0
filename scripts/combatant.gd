class_name Combatant
extends Node3D

@export var combatant_name := "Unit"
@export var max_hp := 100
@export var max_mana := 0
@export var basic_dmg_min := 4
@export var basic_dmg_max := 9

var vitals: Vitals
var _mesh: MeshInstance3D

func preparar() -> void:
	vitals = Vitals.new(max_hp, max_mana)
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.mesh = CapsuleMesh.new()
		add_child(_mesh)

func set_cor(c: Color) -> void:
	if _mesh == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	_mesh.material_override = m

func esta_vivo() -> bool:
	return vitals != null and vitals.esta_vivo()

func receber_dano(a: int) -> void:
	if vitals != null:
		vitals.receber_dano(a)

func rolar_dano_basico() -> int:
	return CombatMath.rolar_dano(basic_dmg_min, basic_dmg_max)
