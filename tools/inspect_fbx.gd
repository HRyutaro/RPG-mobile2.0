extends SceneTree

func _init() -> void:
	for p in [
		"res://models/personagem/female/Female_Animation_Skeleton.FBX",
		"res://models/personagem/female/Female_Base_Torso.FBX",
		"res://models/personagem/female/Female_Base_Legs.FBX",
		"res://models/personagem/female/Female_Head_1.FBX",
		"res://models/personagem/female/anim/Female_Animation@Female_Idle.FBX",
		"res://models/personagem/female/anim/Female_Animation@Female_Sword_Attacks.FBX",
	]:
		_inspect(p)
	quit()

func _inspect(path: String) -> void:
	print("\n=== ", path, " ===")
	var ps = load(path)
	if ps == null:
		print("  FALHOU AO CARREGAR")
		return
	var inst = ps.instantiate()
	_walk(inst, 0)
	inst.free()

func _walk(n: Node, d: int) -> void:
	var extra := ""
	if n is MeshInstance3D and n.mesh != null:
		extra = " MESH surfaces=%d aabb_size=%s" % [n.mesh.get_surface_count(), str(n.mesh.get_aabb().size)]
	elif n is Skeleton3D:
		extra = " SKELETON bones=%d" % n.get_bone_count()
	elif n is AnimationPlayer:
		extra = " ANIMPLAYER anims=%s" % str(n.get_animation_list())
	print("  ".repeat(d), n.name, " [", n.get_class(), "]", extra)
	for c in n.get_children():
		_walk(c, d + 1)
