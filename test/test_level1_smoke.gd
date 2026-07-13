extends GutTest

func test_level1_instancia_sem_erro():
	var cena = load("res://scenes/Level1.tscn")
	assert_not_null(cena)
	var inst = cena.instantiate()
	add_child_autofree(inst)
	await wait_frames(3)
	# _ready montou o mundo: ambiente + player + inimigos + sistemas
	assert_gt(inst.get_child_count(), 0, "Level1 montou nodes filhos")
	var players = inst.find_children("*", "PlayerCombatant", true, false)
	assert_gt(players.size(), 0, "ha um PlayerCombatant na cena")
	var enemies = inst.find_children("*", "EnemyCombatant", true, false)
	assert_gt(enemies.size(), 0, "ha ao menos 1 EnemyCombatant na cena")
	var floresta = inst.find_children("*", "CenarioFloresta", true, false)
	assert_gt(floresta.size(), 0, "ha floresta no Level1")
	if floresta.size() > 0:
		assert_gt(floresta[0].get_child_count(), 0, "floresta tem props")
	var alvos = inst.find_children("*", "TargetingController", true, false)
	assert_gt(alvos.size(), 0, "ha TargetingController no Level1")
