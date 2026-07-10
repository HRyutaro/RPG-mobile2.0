class_name CombatMath

static func rolar_dano(min_v: int, max_v: int, rng := Callable()) -> int:
	if rng.is_valid():
		return int(rng.call(min_v, max_v + 1))
	return randi_range(min_v, max_v)

static func dano_contra(base: int) -> int:
	return int(round(base * 1.5))
