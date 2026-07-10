extends GutTest

func _vivo(hp): return hp > 0

func test_single_retorna_so_o_selecionado():
	var r = Targeting.resolver(CombatEnums.TargetMode.SINGLE, 20, [10, 20, 30], _vivo)
	assert_eq(r, [20])

func test_single_selecionado_morto_vazio():
	var r = Targeting.resolver(CombatEnums.TargetMode.SINGLE, 0, [10, 0, 30], _vivo)
	assert_eq(r, [])

func test_aoe_retorna_todos_vivos():
	var r = Targeting.resolver(CombatEnums.TargetMode.AOE, 10, [10, 0, 30], _vivo)
	assert_eq(r, [10, 30])
