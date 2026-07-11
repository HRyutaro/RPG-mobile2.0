extends SceneTree
## Gera os .tres de habilidades, ataques e itens via codigo (robusto).
## Rodar: godot --headless --path <proj> -s res://tools/gerar_dados.gd

func _init() -> void:
	_gerar()
	quit()

func _gerar() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/habilidades")
	DirAccess.make_dir_recursive_absolute("res://data/ataques")
	DirAccess.make_dir_recursive_absolute("res://data/itens")

	_hab("golpe_sagrado", "Golpe Sagrado", "Investida sagrada num alvo.", 20, 10, 16, CombatEnums.TargetMode.SINGLE, 0.9)
	_hab("luz_punitiva", "Luz Punitiva", "Explosao de luz em todos os inimigos.", 30, 7, 12, CombatEnums.TargetMode.AOE, 1.0)
	_hab("bola_de_fogo", "Bola de Fogo", "Explosao de fogo em area.", 30, 8, 14, CombatEnums.TargetMode.AOE, 1.0)
	_hab("raio_de_luz", "Raio de Luz", "Feixe concentrado num alvo.", 25, 12, 20, CombatEnums.TargetMode.SINGLE, 0.9)
	_hab("rasgar_pele", "Rasgar Pele", "Corte rapido e sangrento.", 15, 9, 15, CombatEnums.TargetMode.SINGLE, 0.7)
	_hab("laminas_gemeas", "Laminas Gemeas", "Golpe duplo perfurante.", 25, 13, 19, CombatEnums.TargetMode.SINGLE, 0.8)

	_atk("faca", "Ataque de Faca", 2, 3, 0.6, 0.15, 0.25)

	_item("pocao_de_vida", "Pocao de Vida", Item.Tipo.CURA, 30)
	_item("pocao_de_mana", "Pocao de Mana", Item.Tipo.MANA, 30)
	print("[gerar_dados] concluido")

func _hab(file: String, nome: String, desc: String, mana: int, dmin: int, dmax: int, alvo: int, cast: float) -> void:
	var h := Habilidade.new()
	h.nome = nome
	h.descricao = desc
	h.custo_mana = mana
	h.dano_min = dmin
	h.dano_max = dmax
	h.alvo = alvo
	h.cast_time = cast
	ResourceSaver.save(h, "res://data/habilidades/%s.tres" % file)

func _atk(file: String, nome: String, dmin: int, dmax: int, tele: float, pini: float, pdur: float) -> void:
	var a := AtaqueInimigo.new()
	a.nome = nome
	var hit := HitData.new()
	hit.dano_min = dmin
	hit.dano_max = dmax
	hit.telegraph_time = tele
	hit.parry_window_start = pini
	hit.parry_window_duration = pdur
	var lista: Array[HitData] = [hit]
	a.hits = lista
	ResourceSaver.save(a, "res://data/ataques/%s.tres" % file)

func _item(file: String, nome: String, tipo: int, qtd: int) -> void:
	var it := Item.new()
	it.nome = nome
	it.tipo = tipo
	it.quantidade = qtd
	ResourceSaver.save(it, "res://data/itens/%s.tres" % file)
