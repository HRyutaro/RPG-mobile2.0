class_name Vitals

var max_hp: int
var max_mana: int
var hp: int
var mana: int

func _init(p_max_hp: int, p_max_mana: int) -> void:
	max_hp = p_max_hp
	max_mana = p_max_mana
	hp = p_max_hp
	mana = p_max_mana

func esta_vivo() -> bool:
	return hp > 0

func receber_dano(a: int) -> void:
	hp = max(0, hp - a)

func curar(a: int) -> void:
	hp = min(max_hp, hp + a)

func restaurar_mana(a: int) -> void:
	mana = min(max_mana, mana + a)

func gastar_mana(a: int) -> bool:
	if mana < a:
		return false
	mana -= a
	return true
