class_name EnemyAI

static func escolher_qtd_lanes(roll100: int) -> int:
	if roll100 < 50:
		return 1
	if roll100 < 85:
		return 2
	return 3

static func escolher_lanes_ameacadas(qtd: int, rng: Callable) -> Array:
	var pool := [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT]
	var chosen := []
	var count = clampi(qtd, 1, pool.size())
	for i in count:
		var idx = int(rng.call(0, pool.size()))
		chosen.append(pool[idx])
		pool.remove_at(idx)
	return chosen
