class_name CharacterModel
extends Node3D
## Instancia um esqueleto FBX (com malha) e aplica uma AnimationLibrary.
## Opcional: "veste" pecas modulares (torso/pernas/cabeca) com texturas no
## mesmo esqueleto (os ossos das pecas sao subconjunto do esqueleto principal).

@export var skeleton_fbx: PackedScene
@export var anim_lib: AnimationLibrary
@export var cor: Color = Color(0.85, 0.72, 0.62) # cor chapada quando NAO ha pecas
@export var partes: Array[PackedScene] = []      # FBX das pecas modulares
@export var texturas: Array[Texture2D] = []      # textura de cada peca (paralelo a partes)
@export var arma_fbx: PackedScene
@export var arma_tex: Texture2D
@export var arma_offset := Vector3.ZERO
@export var arma_rot := Vector3.ZERO
@export var arma_escala := 1.0

var _anim: AnimationPlayer
var _skel: Skeleton3D
var _modelo: Node3D
var _arma_mi: MeshInstance3D

func montar() -> void:
	if skeleton_fbx == null:
		return
	_modelo = skeleton_fbx.instantiate()
	add_child(_modelo)
	_skel = _modelo.find_child("Skeleton3D", true, false)

	if partes.is_empty():
		_aplicar_cor_chapada()
	else:
		_vestir_pecas()
	_vestir_arma()

	_anim = AnimationPlayer.new()
	_modelo.add_child(_anim) # parent = modelo: root_node padrao resolve "Skeleton3D:osso"
	if anim_lib != null:
		_anim.add_animation_library("", anim_lib)
	_anim.animation_finished.connect(_ao_terminar)
	tocar("idle")

func _aplicar_cor_chapada() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		mi.visible = true
		mi.material_override = mat

func _vestir_pecas() -> void:
	# esconde a malha base de referencia
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		mi.visible = false
	for i in partes.size():
		if partes[i] == null:
			continue
		var pinst = partes[i].instantiate()
		var fontes = pinst.find_children("*", "MeshInstance3D", true, false)
		if fontes.is_empty():
			pinst.free(); continue
		var src: MeshInstance3D = fontes[0]
		var mi := MeshInstance3D.new()
		mi.mesh = src.mesh
		var mat := StandardMaterial3D.new()
		if i < texturas.size() and texturas[i] != null:
			mat.albedo_texture = texturas[i]
		mi.material_override = mat
		if src.skin != null:
			# remapeia binds nao-resolviveis (ex: cabelo com "Character Head_2")
			# para a cabeca real, para o skin resolver no esqueleto principal
			var skin: Skin = src.skin.duplicate()
			for b in skin.get_bind_count():
				var bn := skin.get_bind_name(b)
				if bn != "" and _skel.find_bone(bn) == -1:
					skin.set_bind_name(b, "Character Head")
			mi.skin = skin
			_skel.add_child(mi)
			mi.skeleton = mi.get_path_to(_skel) # skin resolve pelos nomes de osso
		else:
			var ba := BoneAttachment3D.new()
			ba.bone_name = "Character Head"
			_skel.add_child(ba)
			ba.add_child(mi)
			mi.transform = src.transform
		pinst.free()

func _vestir_arma() -> void:
	if arma_fbx == null or _skel == null:
		return
	var winst = arma_fbx.instantiate()
	var fontes = winst.find_children("*", "MeshInstance3D", true, false)
	if fontes.is_empty():
		winst.free(); return
	var src: MeshInstance3D = fontes[0]
	var mi := MeshInstance3D.new()
	mi.mesh = src.mesh
	if arma_tex != null:
		var m := StandardMaterial3D.new()
		m.albedo_texture = arma_tex
		mi.material_override = m
	var ba := BoneAttachment3D.new()
	ba.bone_name = "Character R Hand"
	_skel.add_child(ba)
	ba.add_child(mi)
	mi.position = arma_offset
	mi.rotation_degrees = arma_rot
	mi.scale = Vector3.ONE * arma_escala
	_arma_mi = mi
	winst.free()

func ajustar_arma(offset: Vector3, rot: Vector3, escala: float) -> void:
	if _arma_mi != null:
		_arma_mi.position = offset
		_arma_mi.rotation_degrees = rot
		_arma_mi.scale = Vector3.ONE * escala

func tocar(nome: String) -> void:
	if _anim != null and _anim.has_animation(nome):
		_anim.speed_scale = 1.0
		_anim.play(nome)

func tocar_damage() -> void:
	# a animacao de dano e uma montagem de varias reacoes; toca UMA aleatoria
	if _anim == null or not _anim.has_animation("damage"):
		return
	var a := _anim.get_animation("damage")
	var seg := 0.85
	var n := maxi(1, int(a.length / seg))
	var i := randi() % n
	_anim.speed_scale = 1.0
	_anim.play("damage")
	_anim.seek(i * seg, true)
	await get_tree().create_timer(seg).timeout
	if _anim != null and _anim.current_animation == "damage":
		tocar("idle")

func _ao_terminar(nome: String) -> void:
	if nome == "die":
		# congela na ultima pose (caido) — senao o esqueleto volta pra rest = "levanta"
		if _anim.has_animation("die"):
			_anim.play("die")
			_anim.seek(_anim.get_animation("die").length, true)
			_anim.speed_scale = 0.0
	elif nome != "idle":
		tocar("idle")

func get_skeleton() -> Skeleton3D:
	return _skel

func get_anim_player() -> AnimationPlayer:
	return _anim
