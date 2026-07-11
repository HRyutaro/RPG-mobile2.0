class_name CharacterModel
extends Node3D
## Instancia um esqueleto FBX (com malha) e aplica uma AnimationLibrary.
## Uso: setar skeleton_fbx + anim_lib, chamar montar(), depois tocar("idle"/"attack"/...).

@export var skeleton_fbx: PackedScene
@export var anim_lib: AnimationLibrary

var _anim: AnimationPlayer
var _skel: Skeleton3D
var _modelo: Node3D

func montar() -> void:
	if skeleton_fbx == null:
		return
	_modelo = skeleton_fbx.instantiate()
	add_child(_modelo)
	_skel = _modelo.find_child("Skeleton3D", true, false)
	# a malha base costuma vir escondida ("(Hide)") no Cartoon Heroes
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		mi.visible = true

	_anim = AnimationPlayer.new()
	_modelo.add_child(_anim) # parent = modelo, root_node padrao resolve "Skeleton3D:osso"
	if anim_lib != null:
		_anim.add_animation_library("", anim_lib)
	tocar("idle")

func tocar(nome: String) -> void:
	if _anim != null and _anim.has_animation(nome):
		_anim.play(nome)

func get_skeleton() -> Skeleton3D:
	return _skel

func get_anim_player() -> AnimationPlayer:
	return _anim
