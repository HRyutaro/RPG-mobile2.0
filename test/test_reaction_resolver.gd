extends GutTest

func test_lane_segura_esquiva():
	var r = ReactionResolver.resolve(CombatEnums.Lane.RIGHT, [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER], false, false)
	assert_eq(r, CombatEnums.HitOutcome.DODGED)

func test_na_lane_sem_parry_leva_hit():
	var r = ReactionResolver.resolve(CombatEnums.Lane.CENTER, [CombatEnums.Lane.CENTER], false, false)
	assert_eq(r, CombatEnums.HitOutcome.HIT)

func test_parry_na_janela():
	var r = ReactionResolver.resolve(CombatEnums.Lane.CENTER, [CombatEnums.Lane.CENTER], true, true)
	assert_eq(r, CombatEnums.HitOutcome.PARRIED)

func test_parry_fora_da_janela_leva_hit():
	var r = ReactionResolver.resolve(CombatEnums.Lane.CENTER, [CombatEnums.Lane.CENTER], true, false)
	assert_eq(r, CombatEnums.HitOutcome.HIT)

func test_tres_lanes_hit_garantido():
	var r = ReactionResolver.resolve(CombatEnums.Lane.LEFT, [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT], false, false)
	assert_eq(r, CombatEnums.HitOutcome.HIT)
