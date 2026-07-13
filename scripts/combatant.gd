class_name Combatant
extends Node3D

@export var combatant_name := "Unit"
@export var max_hp := 100
@export var max_mana := 0
@export var basic_dmg_min := 4
@export var basic_dmg_max := 9

@export_group("Visual")
@export var model_fbx: PackedScene
@export var model_anims: AnimationLibrary
@export var model_cor: Color = Color(0.85, 0.72, 0.62)
@export var model_partes: Array[PackedScene] = []
@export var model_texturas: Array[Texture2D] = []
@export var model_arma_fbx: PackedScene
@export var model_arma_tex: Texture2D
@export var model_arma_offset := Vector3.ZERO
@export var model_arma_rot := Vector3.ZERO
@export var model_arma_escala := 1.0

var vitals: Vitals
var _mesh: MeshInstance3D
var _model: CharacterModel

func preparar() -> void:
	vitals = Vitals.new(max_hp, max_mana)
	if model_fbx != null:
		_model = CharacterModel.new()
		_model.skeleton_fbx = model_fbx
		_model.anim_lib = model_anims
		_model.cor = model_cor
		_model.partes = model_partes
		_model.texturas = model_texturas
		_model.arma_fbx = model_arma_fbx
		_model.arma_tex = model_arma_tex
		_model.arma_offset = model_arma_offset
		_model.arma_rot = model_arma_rot
		_model.arma_escala = model_arma_escala
		add_child(_model)
		_model.montar()
	elif _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.mesh = CapsuleMesh.new()
		add_child(_mesh)

func set_cor(c: Color) -> void:
	if _mesh == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	_mesh.material_override = m

func tocar_anim(nome: String) -> void:
	if _model != null:
		_model.tocar(nome)

func ajustar_arma(offset: Vector3, rot: Vector3, escala: float) -> void:
	if _model != null:
		_model.ajustar_arma(offset, rot, escala)

func adicionar_barra_flutuante(largura := 0.9, altura := 0.12, altura_cabeca := 2.0, cor_hp := Color(0.2, 0.85, 0.25)) -> void:
	var barra := BarraVida3D.new()
	barra.position = Vector3(0, altura_cabeca, 0)
	add_child(barra)
	barra.setup(self, largura, altura, cor_hp)

func esta_vivo() -> bool:
	return vitals != null and vitals.esta_vivo()

func receber_dano(a: int) -> void:
	if vitals == null:
		return
	vitals.receber_dano(a)
	if not vitals.esta_vivo():
		tocar_anim("die")
	elif _model != null:
		_model.tocar_damage() # uma reacao aleatoria

func rolar_dano_basico() -> int:
	return CombatMath.rolar_dano(basic_dmg_min, basic_dmg_max)
