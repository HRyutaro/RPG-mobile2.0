extends GutTest

func test_direita_simples():
	assert_eq(TargetCycler.proximo([true, true, true], 0, 1), 1)

func test_esquerda_faz_wrap():
	assert_eq(TargetCycler.proximo([true, true, true], 0, -1), 2)

func test_direita_faz_wrap():
	assert_eq(TargetCycler.proximo([true, true, true], 2, 1), 0)

func test_pula_morto():
	assert_eq(TargetCycler.proximo([true, false, true], 0, 1), 2)

func test_um_inimigo_retorna_ele():
	assert_eq(TargetCycler.proximo([true], 0, 1), 0)

func test_atual_morto_acha_vivo():
	assert_eq(TargetCycler.proximo([false, true, false], 0, 1), 1)

func test_nenhum_outro_vivo_mantem():
	assert_eq(TargetCycler.proximo([false, true, false], 1, 1), 1)
