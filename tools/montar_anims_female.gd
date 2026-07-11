extends SceneTree
## Extrai "Take 001" de cada FBX de animacao Female e monta uma AnimationLibrary
## renomeada (idle/attack/damage/die), salva em res://models/personagem/female/female_anims.res

const BASE := "res://models/personagem/female/anim/"

func _init() -> void:
	var lib := AnimationLibrary.new()
	_add(lib, "idle", BASE + "Female_Animation@Female_Idle.FBX", true)
	_add(lib, "attack", BASE + "Female_Animation@Female_Sword_Attacks.FBX", false)
	_add(lib, "damage", BASE + "Female_Animation@Female_Sword_Damage.FBX", false)
	_add(lib, "die", BASE + "Female_Animation@Female_Sword_Die.FBX", false)
	var err := ResourceSaver.save(lib, "res://models/personagem/female/female_anims.res")
	print("[montar_anims] salvo err=", err, " anims=", lib.get_animation_list())
	quit()

func _add(lib: AnimationLibrary, nome: String, fbx: String, loop: bool) -> void:
	var ps = load(fbx)
	if ps == null:
		print("  FALHOU: ", fbx); return
	var inst = ps.instantiate()
	var ap: AnimationPlayer = inst.get_node_or_null("AnimationPlayer")
	if ap == null:
		print("  sem AnimationPlayer: ", fbx); inst.free(); return
	var lista = ap.get_animation_list()
	if lista.is_empty():
		print("  sem animacoes: ", fbx); inst.free(); return
	var anim: Animation = ap.get_animation(lista[0]).duplicate()
	if loop:
		anim.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation(nome, anim)
	print("  + ", nome, " len=", "%.2f" % anim.length, "s tracks=", anim.get_track_count())
	inst.free()
