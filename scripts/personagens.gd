class_name Personagens
## Configuracao de modelo por classe (heroi) e por variante (inimigo).
## Herois (Female): torso muda por classe; pernas/cabeca base.
## Inimigos (Male): torso muda por variante (0..2) para dar variedade visual.

const F := "res://models/personagem/female/"
const M := "res://models/personagem/male/"

# ---------- Heroi (Female) ----------

static func skeleton_female() -> PackedScene:
	return load(F + "Female_Animation_Skeleton.FBX")

static func anims_female() -> AnimationLibrary:
	return load(F + "female_anims.res")

static func partes_female(tipo: int) -> Array[PackedScene]:
	var torso := "Female_Torso_1.FBX" # Paladina
	match tipo:
		CombatEnums.CharacterType.MAGO: torso = "Female_Torso_2.FBX"
		CombatEnums.CharacterType.GATUNA: torso = "Female_Torso_3.FBX"
	var a: Array[PackedScene] = [
		load(F + torso),
		load(F + "Female_Base_Legs.FBX"),
		load(F + "Female_Head_1.FBX"),
	]
	return a

static func tex_female(tipo: int) -> Array[Texture2D]:
	var t := "tex/Female_Torso_1_Blue.tga" # Paladina (azul)
	match tipo:
		CombatEnums.CharacterType.MAGO: t = "tex/Female_Torso_2_Red.tga"
		CombatEnums.CharacterType.GATUNA: t = "tex/Female_Torso_3_Green.tga"
	var a: Array[Texture2D] = [
		load(F + t),
		load(F + "tex/Female_Base_Legs.tga"),
		load(F + "tex/Female_Head_1.tga"),
	]
	return a

# ---------- Inimigo (Male) ----------

static func skeleton_male() -> PackedScene:
	return load(M + "Male_Animation_Skeleton.FBX")

static func anims_male() -> AnimationLibrary:
	return load(M + "male_anims.res")

const _MALE_TORSOS := ["Male_Torso_1.FBX", "Male_Torso_2.FBX", "Male_Torso_3.FBX"]
const _MALE_TEX := ["tex/Male_Torso_1_Red.tga", "tex/Male_Torso_2_Green.tga", "tex/Male_Torso_3_Yellow.tga"]

static func partes_male(variante: int) -> Array[PackedScene]:
	var a: Array[PackedScene] = [
		load(M + _MALE_TORSOS[variante % _MALE_TORSOS.size()]),
		load(M + "Male_Base_Legs.FBX"),
		load(M + "Male_Head_1.FBX"),
	]
	return a

static func tex_male(variante: int) -> Array[Texture2D]:
	var a: Array[Texture2D] = [
		load(M + _MALE_TEX[variante % _MALE_TEX.size()]),
		load(M + "tex/Male_Base_Legs.tga"),
		load(M + "tex/Male_Head_1.tga"),
	]
	return a
