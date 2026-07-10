# Porte do Combate para Godot (GDScript) — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Portar o núcleo jogável do combate (lógica testada + cena jogável com placeholders + fluxo MainMenu→CharacterSelect→Level1) para um projeto Godot 4.7 novo em GDScript, conforme `docs/superpowers/specs/2026-07-10-porte-godot-combate-design.md`.

**Architecture:** Lógica pura em classes `RefCounted`/`static func` (testadas via GUT), dados como `Resource`/`.tres`, runtime em Nodes. Cenas e UI são construídas **proceduralmente em GDScript** (placeholders: cápsulas + Controls), evitando `.tscn` frágil escrito à mão.

**Tech Stack:** Godot 4.7, GDScript, GUT 9.6.0.

## Global Constraints

- Projeto: `D:\Godot\Projetos\rpg-tatico-mobile` (já criado, git iniciado).
- Binário Godot: `C:\godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`.
- GDScript, nomes em `snake_case`; classes públicas com `class_name`.
- Lanes: enum `Lane { LEFT = -1, CENTER = 0, RIGHT = 1 }`.
- Menu do turno do jogador: 3 botões (Atacar/Habilidades/Itens); esquiva/parry são reação em tempo real no turno do inimigo.
- Ataque inimigo = sequência de hits; v1 = 1 hit; estrutura aceita N.
- Balanceamento: herói 10 HP, inimigos 3 HP, dano de ataque inimigo 2–3.
- TDD nas classes puras (GUT). Nodes/cenas: implementar + verificar por load/execução headless sem erros.

### Como rodar (usado em várias tarefas)

```bash
GODOT="C:/godot/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe"
PROJ="D:/Godot/Projetos/rpg-tatico-mobile"
# 1x após adicionar scripts com class_name novos (registra os class_names):
"$GODOT" --headless --path "$PROJ" --import
# Suíte GUT:
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -25
```

GUT imprime `Tests <n> | Passing <n> | Failing <n>`. Falha → exit != 0 / `Failing` > 0.
Rodar um arquivo: acrescente `-gtest=res://test/<arquivo>.gd`.
Ignore ruído de fim (`RID leaked at exit`, avisos GTK) — inofensivo.

---

## File Structure

```
project.godot
addons/gut/…                        (copiado do dragon-runner)
scripts/
  logic/
    combat_enums.gd                 class_name CombatEnums (enums)
    reaction_resolver.gd            class_name ReactionResolver (static)
    combat_math.gd                  class_name CombatMath (static)
    vitals.gd                       class_name Vitals
    targeting.gd                    class_name Targeting (static)
    enemy_ai.gd                     class_name EnemyAI (static)
  data/
    habilidade.gd                   class_name Habilidade (Resource)
    hit_data.gd                     class_name HitData (Resource)
    ataque_inimigo.gd               class_name AtaqueInimigo (Resource)
    item.gd                         class_name Item (Resource)
  combatant.gd                      class_name Combatant (Node3D)
  player_combatant.gd               class_name PlayerCombatant
  enemy_combatant.gd                class_name EnemyCombatant
  game_state.gd                     autoload GameState
  swipe_input.gd                    class_name SwipeInput (Node)
  reaction_controller.gd            class_name ReactionController (Node)
  battle_controller.gd              class_name BattleController (Node)
  arena_ui.gd                       class_name ArenaUI (CanvasLayer)
  level1.gd                         class_name Level1 (Node3D, builder)
  main_menu.gd                      (Control)
  character_select.gd               (Control)
scenes/
  MainMenu.tscn  CharacterSelect.tscn  Level1.tscn
data/
  habilidades/*.tres  ataques/*.tres  itens/*.tres
test/
  test_reaction_resolver.gd  test_combat_math.gd  test_vitals.gd
  test_targeting.gd  test_enemy_ai.gd
```

---

### Task 1: Setup do projeto + GUT + sanity

**Files:**
- Create: `project.godot`, `.gitattributes`
- Create: `addons/gut/…` (copiado)
- Create: `scripts/game_state.gd`
- Test: `test/test_sanity.gd`

**Interfaces:**
- Produces: projeto Godot rodável; autoload `GameState`; suíte GUT funcional.

- [ ] **Step 1: Copiar o addon GUT do dragon-runner**

```bash
cp -r "D:/Godot/Projetos/dragon-runner/addons" "D:/Godot/Projetos/rpg-tatico-mobile/addons"
```

- [ ] **Step 2: Criar `project.godot`**

```ini
config_version=5

[application]
config/name="RPG Tatico Mobile"
run/main_scene="res://scenes/MainMenu.tscn"
config/features=PackedStringArray("4.7", "Mobile")

[autoload]
GameState="*res://scripts/game_state.gd"

[editor_plugins]
enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[rendering]
renderer/rendering_method="mobile"
```

- [ ] **Step 3: Criar `scripts/game_state.gd`**

```gdscript
extends Node
## Guarda estado entre cenas (substitui o PlayerPrefs do Unity).

var classe_escolhida: int = 0 # CombatEnums.CharacterType
```

- [ ] **Step 4: Criar `test/test_sanity.gd`**

```gdscript
extends GutTest

func test_harness_roda():
	assert_eq(1 + 1, 2)
```

- [ ] **Step 5: Importar e rodar**

```bash
GODOT="C:/godot/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe"
PROJ="D:/Godot/Projetos/rpg-tatico-mobile"
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -15
```
Expected: `Passing 1 | Failing 0`.

- [ ] **Step 6: Commit**

```bash
cd "D:/Godot/Projetos/rpg-tatico-mobile"
git add -A && git commit -m "chore: setup projeto Godot 4.7 + GUT + GameState + sanity"
```

---

### Task 2: Enums + ReactionResolver (TDD)

**Files:**
- Create: `scripts/logic/combat_enums.gd`, `scripts/logic/reaction_resolver.gd`
- Test: `test/test_reaction_resolver.gd`

**Interfaces:**
- Produces:
  - `CombatEnums.Lane { LEFT = -1, CENTER = 0, RIGHT = 1 }`, `CombatEnums.HitOutcome { DODGED, PARRIED, HIT }`, `CombatEnums.TargetMode { SINGLE, AOE }`, `CombatEnums.CharacterType { PALADINO, MAGO, GATUNA }`.
  - `ReactionResolver.resolve(player_lane: int, threatened: Array, parry_pressed: bool, parry_in_window: bool) -> int`.

- [ ] **Step 1: Teste que falha — `test/test_reaction_resolver.gd`**

```gdscript
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
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_reaction_resolver.gd -gexit 2>&1 | tail -15
```
Expected: erro (class_names inexistentes) / Failing.

- [ ] **Step 3: `scripts/logic/combat_enums.gd`**

```gdscript
class_name CombatEnums

enum Lane { LEFT = -1, CENTER = 0, RIGHT = 1 }
enum HitOutcome { DODGED, PARRIED, HIT }
enum TargetMode { SINGLE, AOE }
enum CharacterType { PALADINO, MAGO, GATUNA }
```

- [ ] **Step 4: `scripts/logic/reaction_resolver.gd`**

```gdscript
class_name ReactionResolver

static func resolve(player_lane: int, threatened: Array, parry_pressed: bool, parry_in_window: bool) -> int:
	if not threatened.has(player_lane):
		return CombatEnums.HitOutcome.DODGED
	if parry_pressed and parry_in_window:
		return CombatEnums.HitOutcome.PARRIED
	return CombatEnums.HitOutcome.HIT
```

- [ ] **Step 5: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_reaction_resolver.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 5 | Failing 0`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: CombatEnums + ReactionResolver com testes"
```

---

### Task 3: CombatMath (TDD)

**Files:**
- Create: `scripts/logic/combat_math.gd`
- Test: `test/test_combat_math.gd`

**Interfaces:**
- Produces: `CombatMath.rolar_dano(min_v: int, max_v: int, rng := Callable()) -> int` (rng recebe `(min, max_exclusivo)`; default usa `randi_range(min_v, max_v)` inclusivo); `CombatMath.dano_contra(base: int) -> int`.

- [ ] **Step 1: Teste que falha — `test/test_combat_math.gd`**

```gdscript
extends GutTest

func test_rolar_dano_dentro_dos_limites():
	for i in 50:
		var d = CombatMath.rolar_dano(4, 9)
		assert_between(d, 4, 9)

func test_rolar_dano_rng_injetado():
	var d = CombatMath.rolar_dano(5, 10, func(mn, mx): return mn)
	assert_eq(d, 5)

func test_rng_recebe_max_exclusivo():
	var capturado := -1
	CombatMath.rolar_dano(3, 7, func(mn, mx): capturado = mx; return mn)
	assert_eq(capturado, 8)

func test_dano_contra_uma_vez_e_meia():
	assert_eq(CombatMath.dano_contra(10), 15)
	assert_eq(CombatMath.dano_contra(6), 9)
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_combat_math.gd -gexit 2>&1 | tail -15
```
Expected: falha (CombatMath inexistente).

- [ ] **Step 3: `scripts/logic/combat_math.gd`**

```gdscript
class_name CombatMath

static func rolar_dano(min_v: int, max_v: int, rng := Callable()) -> int:
	if rng.is_valid():
		return int(rng.call(min_v, max_v + 1))
	return randi_range(min_v, max_v)

static func dano_contra(base: int) -> int:
	return int(round(base * 1.5))
```

- [ ] **Step 4: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_combat_math.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 4 | Failing 0`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: CombatMath com testes"
```

---

### Task 4: Vitals (TDD)

**Files:**
- Create: `scripts/logic/vitals.gd`
- Test: `test/test_vitals.gd`

**Interfaces:**
- Produces: `Vitals` — `_init(max_hp: int, max_mana: int)`; props `max_hp, max_mana, hp, mana`; `esta_vivo() -> bool`, `receber_dano(a: int)`, `curar(a: int)`, `restaurar_mana(a: int)`, `gastar_mana(a: int) -> bool`.

- [ ] **Step 1: Teste que falha — `test/test_vitals.gd`**

```gdscript
extends GutTest

func test_nasce_cheio():
	var v = Vitals.new(100, 50)
	assert_eq(v.hp, 100)
	assert_eq(v.mana, 50)
	assert_true(v.esta_vivo())

func test_dano_nao_fica_negativo():
	var v = Vitals.new(30, 0)
	v.receber_dano(50)
	assert_eq(v.hp, 0)
	assert_false(v.esta_vivo())

func test_gastar_mana_falha_se_insuficiente():
	var v = Vitals.new(100, 20)
	assert_false(v.gastar_mana(30))
	assert_eq(v.mana, 20)
	assert_true(v.gastar_mana(20))
	assert_eq(v.mana, 0)

func test_restaurar_mana_nao_passa_do_max():
	var v = Vitals.new(100, 50)
	v.gastar_mana(40)
	v.restaurar_mana(100)
	assert_eq(v.mana, 50)

func test_curar_nao_passa_do_max():
	var v = Vitals.new(100, 0)
	v.receber_dano(60)
	v.curar(100)
	assert_eq(v.hp, 100)
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_vitals.gd -gexit 2>&1 | tail -15
```
Expected: falha.

- [ ] **Step 3: `scripts/logic/vitals.gd`**

```gdscript
class_name Vitals

var max_hp: int
var max_mana: int
var hp: int
var mana: int

func _init(p_max_hp: int, p_max_mana: int) -> void:
	max_hp = p_max_hp
	max_mana = p_max_mana
	hp = p_max_hp
	mana = p_max_mana

func esta_vivo() -> bool:
	return hp > 0

func receber_dano(a: int) -> void:
	hp = max(0, hp - a)

func curar(a: int) -> void:
	hp = min(max_hp, hp + a)

func restaurar_mana(a: int) -> void:
	mana = min(max_mana, mana + a)

func gastar_mana(a: int) -> bool:
	if mana < a:
		return false
	mana -= a
	return true
```

- [ ] **Step 4: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_vitals.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 5 | Failing 0`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: Vitals com testes"
```

---

### Task 5: Targeting (TDD)

**Files:**
- Create: `scripts/logic/targeting.gd`
- Test: `test/test_targeting.gd`

**Interfaces:**
- Produces: `Targeting.resolver(modo: int, selecionado, todos: Array, vivo: Callable) -> Array`.

- [ ] **Step 1: Teste que falha — `test/test_targeting.gd`**

```gdscript
extends GutTest

func _vivo(hp): return hp > 0

func test_single_retorna_so_o_selecionado():
	var r = Targeting.resolver(CombatEnums.TargetMode.SINGLE, 20, [10, 20, 30], _vivo)
	assert_eq(r, [20])

func test_single_selecionado_morto_vazio():
	var r = Targeting.resolver(CombatEnums.TargetMode.SINGLE, 0, [10, 0, 30], _vivo)
	assert_eq(r, [])

func test_aoe_retorna_todos_vivos():
	var r = Targeting.resolver(CombatEnums.TargetMode.AOE, 10, [10, 0, 30], _vivo)
	assert_eq(r, [10, 30])
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_targeting.gd -gexit 2>&1 | tail -15
```
Expected: falha.

- [ ] **Step 3: `scripts/logic/targeting.gd`**

```gdscript
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
```

- [ ] **Step 4: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_targeting.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 3 | Failing 0`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: Targeting single/AoE com testes"
```

---

### Task 6: EnemyAI (TDD)

**Files:**
- Create: `scripts/logic/enemy_ai.gd`
- Test: `test/test_enemy_ai.gd`

**Interfaces:**
- Produces: `EnemyAI.escolher_qtd_lanes(roll100: int) -> int` (1:0–49, 2:50–84, 3:85–99); `EnemyAI.escolher_lanes_ameacadas(qtd: int, rng: Callable) -> Array` (lanes distintas; rng recebe `(0, tamanho)`).

- [ ] **Step 1: Teste que falha — `test/test_enemy_ai.gd`**

```gdscript
extends GutTest

func test_qtd_lanes_pesos():
	assert_eq(EnemyAI.escolher_qtd_lanes(0), 1)
	assert_eq(EnemyAI.escolher_qtd_lanes(49), 1)
	assert_eq(EnemyAI.escolher_qtd_lanes(50), 2)
	assert_eq(EnemyAI.escolher_qtd_lanes(84), 2)
	assert_eq(EnemyAI.escolher_qtd_lanes(85), 3)
	assert_eq(EnemyAI.escolher_qtd_lanes(99), 3)

func test_lanes_distintas():
	var lanes = EnemyAI.escolher_lanes_ameacadas(2, func(_a, _b): return 0)
	assert_eq(lanes.size(), 2)
	assert_ne(lanes[0], lanes[1])

func test_tres_lanes_retorna_todas():
	var lanes = EnemyAI.escolher_lanes_ameacadas(3, func(_a, _b): return 0)
	assert_eq(lanes.size(), 3)
	assert_true(lanes.has(CombatEnums.Lane.LEFT))
	assert_true(lanes.has(CombatEnums.Lane.CENTER))
	assert_true(lanes.has(CombatEnums.Lane.RIGHT))
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_enemy_ai.gd -gexit 2>&1 | tail -15
```
Expected: falha.

- [ ] **Step 3: `scripts/logic/enemy_ai.gd`**

```gdscript
class_name EnemyAI

static func escolher_qtd_lanes(roll100: int) -> int:
	if roll100 < 50:
		return 1
	if roll100 < 85:
		return 2
	return 3

static func escolher_lanes_ameacadas(qtd: int, rng: Callable) -> Array:
	var pool := [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT]
	var chosen := []
	var count = clampi(qtd, 1, pool.size())
	for i in count:
		var idx = int(rng.call(0, pool.size()))
		chosen.append(pool[idx])
		pool.remove_at(idx)
	return chosen
```

- [ ] **Step 4: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_enemy_ai.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 3 | Failing 0`. Depois rode a suíte inteira: `-gdir=res://test -ginclude_subdirs` → `Passing 20 | Failing 0`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: EnemyAI com testes"
```

---

### Task 7: Recursos de dados (Habilidade, HitData, AtaqueInimigo, Item)

**Files:**
- Create: `scripts/data/habilidade.gd`, `scripts/data/hit_data.gd`, `scripts/data/ataque_inimigo.gd`, `scripts/data/item.gd`

**Interfaces:**
- Produces:
  - `Habilidade` (Resource): `nome, descricao, custo_mana, dano_min, dano_max, alvo: CombatEnums.TargetMode, cast_time`; `gerar_dano() -> int`.
  - `HitData` (Resource): `dano_min, dano_max, telegraph_time, parry_window_start, parry_window_duration`.
  - `AtaqueInimigo` (Resource): `nome`, `hits: Array[HitData]`.
  - `Item` (Resource): `enum Tipo { CURA, MANA }`, `nome, tipo, quantidade`.

Sem testes automatizados (dados). Verificação: `--import` sem erro.

- [ ] **Step 1: `scripts/data/habilidade.gd`**

```gdscript
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
```

- [ ] **Step 2: `scripts/data/hit_data.gd`**

```gdscript
class_name HitData
extends Resource

@export var dano_min: int = 2
@export var dano_max: int = 3
@export var telegraph_time: float = 0.6
@export var parry_window_start: float = 0.15
@export var parry_window_duration: float = 0.25
```

- [ ] **Step 3: `scripts/data/ataque_inimigo.gd`**

```gdscript
class_name AtaqueInimigo
extends Resource

@export var nome: String
@export var hits: Array[HitData] = []
```

- [ ] **Step 4: `scripts/data/item.gd`**

```gdscript
class_name Item
extends Resource

enum Tipo { CURA, MANA }

@export var nome: String
@export var tipo: Tipo = Tipo.CURA
@export var quantidade: int = 30
```

- [ ] **Step 5: Importar (verifica compilação)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "error|SCRIPT ERROR" | head || echo "sem erros"
```
Expected: sem erros de script.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: recursos de dados (Habilidade, HitData, AtaqueInimigo, Item)"
```

---

### Task 8: Combatant / PlayerCombatant / EnemyCombatant (Nodes procedurais)

**Files:**
- Create: `scripts/combatant.gd`, `scripts/player_combatant.gd`, `scripts/enemy_combatant.gd`

**Interfaces:**
- Consumes: `Vitals`, `CombatMath`, `Habilidade`, `AtaqueInimigo`, `CombatEnums`.
- Produces:
  - `Combatant` (Node3D): props `combatant_name, max_hp, max_mana, basic_dmg_min, basic_dmg_max`; `vitals: Vitals`; `esta_vivo() -> bool`, `receber_dano(a)`, `rolar_dano_basico() -> int`, `preparar()` (cria vitals + cápsula), `set_cor(c: Color)`.
  - `PlayerCombatant`: + `tipo: CombatEnums.CharacterType`, `habilidades: Array[Habilidade]`, `lane_atual: int`, `mover_para(lane, anchors)`.
  - `EnemyCombatant`: + `ataques: Array[AtaqueInimigo]`, `escolher_ataque(rng: Callable) -> AtaqueInimigo`.

Verificação: script de teste headless que instancia e checa vitals.

- [ ] **Step 1: `scripts/combatant.gd`**

```gdscript
class_name Combatant
extends Node3D

@export var combatant_name := "Unit"
@export var max_hp := 100
@export var max_mana := 0
@export var basic_dmg_min := 4
@export var basic_dmg_max := 9

var vitals: Vitals
var _mesh: MeshInstance3D

func preparar() -> void:
	vitals = Vitals.new(max_hp, max_mana)
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.mesh = CapsuleMesh.new()
		add_child(_mesh)

func set_cor(c: Color) -> void:
	if _mesh == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	_mesh.material_override = m

func esta_vivo() -> bool:
	return vitals != null and vitals.esta_vivo()

func receber_dano(a: int) -> void:
	if vitals != null:
		vitals.receber_dano(a)

func rolar_dano_basico() -> int:
	return CombatMath.rolar_dano(basic_dmg_min, basic_dmg_max)
```

- [ ] **Step 2: `scripts/player_combatant.gd`**

```gdscript
class_name PlayerCombatant
extends Combatant

@export var tipo: CombatEnums.CharacterType = CombatEnums.CharacterType.PALADINO
@export var habilidades: Array[Habilidade] = []

var lane_atual: int = CombatEnums.Lane.CENTER

const LANE_WIDTH := 2.0

func mover_para(lane: int) -> void:
	lane_atual = clampi(lane, CombatEnums.Lane.LEFT, CombatEnums.Lane.RIGHT)
	position.x = lane_atual * LANE_WIDTH
```

- [ ] **Step 3: `scripts/enemy_combatant.gd`**

```gdscript
class_name EnemyCombatant
extends Combatant

@export var ataques: Array[AtaqueInimigo] = []

func escolher_ataque(rng: Callable) -> AtaqueInimigo:
	if ataques.is_empty():
		return null
	return ataques[int(rng.call(0, ataques.size()))]
```

- [ ] **Step 4: Teste headless — `test/test_combatants.gd`**

```gdscript
extends GutTest

func test_combatant_prepara_vitals():
	var c = Combatant.new()
	c.max_hp = 10
	add_child_autofree(c)
	c.preparar()
	assert_eq(c.vitals.hp, 10)
	assert_true(c.esta_vivo())
	c.receber_dano(10)
	assert_false(c.esta_vivo())

func test_player_move_lane():
	var p = PlayerCombatant.new()
	add_child_autofree(p)
	p.preparar()
	p.mover_para(CombatEnums.Lane.LEFT)
	assert_eq(p.lane_atual, CombatEnums.Lane.LEFT)
	assert_almost_eq(p.position.x, -2.0, 0.001)

func test_enemy_escolhe_ataque():
	var e = EnemyCombatant.new()
	add_child_autofree(e)
	var atk = AtaqueInimigo.new()
	e.ataques = [atk]
	assert_eq(e.escolher_ataque(func(_a, _b): return 0), atk)
```

- [ ] **Step 5: Importar e rodar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_combatants.gd -gexit 2>&1 | tail -15
```
Expected: `Passing 3 | Failing 0`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: Combatant/Player/Enemy (nodes procedurais) com testes"
```

---

### Task 9: SwipeInput

**Files:**
- Create: `scripts/swipe_input.gd`

**Interfaces:**
- Produces: `SwipeInput` (Node) — sinais `swipe(dir: int)` (-1/+1) e `parry()`; `set_ativo(v: bool)`; método `pressionar_parry()` (ligado ao botão).

Verificação: `--import` sem erro (comportamento validado no smoke da Task 13).

- [ ] **Step 1: `scripts/swipe_input.gd`**

```gdscript
class_name SwipeInput
extends Node

signal swipe(dir: int)
signal parry

@export var min_swipe_px := 40.0

var _ativo := false
var _acc_x := 0.0

func set_ativo(v: bool) -> void:
	_ativo = v
	_acc_x = 0.0

func pressionar_parry() -> void:
	parry.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _ativo:
		return
	if event is InputEventScreenDrag:
		_acumular(event.relative.x)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_acumular(event.relative.x)

func _acumular(dx: float) -> void:
	_acc_x += dx
	if absf(_acc_x) >= min_swipe_px:
		swipe.emit(1 if _acc_x > 0 else -1)
		_acc_x = 0.0
```

- [ ] **Step 2: Importar (verifica)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|error" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: SwipeInput (arrasto -> lane, sinal de parry)"
```

---

### Task 10: ReactionController

**Files:**
- Create: `scripts/reaction_controller.gd`

**Interfaces:**
- Consumes: `SwipeInput`, `PlayerCombatant`, `EnemyCombatant`, `HitData`, `ReactionResolver`, `CombatMath`, `CombatEnums`.
- Produces: `ReactionController` (Node) — props `swipe_input: SwipeInput`; `telegraph: Callable` (recebe `Array` de lanes p/ mostrar) e `telegraph_hide: Callable`; `func rodar_hit(player, atacante, hit: HitData, ameacadas: Array) -> int` (async via `await`; move lane no swipe, lê parry, resolve, aplica dano/contra-ataque, retorna o `HitOutcome`).

Verificação: `--import` sem erro; comportamento no smoke da Task 13.

- [ ] **Step 1: `scripts/reaction_controller.gd`**

```gdscript
class_name ReactionController
extends Node

var swipe_input: SwipeInput
var telegraph_show: Callable = func(_lanes): pass
var telegraph_hide: Callable = func(): pass

var _parry_pressed := false
var _parry_time := -999.0
var _janela_ini := 0.0
var _janela_fim := 0.0

func rodar_hit(player: PlayerCombatant, atacante: EnemyCombatant, hit: HitData, ameacadas: Array) -> int:
	_parry_pressed = false
	_parry_time = -999.0
	var t0 := Time.get_ticks_msec() / 1000.0
	_janela_ini = hit.telegraph_time + hit.parry_window_start
	_janela_fim = _janela_ini + hit.parry_window_duration
	var total := _janela_fim

	var on_swipe := func(dir: int):
		player.mover_para(player.lane_atual + dir)
	var on_parry := func():
		_parry_pressed = true
		_parry_time = (Time.get_ticks_msec() / 1000.0) - t0

	swipe_input.swipe.connect(on_swipe)
	swipe_input.parry.connect(on_parry)
	swipe_input.set_ativo(true)
	telegraph_show.call(ameacadas)

	await get_tree().create_timer(total).timeout

	swipe_input.set_ativo(false)
	telegraph_hide.call()
	swipe_input.swipe.disconnect(on_swipe)
	swipe_input.parry.disconnect(on_parry)

	var na_janela := _parry_pressed and _parry_time >= _janela_ini and _parry_time <= _janela_fim
	var outcome := ReactionResolver.resolve(player.lane_atual, ameacadas, _parry_pressed, na_janela)

	match outcome:
		CombatEnums.HitOutcome.HIT:
			player.receber_dano(CombatMath.rolar_dano(hit.dano_min, hit.dano_max))
		CombatEnums.HitOutcome.PARRIED:
			var base := CombatMath.rolar_dano(hit.dano_min, hit.dano_max)
			atacante.receber_dano(CombatMath.dano_contra(base))
	return outcome
```

- [ ] **Step 2: Importar (verifica)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|error" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: ReactionController (telegrafo, janela, resolucao via await)"
```

---

### Task 11: BattleController

**Files:**
- Create: `scripts/battle_controller.gd`

**Interfaces:**
- Consumes: tudo anterior + `ArenaUI` (Task 12, referenciada por `set`).
- Produces: `BattleController` (Node) — props (setadas pelo `Level1`): `player: PlayerCombatant`, `enemies: Array[EnemyCombatant]`, `reaction: ReactionController`, `ui: ArenaUI`, `itens: Array[Item]`, `turn_delay := 0.6`. Métodos: `iniciar()`, callbacks `_on_atacar()`, `_on_habilidade(h: Habilidade)`, `_on_item()`. Sinal `log_msg(txt: String)`.

Verificação: exercitado no smoke da Task 13.

- [ ] **Step 1: `scripts/battle_controller.gd`**

```gdscript
class_name BattleController
extends Node

signal log_msg(txt: String)

var player: PlayerCombatant
var enemies: Array[EnemyCombatant] = []
var reaction: ReactionController
var ui = null # ArenaUI (setado pelo Level1)
var itens: Array[Item] = []
var turn_delay := 0.6

var _alvo: EnemyCombatant
var _ocupado := false

func iniciar() -> void:
	_alvo = _primeiro_vivo()
	_log("Combate iniciado.")
	_turno_jogador()

func _pronto() -> bool:
	return not _ocupado and player != null and player.esta_vivo()

func _turno_jogador() -> void:
	_garantir_alvo()
	if ui != null:
		ui.set_menu_visivel(true)
		ui.set_menu_interativo(true)

func _on_atacar() -> void:
	if not _pronto(): return
	_executar_ataque_basico()

func _on_habilidade(h: Habilidade) -> void:
	if not _pronto(): return
	if not player.vitals.gastar_mana(h.custo_mana):
		_log("Mana insuficiente para %s." % h.nome)
		return
	_executar_habilidade(h)

func _on_item() -> void:
	if not _pronto(): return
	if itens.is_empty():
		_log("Sem itens.")
		return
	var it := itens[0]
	if it.tipo == Item.Tipo.CURA:
		player.vitals.curar(it.quantidade)
	else:
		player.vitals.restaurar_mana(it.quantidade)
	_log("Usou %s." % it.nome)
	_fim_da_acao()

func _executar_ataque_basico() -> void:
	_ocupado = true
	_ui_interativo(false)
	_garantir_alvo()
	if _alvo != null:
		_alvo.receber_dano(player.rolar_dano_basico())
	_fim_da_acao()

func _executar_habilidade(h: Habilidade) -> void:
	_ocupado = true
	_ui_interativo(false)
	_garantir_alvo()
	var vivo := func(e): return e != null and e.esta_vivo()
	var alvos := Targeting.resolver(h.alvo, _alvo, enemies, vivo)
	for a in alvos:
		a.receber_dano(h.gerar_dano())
	_fim_da_acao()

func _fim_da_acao() -> void:
	_ocupado = true
	if _todos_mortos():
		_vitoria(); return
	await get_tree().create_timer(turn_delay).timeout
	await _turno_inimigo()
	if not player.esta_vivo():
		_derrota(); return
	_ocupado = false
	_turno_jogador()

func _turno_inimigo() -> void:
	if ui != null: ui.set_menu_visivel(false)
	for inimigo in enemies:
		if inimigo == null or not inimigo.esta_vivo():
			continue
		var atk := inimigo.escolher_ataque(func(a, b): return randi_range(a, b - 1))
		if atk == null or atk.hits.is_empty():
			continue
		for hit in atk.hits:
			var qtd := EnemyAI.escolher_qtd_lanes(randi_range(0, 99))
			var ameacadas := EnemyAI.escolher_lanes_ameacadas(qtd, func(a, b): return randi_range(a, b - 1))
			_log("%s ataca!" % inimigo.combatant_name)
			var outcome: int = await reaction.rodar_hit(player, inimigo, hit, ameacadas)
			_log(_texto_outcome(outcome))
			if not player.esta_vivo():
				return

func _texto_outcome(o: int) -> String:
	match o:
		CombatEnums.HitOutcome.PARRIED: return "Parry!"
		CombatEnums.HitOutcome.DODGED: return "Esquiva!"
		_: return "Acertou voce!"

func _garantir_alvo() -> void:
	if _alvo != null and _alvo.esta_vivo(): return
	_alvo = _primeiro_vivo()

func _primeiro_vivo() -> EnemyCombatant:
	for e in enemies:
		if e != null and e.esta_vivo(): return e
	return null

func _todos_mortos() -> bool:
	return _primeiro_vivo() == null

func _ui_interativo(v: bool) -> void:
	if ui != null: ui.set_menu_interativo(v)

func _vitoria() -> void:
	_log("Vitoria!"); _ocupado = true
	if ui != null: ui.set_menu_visivel(false)

func _derrota() -> void:
	_log("Game Over."); _ocupado = true
	if ui != null: ui.set_menu_visivel(false)

func _log(txt: String) -> void:
	log_msg.emit(txt)
	print(txt)
```

- [ ] **Step 2: Importar (verifica)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|error" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: BattleController (maquina de turnos via await)"
```

---

### Task 12: ArenaUI (UI procedural)

**Files:**
- Create: `scripts/arena_ui.gd`

**Interfaces:**
- Consumes: `PlayerCombatant`, `EnemyCombatant`, `CombatEnums`.
- Produces: `ArenaUI` (CanvasLayer) — construída em `_ready`. Sinais `atacar`, `usar_habilidade(h)`, `usar_item`, `parry`. Métodos: `bind_player(p)`, `set_enemies(arr)`, `set_menu_visivel(v)`, `set_menu_interativo(v)`, `set_log(txt)`, `popular_habilidades(habs: Array)`, `mostrar_telegrafo(lanes: Array)`, `esconder_telegrafo()`.

Verificação: instanciação no smoke da Task 13.

- [ ] **Step 1: `scripts/arena_ui.gd`**

```gdscript
class_name ArenaUI
extends CanvasLayer

signal atacar
signal usar_habilidade(h)
signal usar_item
signal parry

var _player: PlayerCombatant
var _enemies: Array = []

var _menu: Control
var _btn_atacar: Button
var _btn_habs: Button
var _btn_itens: Button
var _hab_panel: VBoxContainer
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _log: Label
var _tel := {}       # lane -> ColorRect
var _enemy_bars := []

func _ready() -> void:
	_montar()

func _montar() -> void:
	# telegrafo por lane (fundo)
	for lane in [CombatEnums.Lane.LEFT, CombatEnums.Lane.CENTER, CombatEnums.Lane.RIGHT]:
		var r := ColorRect.new()
		r.color = Color(1, 0.15, 0.15, 0.30)
		r.anchor_left = (lane + 1) / 3.0
		r.anchor_right = (lane + 2) / 3.0
		r.anchor_top = 0.0
		r.anchor_bottom = 1.0
		r.visible = false
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(r)
		_tel[lane] = r

	# HUD do player
	_hp_bar = ProgressBar.new(); _hp_bar.position = Vector2(20, 20); _hp_bar.size = Vector2(200, 24)
	_mp_bar = ProgressBar.new(); _mp_bar.position = Vector2(20, 50); _mp_bar.size = Vector2(200, 18)
	add_child(_hp_bar); add_child(_mp_bar)

	# log
	_log = Label.new(); _log.position = Vector2(20, 80)
	add_child(_log)

	# menu de acao
	_menu = VBoxContainer.new()
	_menu.anchor_left = 0.5; _menu.anchor_top = 1.0
	_menu.position = Vector2(-120, -180)
	add_child(_menu)
	_btn_atacar = _make_btn("Atacar", func(): atacar.emit())
	_btn_habs = _make_btn("Habilidades", func(): _hab_panel.visible = not _hab_panel.visible)
	_btn_itens = _make_btn("Itens", func(): usar_item.emit())
	_menu.add_child(_btn_atacar); _menu.add_child(_btn_habs); _menu.add_child(_btn_itens)

	# painel de habilidades
	_hab_panel = VBoxContainer.new()
	_hab_panel.anchor_left = 0.5; _hab_panel.anchor_top = 1.0
	_hab_panel.position = Vector2(60, -180)
	_hab_panel.visible = false
	add_child(_hab_panel)

	# botao parry
	var parry_btn := _make_btn("PARRY", func(): parry.emit())
	parry_btn.anchor_left = 0.5; parry_btn.anchor_top = 1.0
	parry_btn.position = Vector2(-60, -60)
	parry_btn.custom_minimum_size = Vector2(180, 60)
	add_child(parry_btn)

func _make_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(160, 44)
	b.pressed.connect(cb)
	return b

func bind_player(p: PlayerCombatant) -> void:
	_player = p

func set_enemies(arr: Array) -> void:
	_enemies = arr
	for b in _enemy_bars:
		b.queue_free()
	_enemy_bars.clear()
	var i := 0
	for e in arr:
		var bar := ProgressBar.new()
		bar.position = Vector2(20 + i * 210, 120)
		bar.size = Vector2(200, 18)
		add_child(bar)
		_enemy_bars.append(bar)
		i += 1

func popular_habilidades(habs: Array) -> void:
	for c in _hab_panel.get_children():
		c.queue_free()
	for h in habs:
		var hb := h
		var b := _make_btn(h.nome, func(): usar_habilidade.emit(hb))
		_hab_panel.add_child(b)

func set_menu_visivel(v: bool) -> void:
	if _menu: _menu.visible = v
	if not v and _hab_panel: _hab_panel.visible = false

func set_menu_interativo(v: bool) -> void:
	for b in [_btn_atacar, _btn_habs, _btn_itens]:
		if b: b.disabled = not v

func set_log(txt: String) -> void:
	if _log: _log.text = txt

func mostrar_telegrafo(lanes: Array) -> void:
	for lane in _tel:
		_tel[lane].visible = lanes.has(lane)

func esconder_telegrafo() -> void:
	for lane in _tel:
		_tel[lane].visible = false

func _process(_dt: float) -> void:
	if _player != null and _player.vitals != null:
		_hp_bar.max_value = _player.vitals.max_hp
		_hp_bar.value = _player.vitals.hp
		_mp_bar.max_value = max(1, _player.vitals.max_mana)
		_mp_bar.value = _player.vitals.mana
	for i in range(min(_enemy_bars.size(), _enemies.size())):
		var e = _enemies[i]
		if e != null and e.vitals != null:
			_enemy_bars[i].max_value = e.vitals.max_hp
			_enemy_bars[i].value = e.vitals.hp
			_enemy_bars[i].visible = e.esta_vivo()
```

- [ ] **Step 2: Importar (verifica)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|error" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: ArenaUI (UI de combate procedural)"
```

---

### Task 13: Cena Level1 (builder) + fiação + smoke headless

**Files:**
- Create: `scripts/level1.gd`, `scenes/Level1.tscn`
- Test: `test/test_level1_smoke.gd`

**Interfaces:**
- Consumes: tudo anterior.
- Produces: `Level1` (Node3D) — em `_ready`: monta ambiente (chão/luz/câmera/lane anchors), spawna herói (pela `GameState.classe_escolhida`) + 1–3 inimigos, cria `BattleController`/`ReactionController`/`SwipeInput`/`ArenaUI`, fia sinais, chama `iniciar()`. Método `_spawn_player()`, `_spawn_enemies()`.

- [ ] **Step 1: `scripts/level1.gd`**

```gdscript
class_name Level1
extends Node3D

const LANE_WIDTH := 2.0

var _battle: BattleController
var _reaction: ReactionController
var _swipe: SwipeInput
var _ui: ArenaUI
var _player: PlayerCombatant
var _enemies: Array[EnemyCombatant] = []

func _ready() -> void:
	_montar_ambiente()
	_spawn_player()
	_spawn_enemies()
	_montar_sistemas()
	_battle.iniciar()

func _montar_ambiente() -> void:
	var chao := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(40, 40)
	chao.mesh = pm
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(0.28, 0.45, 0.22)
	chao.material_override = mat
	add_child(chao)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -30, 0)
	add_child(luz)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 4.5, 8)
	cam.rotation_degrees = Vector3(-25, 0, 0)
	add_child(cam)

func _spawn_player() -> void:
	_player = PlayerCombatant.new()
	_player.tipo = GameState.classe_escolhida
	match _player.tipo:
		CombatEnums.CharacterType.PALADINO:
			_player.combatant_name = "Paladina"; _player.max_hp = 10; _player.max_mana = 60
		CombatEnums.CharacterType.MAGO:
			_player.combatant_name = "Maga"; _player.max_hp = 10; _player.max_mana = 120
		CombatEnums.CharacterType.GATUNA:
			_player.combatant_name = "Gatuna"; _player.max_hp = 10; _player.max_mana = 80
	_player.basic_dmg_min = 1; _player.basic_dmg_max = 2
	_player.position = Vector3(0, 1, 0)
	add_child(_player)
	_player.preparar()
	_player.set_cor(Color(0.3, 0.5, 1.0))
	_player.mover_para(CombatEnums.Lane.CENTER)
	_carregar_habilidades()

func _carregar_habilidades() -> void:
	var dir := "res://data/habilidades/"
	var arquivos := {
		CombatEnums.CharacterType.PALADINO: ["golpe_sagrado.tres", "luz_punitiva.tres"],
		CombatEnums.CharacterType.MAGO: ["bola_de_fogo.tres", "raio_de_luz.tres"],
		CombatEnums.CharacterType.GATUNA: ["rasgar_pele.tres", "laminas_gemeas.tres"],
	}
	var habs: Array[Habilidade] = []
	for f in arquivos[_player.tipo]:
		var h = load(dir + f)
		if h != null: habs.append(h)
	_player.habilidades = habs

func _spawn_enemies() -> void:
	_enemies.clear()
	var atk := load("res://data/ataques/faca.tres")
	var qtd := randi_range(1, 3)
	for i in qtd:
		var e := EnemyCombatant.new()
		e.combatant_name = "Bandido %d" % (i + 1)
		e.max_hp = 3
		e.basic_dmg_min = 1; e.basic_dmg_max = 2
		if atk != null: e.ataques = [atk]
		e.position = Vector3(-2.0 + i * 2.0, 1, -6)
		add_child(e)
		e.preparar()
		e.set_cor(Color(0.9, 0.3, 0.3))
		_enemies.append(e)

func _montar_sistemas() -> void:
	_ui = ArenaUI.new()
	add_child(_ui)
	_ui.bind_player(_player)
	_ui.set_enemies(_enemies)
	_ui.popular_habilidades(_player.habilidades)

	_swipe = SwipeInput.new()
	add_child(_swipe)

	_reaction = ReactionController.new()
	_reaction.swipe_input = _swipe
	_reaction.telegraph_show = func(lanes): _ui.mostrar_telegrafo(lanes)
	_reaction.telegraph_hide = func(): _ui.esconder_telegrafo()
	add_child(_reaction)

	_battle = BattleController.new()
	_battle.player = _player
	_battle.enemies = _enemies
	_battle.reaction = _reaction
	_battle.ui = _ui
	_battle.itens = _carregar_itens()
	add_child(_battle)

	# fiacao de sinais
	_ui.atacar.connect(_battle._on_atacar)
	_ui.usar_habilidade.connect(_battle._on_habilidade)
	_ui.usar_item.connect(_battle._on_item)
	_ui.parry.connect(_swipe.pressionar_parry)
	_battle.log_msg.connect(_ui.set_log)

func _carregar_itens() -> Array[Item]:
	var res: Array[Item] = []
	for f in ["pocao_de_vida.tres", "pocao_de_mana.tres"]:
		var it = load("res://data/itens/" + f)
		if it != null: res.append(it)
	return res
```

- [ ] **Step 2: Criar `scenes/Level1.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/level1.gd" id="1"]

[node name="Level1" type="Node3D"]
script = ExtResource("1")
```

- [ ] **Step 3: Teste smoke — `test/test_level1_smoke.gd`**

```gdscript
extends GutTest

func test_level1_instancia_sem_erro():
	var cena = load("res://scenes/Level1.tscn")
	assert_not_null(cena)
	var inst = cena.instantiate()
	add_child_autofree(inst)
	await wait_frames(3)
	# _ready montou o mundo: ambiente + player + inimigos + sistemas
	assert_gt(inst.get_child_count(), 0, "Level1 montou nodes filhos")
	var players = inst.find_children("*", "PlayerCombatant", true, false)
	assert_gt(players.size(), 0, "ha um PlayerCombatant na cena")
	var enemies = inst.find_children("*", "EnemyCombatant", true, false)
	assert_gt(enemies.size(), 0, "ha ao menos 1 EnemyCombatant na cena")
```

- [ ] **Step 4: Importar e rodar smoke**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_level1_smoke.gd -gexit 2>&1 | tail -20
```
Expected: `Passing 1 | Failing 0`, sem `SCRIPT ERROR`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: cena Level1 (builder procedural) + fiacao + smoke"
```

---

### Task 14: Telas MainMenu + CharacterSelect + fluxo

**Files:**
- Create: `scripts/main_menu.gd`, `scripts/character_select.gd`
- Create: `scenes/MainMenu.tscn`, `scenes/CharacterSelect.tscn`

**Interfaces:**
- Consumes: `GameState`, `CombatEnums`.
- Produces: MainMenu (botões Novo Jogo/Sair) → CharacterSelect (3 botões de classe) grava `GameState.classe_escolhida` e vai pra `Level1`.

- [ ] **Step 1: `scripts/main_menu.gd`**

```gdscript
extends Control

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.5; vb.anchor_top = 0.5
	vb.position = Vector2(-100, -80)
	add_child(vb)
	vb.add_child(_btn("Novo Jogo", func(): get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")))
	vb.add_child(_btn("Sair", func(): get_tree().quit()))

func _btn(txt: String, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.custom_minimum_size = Vector2(200, 48)
	b.pressed.connect(cb)
	return b
```

- [ ] **Step 2: `scripts/character_select.gd`**

```gdscript
extends Control

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.anchor_left = 0.5; vb.anchor_top = 0.5
	vb.position = Vector2(-120, -120)
	add_child(vb)
	vb.add_child(_btn("Paladina", CombatEnums.CharacterType.PALADINO))
	vb.add_child(_btn("Maga", CombatEnums.CharacterType.MAGO))
	vb.add_child(_btn("Gatuna", CombatEnums.CharacterType.GATUNA))

func _btn(txt: String, tipo: int) -> Button:
	var b := Button.new(); b.text = txt; b.custom_minimum_size = Vector2(220, 52)
	b.pressed.connect(func():
		GameState.classe_escolhida = tipo
		get_tree().change_scene_to_file("res://scenes/Level1.tscn"))
	return b
```

- [ ] **Step 3: `scenes/MainMenu.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/main_menu.gd" id="1"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
script = ExtResource("1")
```

- [ ] **Step 4: `scenes/CharacterSelect.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/character_select.gd" id="1"]

[node name="CharacterSelect" type="Control"]
layout_mode = 3
anchors_preset = 15
script = ExtResource("1")
```

- [ ] **Step 5: Importar e verificar carga das cenas**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|error" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: telas MainMenu + CharacterSelect + fluxo pra Level1"
```

---

### Task 15: Assets de dados (.tres) + execução end-to-end

**Files:**
- Create: `data/habilidades/*.tres`, `data/ataques/*.tres`, `data/itens/*.tres`

**Interfaces:**
- Consumes: recursos da Task 7. Produces: os `.tres` carregados pelo `Level1`.

Cada `.tres` referencia seu script pelo `class_name`/path. Exemplo de formato (Godot 4):

- [ ] **Step 1: `data/habilidades/golpe_sagrado.tres`**

```
[gd_resource type="Resource" script_class="Habilidade" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/habilidade.gd" id="1"]

[resource]
script = ExtResource("1")
nome = "Golpe Sagrado"
descricao = "Investida sagrada num alvo."
custo_mana = 20
dano_min = 10
dano_max = 16
alvo = 0
cast_time = 0.9
```

- [ ] **Step 2: Demais habilidades** (mesmo formato, trocando os campos)

`luz_punitiva.tres` → nome "Luz Punitiva", custo 30, dano 7–12, `alvo = 1` (AoE).
`bola_de_fogo.tres` → "Bola de Fogo", custo 30, dano 8–14, `alvo = 1`.
`raio_de_luz.tres` → "Raio de Luz", custo 25, dano 12–20, `alvo = 0`.
`rasgar_pele.tres` → "Rasgar Pele", custo 15, dano 9–15, `alvo = 0`.
`laminas_gemeas.tres` → "Laminas Gemeas", custo 25, dano 13–19, `alvo = 0`.

- [ ] **Step 3: `data/ataques/faca.tres`** (com 1 HitData embutido)

```
[gd_resource type="Resource" script_class="AtaqueInimigo" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/data/ataque_inimigo.gd" id="1"]
[ext_resource type="Script" path="res://scripts/data/hit_data.gd" id="2"]

[sub_resource type="Resource" id="hit1"]
script = ExtResource("2")
dano_min = 2
dano_max = 3
telegraph_time = 0.6
parry_window_start = 0.15
parry_window_duration = 0.25

[resource]
script = ExtResource("1")
nome = "Ataque de Faca"
hits = [SubResource("hit1")]
```

- [ ] **Step 4: Itens** — `data/itens/pocao_de_vida.tres` e `pocao_de_mana.tres`

```
[gd_resource type="Resource" script_class="Item" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/item.gd" id="1"]

[resource]
script = ExtResource("1")
nome = "Pocao de Vida"
tipo = 0
quantidade = 30
```
(`pocao_de_mana.tres` → nome "Pocao de Mana", `tipo = 1`.)

- [ ] **Step 5: Importar, rodar suíte inteira e o smoke**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -20
```
Expected: `Passing 21 | Failing 0` (5+4+5+3+3 lógica +1 smoke) — e sem `SCRIPT ERROR`.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: assets .tres (habilidades, ataques, itens); e2e verde"
```

---

## Self-Review (feito)

- **Cobertura da spec:** logica pura (Tasks 2–6), dados/Resource (7,15), combatants (8), input swipe/parry (9), reação/telégrafo (10,12), turnos via await (11), UI (12), cena Level1 + placeholders (13), fluxo MainMenu→CharacterSelect→Level1 (14), balanceamento 10/3 (13/15), GUT espelhando 21 testes (2–6,8,13,15), GameState no lugar de PlayerPrefs (1,14). ✔
- **Placeholders:** todo passo de código tem código real; nenhum "TODO". ✔
- **Consistência de tipos:** `CombatEnums.*`, `ReactionResolver.resolve`, `CombatMath.rolar_dano/dano_contra`, `Vitals`, `Targeting.resolver`, `EnemyAI.*`, `HitData`, `AtaqueInimigo.hits`, `ArenaUI` API e sinais do `BattleController` batem entre tarefas. ✔
- **Nota:** Godot headless é rápido (segundos), então cada tarefa roda seus testes sem o custo que o Unity tinha.
