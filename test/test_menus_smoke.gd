extends GutTest

func test_mainmenu_monta_botoes():
	var inst = load("res://scenes/MainMenu.tscn").instantiate()
	add_child_autofree(inst)
	await wait_frames(1)
	var botoes = inst.find_children("*", "Button", true, false)
	assert_gt(botoes.size(), 0, "MainMenu tem botoes")

func test_charselect_tem_tres_classes():
	var inst = load("res://scenes/CharacterSelect.tscn").instantiate()
	add_child_autofree(inst)
	await wait_frames(1)
	var botoes = inst.find_children("*", "Button", true, false)
	assert_eq(botoes.size(), 3, "CharacterSelect tem 3 botoes de classe")
