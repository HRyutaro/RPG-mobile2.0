class_name Level1
extends Node3D

const LANE_WIDTH := 2.0

var _battle: BattleController
var _reaction: ReactionController
var _swipe: SwipeInput
var _ui: ArenaUI
var _player: PlayerCombatant
var _enemies: Array[EnemyCombatant] = []

func _ready() -> void:
	_montar_ambiente()
	_spawn_player()
	_spawn_enemies()
	_montar_sistemas()
	_battle.iniciar()

func _montar_ambiente() -> void:
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(40, 40)
	chao.mesh = pm
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.28, 0.45, 0.22)
	chao.material_override = mat
	add_child(chao)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.5, 8)
	cam.rotation_degrees = Vector3(-25, 0, 0)
	add_child(cam)

	# floresta ao redor da arena (centro entre heroi e inimigos)
	var floresta := CenarioFloresta.new()
	add_child(floresta)
	floresta.montar(Vector3(0, 0, -3))

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
	_player.model_partes = Personagens.partes_female()
	_player.model_texturas = Personagens.tex_female()
	_player.position = Vector3(0, 0, 0)
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
		e.model_fbx = Personagens.skeleton_male()
		e.model_anims = Personagens.anims_male()
		e.model_partes = Personagens.partes_male()
		e.model_texturas = Personagens.tex_male()
		e.position = Vector3(-2.0 + i * 2.0, 0, -6)
		# inimigos olham para o jogador
		e.rotation_degrees = Vector3(0, 180, 0)
		add_child(e)
		e.preparar()
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
	_reaction.telegraph_show = func(lanes): _ui.mostrar_telegrafo(lanes)
	_reaction.telegraph_hide = func(): _ui.esconder_telegrafo()
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
