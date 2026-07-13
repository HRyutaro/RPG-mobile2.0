class_name Level1
extends Node3D

const LANE_WIDTH := 2.0

## Configuravel no Inspector (selecione o node Level1 na cena)
@export_group("Camera")
@export var cam_pos := Vector3(0, 2.2, 3.8)
@export var cam_rot_deg := Vector3(-12, 0, 0)
@export_range(20, 90) var cam_fov := 58.0
@export_range(0.0, 1.0) var cam_seguir := 0.7 # quanto a camera acompanha a lane do player
@export var cam_seguir_vel := 6.0

@export_group("Barra de vida (inimigos)")
@export var barra_largura := 0.8
@export var barra_altura := 0.11
@export var barra_altura_cabeca := 2.0

@export_group("Posicoes")
@export var inimigos_z := -4.0 # distancia dos inimigos (mais negativo = mais longe)

@export_group("Arma (espada/adaga/cajado) — calibrar aqui")
@export var arma_offset := Vector3.ZERO
@export var arma_rot := Vector3.ZERO
@export var arma_escala := 0.25 # armas vem grandes (~4.5u); 0.25 ~= 1.1u

@export_group("Arco (Gatuna) — segurado diferente")
@export var arco_offset := Vector3.ZERO
@export var arco_rot := Vector3(90, 0, 0) # deita o arco na vertical
@export var arco_escala := 0.2

@export_group("Arma inimigo (macho) — calibrar aqui")
@export var arma_inimigo_offset := Vector3(0, 0, 0.25)
@export var arma_inimigo_rot := Vector3.ZERO
@export var arma_inimigo_escala := 0.2

var _battle: BattleController
var _reaction: ReactionController
var _swipe: SwipeInput
var _ui: ArenaUI
var _lanes_chao: LanesChao
var _cam: Camera3D
var _player: PlayerCombatant
var _enemies: Array[EnemyCombatant] = []

func _ready() -> void:
	_montar_ambiente()
	_spawn_player()
	_spawn_enemies()
	_montar_sistemas()
	_battle.iniciar()

func _process(dt: float) -> void:
	if _cam != null and _player != null:
		var alvo := cam_pos.x + _player.position.x * cam_seguir
		_cam.position.x = lerpf(_cam.position.x, alvo, clampf(dt * cam_seguir_vel, 0.0, 1.0))
	# ajuste de arma em tempo real: edite estes valores na aba Remote durante o Play
	if _player != null:
		if _player.tipo == CombatEnums.CharacterType.GATUNA:
			_player.ajustar_arma(arco_offset, arco_rot, arco_escala)
		else:
			_player.ajustar_arma(arma_offset, arma_rot, arma_escala)
	for e in _enemies:
		if e != null:
			e.ajustar_arma(arma_inimigo_offset, arma_inimigo_rot, arma_inimigo_escala)

func _montar_ambiente() -> void:
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(60, 60)
	chao.mesh = pm
	chao.material_override = _material_grama()
	add_child(chao)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	luz.light_energy = 1.1
	add_child(luz)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.9) # ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.6)
	env.ambient_light_energy = 0.6
	we.environment = env
	add_child(we)

	var cam := Camera3D.new()
	cam.position = cam_pos
	cam.rotation_degrees = cam_rot_deg
	cam.fov = cam_fov
	# mantem a largura (as 3 lanes) sempre visivel; retrato mostra mais na vertical
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(cam)
	_cam = cam

	# floresta: layout fixo com 2 variacoes, clareira central garantida
	var floresta := CenarioFloresta.new()
	add_child(floresta)
	floresta.montar(randi() % 2)

	# faixas de lane no chao (telegrafo do ataque inimigo)
	_lanes_chao = LanesChao.new()
	add_child(_lanes_chao)
	_lanes_chao.montar()

func _material_grama() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var noise := FastNoiseLite.new()
	noise.frequency = 0.9
	var ntex := NoiseTexture2D.new()
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	var grad := Gradient.new()
	grad.set_color(0, Color(0.20, 0.34, 0.16))
	grad.set_color(1, Color(0.36, 0.52, 0.26))
	ntex.color_ramp = grad
	ntex.noise = noise
	mat.albedo_texture = ntex
	mat.uv1_scale = Vector3(16, 16, 1)
	mat.roughness = 1.0
	return mat

func _spawn_player() -> void:
	_player = PlayerCombatant.new()
	_player.tipo = GameState.classe_escolhida
	match _player.tipo:
		CombatEnums.CharacterType.PALADINO:
			_player.combatant_name = "Paladina"; _player.max_hp = 10; _player.max_mana = 60
		CombatEnums.CharacterType.MAGO:
			_player.combatant_name = "Maga"; _player.max_hp = 10; _player.max_mana = 120
		CombatEnums.CharacterType.GATUNA:
			_player.combatant_name = "Gatuna"; _player.max_hp = 10; _player.max_mana = 80
	_player.basic_dmg_min = 1; _player.basic_dmg_max = 2
	_player.model_fbx = Personagens.skeleton_female()
	_player.model_anims = Personagens.anims_female()
	_player.model_partes = Personagens.partes_female(_player.tipo)
	_player.model_texturas = Personagens.tex_female(_player.tipo)
	_player.model_arma_fbx = Personagens.arma_female(_player.tipo)
	_player.model_arma_tex = Personagens.arma_tex()
	if _player.tipo == CombatEnums.CharacterType.GATUNA:
		_player.model_arma_offset = arco_offset
		_player.model_arma_rot = arco_rot
		_player.model_arma_escala = arco_escala
	else:
		_player.model_arma_offset = arma_offset
		_player.model_arma_rot = arma_rot
		_player.model_arma_escala = arma_escala
	_player.position = Vector3(0, 0, 0)
	_player.rotation_degrees = Vector3(0, 180, 0) # encara os inimigos (-z)
	add_child(_player)
	_player.preparar()
	_player.mover_para(CombatEnums.Lane.CENTER)
	_carregar_habilidades()

func _carregar_habilidades() -> void:
	var dir := "res://data/habilidades/"
	var arquivos := {
		CombatEnums.CharacterType.PALADINO: ["golpe_sagrado.tres", "luz_punitiva.tres"],
		CombatEnums.CharacterType.MAGO: ["bola_de_fogo.tres", "raio_de_luz.tres"],
		CombatEnums.CharacterType.GATUNA: ["rasgar_pele.tres", "laminas_gemeas.tres"],
	}
	var habs: Array[Habilidade] = []
	for f in arquivos[_player.tipo]:
		var h = load(dir + f)
		if h != null: habs.append(h)
	_player.habilidades = habs

func _spawn_enemies() -> void:
	_enemies.clear()
	var atk = load("res://data/ataques/faca.tres")
	var qtd := randi_range(1, 3)
	for i in qtd:
		var e := EnemyCombatant.new()
		e.combatant_name = "Bandido %d" % (i + 1)
		e.max_hp = 3
		e.basic_dmg_min = 1; e.basic_dmg_max = 2
		if atk != null:
			var la: Array[AtaqueInimigo] = [atk]
			e.ataques = la
		var variante := randi() % 3
		e.model_fbx = Personagens.skeleton_male()
		e.model_anims = Personagens.anims_male()
		e.model_partes = Personagens.partes_male(variante)
		e.model_texturas = Personagens.tex_male(variante)
		e.model_arma_fbx = Personagens.arma_male(randi() % 4)
		e.model_arma_tex = Personagens.arma_tex()
		e.model_arma_offset = arma_inimigo_offset
		e.model_arma_rot = arma_inimigo_rot
		e.model_arma_escala = arma_inimigo_escala
		e.position = Vector3(-2.0 + i * 2.0, 0, inimigos_z)
		# inimigos encaram o jogador (+z)
		e.rotation_degrees = Vector3(0, 0, 0)
		add_child(e)
		e.preparar()
		e.adicionar_barra_flutuante(barra_largura, barra_altura, barra_altura_cabeca, Color(0.95, 0.15, 0.15))
		_enemies.append(e)

func _montar_sistemas() -> void:
	_ui = ArenaUI.new()
	add_child(_ui)
	_ui.bind_player(_player)
	_ui.set_enemies(_enemies)
	_ui.popular_habilidades(_player.habilidades)

	_swipe = SwipeInput.new()
	add_child(_swipe)

	_reaction = ReactionController.new()
	_reaction.swipe_input = _swipe
	_reaction.telegraph_show = func(lanes): _lanes_chao.mostrar(lanes)
	_reaction.telegraph_hide = func(): _lanes_chao.esconder()
	_reaction.parry_show = func(v): _ui.mostrar_parry(v)
	add_child(_reaction)

	_battle = BattleController.new()
	_battle.player = _player
	_battle.enemies = _enemies
	_battle.reaction = _reaction
	_battle.ui = _ui
	_battle.itens = _carregar_itens()
	add_child(_battle)

	# fiacao de sinais
	_ui.atacar.connect(_battle._on_atacar)
	_ui.usar_habilidade.connect(_battle._on_habilidade)
	_ui.usar_item.connect(_battle._on_item)
	_ui.parry.connect(_swipe.pressionar_parry)
	_battle.log_msg.connect(_ui.set_log)

func _carregar_itens() -> Array[Item]:
	var res: Array[Item] = []
	for f in ["pocao_de_vida.tres", "pocao_de_mana.tres"]:
		var it = load("res://data/itens/" + f)
		if it != null: res.append(it)
	return res
