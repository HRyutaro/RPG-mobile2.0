class_name PlayerCombatant
extends Combatant

@export var tipo: CombatEnums.CharacterType = CombatEnums.CharacterType.PALADINO
@export var habilidades: Array[Habilidade] = []

var lane_atual: int = CombatEnums.Lane.CENTER

const LANE_WIDTH := 2.0

func mover_para(lane: int) -> void:
	lane_atual = clampi(lane, CombatEnums.Lane.LEFT, CombatEnums.Lane.RIGHT)
	position.x = lane_atual * LANE_WIDTH
