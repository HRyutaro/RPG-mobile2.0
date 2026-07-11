class_name ReactionController
extends Node

var swipe_input: SwipeInput
var telegraph_show: Callable = func(_lanes): pass
var telegraph_hide: Callable = func(): pass

var _parry_pressed := false
var _parry_time := -999.0
var _janela_ini := 0.0
var _janela_fim := 0.0

func rodar_hit(player: PlayerCombatant, atacante: EnemyCombatant, hit: HitData, ameacadas: Array) -> int:
	_parry_pressed = false
	_parry_time = -999.0
	var t0 := Time.get_ticks_msec() / 1000.0
	_janela_ini = hit.telegraph_time + hit.parry_window_start
	_janela_fim = _janela_ini + hit.parry_window_duration
	var total := _janela_fim

	var on_swipe := func(dir: int):
		player.mover_para(player.lane_atual + dir)
	var on_parry := func():
		_parry_pressed = true
		_parry_time = (Time.get_ticks_msec() / 1000.0) - t0

	swipe_input.swipe.connect(on_swipe)
	swipe_input.parry.connect(on_parry)
	swipe_input.set_ativo(true)
	telegraph_show.call(ameacadas)

	await get_tree().create_timer(total).timeout

	swipe_input.set_ativo(false)
	telegraph_hide.call()
	swipe_input.swipe.disconnect(on_swipe)
	swipe_input.parry.disconnect(on_parry)

	var na_janela := _parry_pressed and _parry_time >= _janela_ini and _parry_time <= _janela_fim
	var outcome := ReactionResolver.resolve(player.lane_atual, ameacadas, _parry_pressed, na_janela)

	match outcome:
		CombatEnums.HitOutcome.HIT:
			player.receber_dano(CombatMath.rolar_dano(hit.dano_min, hit.dano_max))
		CombatEnums.HitOutcome.PARRIED:
			var base := CombatMath.rolar_dano(hit.dano_min, hit.dano_max)
			atacante.receber_dano(CombatMath.dano_contra(base))
	return outcome
