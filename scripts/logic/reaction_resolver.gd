class_name ReactionResolver

static func resolve(player_lane: int, threatened: Array, parry_pressed: bool, parry_in_window: bool) -> int:
	if not threatened.has(player_lane):
		return CombatEnums.HitOutcome.DODGED
	if parry_pressed and parry_in_window:
		return CombatEnums.HitOutcome.PARRIED
	return CombatEnums.HitOutcome.HIT
