extends GutTest

func test_atacar_entra_na_mira_e_cancelar_volta():
	var inst = load("res://scenes/Level1.tscn").instantiate()
	add_child_autofree(inst)
	await wait_frames(3)
	var battle = inst.find_children("*", "BattleController", true, false)[0]
	var targeting = inst.find_children("*", "TargetingController", true, false)[0]

	# Atacar entra na mira
	battle._on_atacar()
	await wait_frames(2)
	assert_true(targeting.ativo, "mira ativa apos Atacar")

	# Voltar/cancelar encerra a mira e nao gasta turno
	targeting.cancelar()
	await wait_frames(2)
	assert_false(targeting.ativo, "mira encerrada apos cancelar")
