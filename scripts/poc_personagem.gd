extends Node3D
## POC visual: mostra o personagem Female importado ciclando as animacoes.
## Abrir scenes/PocPersonagem.tscn e rodar (F6).

var _cm: CharacterModel
var _label: Label
var _anims := ["idle", "attack", "damage", "die"]
var _idx := 0

func _ready() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 3.0)
	cam.rotation_degrees = Vector3(-12, 0, 0)
	add_child(cam)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -40, 0)
	add_child(luz)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.15, 0.19)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.55)
	we.environment = env
	add_child(we)

	_cm = CharacterModel.new()
	_cm.skeleton_fbx = Personagens.skeleton_female()
	_cm.anim_lib = Personagens.anims_female()
	_cm.partes = Personagens.partes_female()
	_cm.texturas = Personagens.tex_female()
	add_child(_cm)
	_cm.montar()

	var ci := CanvasLayer.new()
	add_child(ci)
	_label = Label.new()
	_label.position = Vector2(24, 20)
	_label.add_theme_font_size_override("font_size", 30)
	ci.add_child(_label)

	var t := Timer.new()
	t.wait_time = 3.0
	t.autostart = true
	t.timeout.connect(_proximo)
	add_child(t)
	_mostrar()

func _proximo() -> void:
	_idx = (_idx + 1) % _anims.size()
	_mostrar()

func _mostrar() -> void:
	_cm.tocar(_anims[_idx])
	_label.text = "Anim: %s" % _anims[_idx]
