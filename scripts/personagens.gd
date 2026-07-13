class_name Personagens
## Configuracao de modelo (esqueleto + animacoes + pecas + texturas) por sexo.

const F := "res://models/personagem/female/"
const M := "res://models/personagem/male/"

static func skeleton_female() -> PackedScene:
	return load(F + "Female_Animation_Skeleton.FBX")

static func anims_female() -> AnimationLibrary:
	return load(F + "female_anims.res")

static func partes_female() -> Array[PackedScene]:
	var a: Array[PackedScene] = [
		load(F + "Female_Base_Torso.FBX"),
		load(F + "Female_Base_Legs.FBX"),
		load(F + "Female_Head_1.FBX"),
	]
	return a

static func tex_female() -> Array[Texture2D]:
	var a: Array[Texture2D] = [
		load(F + "tex/Female_Base_Torso.tga"),
		load(F + "tex/Female_Base_Legs.tga"),
		load(F + "tex/Female_Head_1.tga"),
	]
	return a

static func skeleton_male() -> PackedScene:
	return load(M + "Male_Animation_Skeleton.FBX")

static func anims_male() -> AnimationLibrary:
	return load(M + "male_anims.res")

static func partes_male() -> Array[PackedScene]:
	var a: Array[PackedScene] = [
		load(M + "Male_Base_Torso.FBX"),
		load(M + "Male_Base_Legs.FBX"),
		load(M + "Male_Head_1.FBX"),
	]
	return a

static func tex_male() -> Array[Texture2D]:
	var a: Array[Texture2D] = [
		load(M + "tex/Male_Base_Torso.tga"),
		load(M + "tex/Male_Base_Legs.tga"),
		load(M + "tex/Male_Head_1.tga"),
	]
	return a
