class_name Item
extends Resource

enum Tipo { CURA, MANA }

@export var nome: String
@export var tipo: Tipo = Tipo.CURA
@export var quantidade: int = 30
