extends SceneTree

func _init() -> void:
	var lib = load("res://models/personagem/female/female_anims.res")
	var fbx = load("res://models/personagem/female/Female_Animation_Skeleton.FBX")
	var cm = CharacterModel.new()
	cm.skeleton_fbx = fbx
	cm.anim_lib = lib
	root.add_child(cm)
	cm.montar()

	var skel: Skeleton3D = cm.get_skeleton()
	var ap: AnimationPlayer = cm.get_anim_player()
	print("[verify] bones=", skel.get_bone_count() if skel else -1, " anims=", ap.get_animation_list() if ap else [])

	# prova: quantos ossos mudam de pose ao avancar a animacao
	var rest_poses := []
	for i in skel.get_bone_count():
		rest_poses.append(skel.get_bone_pose_rotation(i))
	ap.play("attack")
	ap.advance(1.2)
	var mudaram := 0
	for i in skel.get_bone_count():
		if not rest_poses[i].is_equal_approx(skel.get_bone_pose_rotation(i)):
			mudaram += 1
	print("[verify] tocando=", ap.is_playing(), " pos=", "%.2f" % ap.current_animation_position, " ossos_que_mudaram=", mudaram, "/", skel.get_bone_count())
	print("[verify] primeiro track path=", ap.get_animation("attack").track_get_path(0))

	# orientacao/altura aproximada via posicoes globais dos ossos
	var min_y := INF
	var max_y := -INF
	var min_z := INF
	var max_z := -INF
	for i in skel.get_bone_count():
		var p: Vector3 = skel.global_transform * skel.get_bone_global_pose(i).origin
		min_y = min(min_y, p.y); max_y = max(max_y, p.y)
		min_z = min(min_z, p.z); max_z = max(max_z, p.z)
	print("[verify] extensao Y=", "%.2f" % (max_y - min_y), " Z=", "%.2f" % (max_z - min_z), " (Y>>Z = em pe)")
	quit()
