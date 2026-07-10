class_name Targeting

static func resolver(modo: int, selecionado, todos: Array, vivo: Callable) -> Array:
	var res := []
	if modo == CombatEnums.TargetMode.AOE:
		for t in todos:
			if t != null and vivo.call(t):
				res.append(t)
	elif selecionado != null and vivo.call(selecionado):
		res.append(selecionado)
	return res
