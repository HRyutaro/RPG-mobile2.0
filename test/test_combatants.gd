extends GutTest

func test_combatant_prepara_vitals():
	var c = Combatant.new()
	c.max_hp = 10
	add_child_autofree(c)
	c.preparar()
	assert_eq(c.vitals.hp, 10)
	assert_true(c.esta_vivo())
	c.receber_dano(10)
	assert_false(c.esta_vivo())

func test_player_move_lane():
	var p = PlayerCombatant.new()
	add_child_autofree(p)
	p.preparar()
	p.mover_para(CombatEnums.Lane.LEFT)
	assert_eq(p.lane_atual, CombatEnums.Lane.LEFT)
	assert_almost_eq(p.position.x, -2.0, 0.001)

func test_enemy_escolhe_ataque():
	var e = EnemyCombatant.new()
	add_child_autofree(e)
	var atk = AtaqueInimigo.new()
	var lista: Array[AtaqueInimigo] = [atk]
	e.ataques = lista
	assert_eq(e.escolher_ataque(func(_a, _b): return 0), atk)
