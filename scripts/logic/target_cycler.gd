class_name TargetCycler

static func proximo(vivos: Array, atual: int, dir: int) -> int:
	var n := vivos.size()
	if n == 0:
		return atual
	var i := atual
	for _k in range(n):
		i = (i + dir + n) % n
		if vivos[i]:
			return i
	return atual
