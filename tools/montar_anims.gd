extends SceneTree
## Monta as AnimationLibrary de Female e Male a partir dos FBX de animacao.
## Salva female_anims.res e male_anims.res.

func _init() -> void:
	_lib_female()
	_lib_male()
	quit()

func _lib_female() -> void:
	var base := "res://models/personagem/female/anim/"
	var lib := AnimationLibrary.new()
	_add(lib, "idle", base + "Female_Animation@Female_Idle.FBX", true)
	_add(lib, "attack", base + "Female_Animation@Female_Sword_Attacks.FBX", false)
	_add(lib, "damage", base + "Female_Animation@Female_Sword_Damage.FBX", false)
	_add(lib, "die", base + "Female_Animation@Female_Sword_Die.FBX", false)
	var err := ResourceSaver.save(lib, "res://models/personagem/female/female_anims.res")
	print("[anims] female err=", err, " ", lib.get_animation_list())

func _lib_male() -> void:
	var base := "res://models/personagem/male/anim/"
	var lib := AnimationLibrary.new()
	_add(lib, "idle", base + "Male_Animation@Male_Idle.FBX", true)
	_add(lib, "attack", base + "Male_Animation@Male_Attacks.FBX", false)
	_add(lib, "damage", base + "Male_Animation@Male_Damage.FBX", false)
	_add(lib, "die", base + "Male_Animation@Male_Die.FBX", false)
	var err := ResourceSaver.save(lib, "res://models/personagem/male/male_anims.res")
	print("[anims] male err=", err, " ", lib.get_animation_list())

func _add(lib: AnimationLibrary, nome: String, fbx: String, loop: bool) -> void:
	var ps = load(fbx)
	if ps == null:
		print("  FALHOU: ", fbx); return
	var inst = ps.instantiate()
	var ap: AnimationPlayer = inst.get_node_or_null("AnimationPlayer")
	if ap == null or ap.get_animation_list().is_empty():
		print("  sem anim: ", fbx); inst.free(); return
	var anim: Animation = ap.get_animation(ap.get_animation_list()[0]).duplicate()
	if loop:
		anim.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation(nome, anim)
	inst.free()
