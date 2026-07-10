extends GutTest

func test_rolar_dano_dentro_dos_limites():
	for i in 50:
		var d = CombatMath.rolar_dano(4, 9)
		assert_between(d, 4, 9)

func test_rolar_dano_rng_injetado():
	var d = CombatMath.rolar_dano(5, 10, func(mn, mx): return mn)
	assert_eq(d, 5)

func test_rng_recebe_max_exclusivo():
	# Array como wrapper: lambdas em GDScript capturam por valor, então
	# mutamos um tipo referencia para observar o argumento recebido.
	var capturado := [-1]
	CombatMath.rolar_dano(3, 7, func(mn, mx): capturado[0] = mx; return mn)
	assert_eq(capturado[0], 8)

func test_dano_contra_uma_vez_e_meia():
	assert_eq(CombatMath.dano_contra(10), 15)
	assert_eq(CombatMath.dano_contra(6), 9)
