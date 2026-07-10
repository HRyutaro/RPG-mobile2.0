extends GutTest

func test_qtd_lanes_pesos():
	assert_eq(EnemyAI.escolher_qtd_lanes(0), 1)
	assert_eq(EnemyAI.escolher_qtd_lanes(49), 1)
	assert_eq(EnemyAI.escolher_qtd_lanes(50), 2)
	assert_eq(EnemyAI.escolher_qtd_lanes(84), 2)
	assert_eq(EnemyAI.escolher_qtd_lanes(85), 3)
	assert_eq(EnemyAI.escolher_qtd_lanes(99), 3)

func test_lanes_distintas():
	var lanes = EnemyAI.escolher_lanes_ameacadas(2, func(_a, _b): return 0)
	assert_eq(lanes.size(), 2)
	assert_ne(lanes[0], lanes[1])

func test_tres_lanes_retorna_todas():
	var lanes = EnemyAI.escolher_lanes_ameacadas(3, func(_a, _b): return 0)
	assert_eq(lanes.size(), 3)
	assert_true(lanes.has(CombatEnums.Lane.LEFT))
	assert_true(lanes.has(CombatEnums.Lane.CENTER))
	assert_true(lanes.has(CombatEnums.Lane.RIGHT))
