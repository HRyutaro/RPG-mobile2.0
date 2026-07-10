class_name Habilidade
extends Resource

@export var nome: String
@export_multiline var descricao: String
@export var custo_mana: int = 20
@export var dano_min: int = 5
@export var dano_max: int = 10
@export var alvo: CombatEnums.TargetMode = CombatEnums.TargetMode.SINGLE
@export var cast_time: float = 0.9

func gerar_dano() -> int:
	return CombatMath.rolar_dano(dano_min, dano_max)
