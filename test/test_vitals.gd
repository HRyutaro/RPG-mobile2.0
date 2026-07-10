extends GutTest

func test_nasce_cheio():
	var v = Vitals.new(100, 50)
	assert_eq(v.hp, 100)
	assert_eq(v.mana, 50)
	assert_true(v.esta_vivo())

func test_dano_nao_fica_negativo():
	var v = Vitals.new(30, 0)
	v.receber_dano(50)
	assert_eq(v.hp, 0)
	assert_false(v.esta_vivo())

func test_gastar_mana_falha_se_insuficiente():
	var v = Vitals.new(100, 20)
	assert_false(v.gastar_mana(30))
	assert_eq(v.mana, 20)
	assert_true(v.gastar_mana(20))
	assert_eq(v.mana, 0)

func test_restaurar_mana_nao_passa_do_max():
	var v = Vitals.new(100, 50)
	v.gastar_mana(40)
	v.restaurar_mana(100)
	assert_eq(v.mana, 50)

func test_curar_nao_passa_do_max():
	var v = Vitals.new(100, 0)
	v.receber_dano(60)
	v.curar(100)
	assert_eq(v.hp, 100)
