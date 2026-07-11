class_name BattleController
extends Node

signal log_msg(txt: String)

var player: PlayerCombatant
var enemies: Array[EnemyCombatant] = []
var reaction: ReactionController
var ui = null # ArenaUI (setado pelo Level1)
var itens: Array[Item] = []
var turn_delay := 0.6

var _alvo: EnemyCombatant
var _ocupado := false

func iniciar() -> void:
	_alvo = _primeiro_vivo()
	_log("Combate iniciado.")
	_turno_jogador()

func _pronto() -> bool:
	return not _ocupado and player != null and player.esta_vivo()

func _turno_jogador() -> void:
	_garantir_alvo()
	if ui != null:
		ui.set_menu_visivel(true)
		ui.set_menu_interativo(true)

func _on_atacar() -> void:
	if not _pronto(): return
	_executar_ataque_basico()

func _on_habilidade(h: Habilidade) -> void:
	if not _pronto(): return
	if not player.vitals.gastar_mana(h.custo_mana):
		_log("Mana insuficiente para %s." % h.nome)
		return
	_executar_habilidade(h)

func _on_item() -> void:
	if not _pronto(): return
	if itens.is_empty():
		_log("Sem itens.")
		return
	var it := itens[0]
	if it.tipo == Item.Tipo.CURA:
		player.vitals.curar(it.quantidade)
	else:
		player.vitals.restaurar_mana(it.quantidade)
	_log("Usou %s." % it.nome)
	_fim_da_acao()

func _executar_ataque_basico() -> void:
	_ocupado = true
	_ui_interativo(false)
	_garantir_alvo()
	if _alvo != null:
		_alvo.receber_dano(player.rolar_dano_basico())
	_fim_da_acao()

func _executar_habilidade(h: Habilidade) -> void:
	_ocupado = true
	_ui_interativo(false)
	_garantir_alvo()
	var vivo := func(e): return e != null and e.esta_vivo()
	var alvos := Targeting.resolver(h.alvo, _alvo, enemies, vivo)
	for a in alvos:
		a.receber_dano(h.gerar_dano())
	_fim_da_acao()

func _fim_da_acao() -> void:
	_ocupado = true
	if _todos_mortos():
		_vitoria(); return
	await get_tree().create_timer(turn_delay).timeout
	await _turno_inimigo()
	if not player.esta_vivo():
		_derrota(); return
	_ocupado = false
	_turno_jogador()

func _turno_inimigo() -> void:
	if ui != null: ui.set_menu_visivel(false)
	for inimigo in enemies:
		if inimigo == null or not inimigo.esta_vivo():
			continue
		var atk := inimigo.escolher_ataque(func(a, b): return randi_range(a, b - 1))
		if atk == null or atk.hits.is_empty():
			continue
		for hit in atk.hits:
			var qtd := EnemyAI.escolher_qtd_lanes(randi_range(0, 99))
			var ameacadas := EnemyAI.escolher_lanes_ameacadas(qtd, func(a, b): return randi_range(a, b - 1))
			_log("%s ataca!" % inimigo.combatant_name)
			var outcome: int = await reaction.rodar_hit(player, inimigo, hit, ameacadas)
			_log(_texto_outcome(outcome))
			if not player.esta_vivo():
				return

func _texto_outcome(o: int) -> String:
	match o:
		CombatEnums.HitOutcome.PARRIED: return "Parry!"
		CombatEnums.HitOutcome.DODGED: return "Esquiva!"
		_: return "Acertou voce!"

func _garantir_alvo() -> void:
	if _alvo != null and _alvo.esta_vivo(): return
	_alvo = _primeiro_vivo()

func _primeiro_vivo() -> EnemyCombatant:
	for e in enemies:
		if e != null and e.esta_vivo(): return e
	return null

func _todos_mortos() -> bool:
	return _primeiro_vivo() == null

func _ui_interativo(v: bool) -> void:
	if ui != null: ui.set_menu_interativo(v)

func _vitoria() -> void:
	_log("Vitoria!"); _ocupado = true
	if ui != null: ui.set_menu_visivel(false)

func _derrota() -> void:
	_log("Game Over."); _ocupado = true
	if ui != null: ui.set_menu_visivel(false)

func _log(txt: String) -> void:
	log_msg.emit(txt)
	print(txt)
