class_name EnemyCombatant
extends Combatant

@export var ataques: Array[AtaqueInimigo] = []

func escolher_ataque(rng: Callable) -> AtaqueInimigo:
	if ataques.is_empty():
		return null
	return ataques[int(rng.call(0, ataques.size()))]
