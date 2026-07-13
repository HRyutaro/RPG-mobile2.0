# Mira com Zoom + Escolha de Alvo — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No turno do jogador, ao Atacar ou usar habilidade, a câmera dá zoom e o jogador escolhe o inimigo alvo (single: swipe ←→ + confirmar; AoE: enquadra todos), conforme `docs/superpowers/specs/2026-07-13-mira-zoom-alvo-design.md`.

**Architecture:** Lógica de ciclagem de alvo pura e testada (`TargetCycler`); um `TargetingController` (Node) orquestra câmera/entrada/UI; `BattleController` entra na mira e aguarda o resultado via `await`. Colisor `Area3D` nos inimigos permite confirmar por toque (raycast).

**Tech Stack:** Godot 4.7, GDScript, GUT.

## Global Constraints

- Binário Godot: `C:\godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`
- Projeto: `D:\Godot\Projetos\rpg-tatico-mobile`
- Namespace por `class_name`; nomes `snake_case`.
- Mira só no turno do jogador; mana da habilidade é gasta **só no confirmar**; cancelar não gasta turno nem mana.
- Single: swipe ←→ troca foco; Confirmar (botão ou toque no inimigo); Voltar (botão ou swipe ↓).
- AoE: enquadra todos; Confirmar/toque acerta todos; Voltar/↓ cancela.
- TDD na lógica pura (GUT). Nodes/câmera/UI: implementar + verificar sem erros no headless.

### Como rodar os testes (usado nas tarefas)

```bash
GODOT="C:/godot/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64.exe"
PROJ="D:/Godot/Projetos/rpg-tatico-mobile"
"$GODOT" --headless --path "$PROJ" --import   # após adicionar class_name novo
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -8
```
Um arquivo: acrescente `-gtest=res://test/<arquivo>.gd`. Editor precisa estar FECHADO.

---

## File Structure

```
scripts/logic/target_cycler.gd     class_name TargetCycler (static, puro)
scripts/targeting_controller.gd    class_name TargetingController (Node)
scripts/combatant.gd               + adicionar_colisor_clique()
scripts/arena_ui.gd                + botoes Confirmar/Voltar + mostrar_mira()
scripts/battle_controller.gd       + entra na mira (await) em Atacar/Habilidade
scripts/level1.gd                  cria/fia TargetingController; pausa follow; @export enquadramento; colisor nos inimigos
test/test_target_cycler.gd         testes GUT
```

---

### Task 1: TargetCycler (lógica pura, TDD)

**Files:**
- Create: `scripts/logic/target_cycler.gd`
- Test: `test/test_target_cycler.gd`

**Interfaces:**
- Produces: `TargetCycler.proximo(vivos: Array, atual: int, dir: int) -> int` — próximo índice **vivo** na direção `dir` (+1/-1), com wrap, pulando mortos; se não houver outro vivo retorna `atual`.

- [ ] **Step 1: Teste que falha — `test/test_target_cycler.gd`**

```gdscript
extends GutTest

func test_direita_simples():
	assert_eq(TargetCycler.proximo([true, true, true], 0, 1), 1)

func test_esquerda_faz_wrap():
	assert_eq(TargetCycler.proximo([true, true, true], 0, -1), 2)

func test_direita_faz_wrap():
	assert_eq(TargetCycler.proximo([true, true, true], 2, 1), 0)

func test_pula_morto():
	assert_eq(TargetCycler.proximo([true, false, true], 0, 1), 2)

func test_um_inimigo_retorna_ele():
	assert_eq(TargetCycler.proximo([true], 0, 1), 0)

func test_atual_morto_acha_vivo():
	assert_eq(TargetCycler.proximo([false, true, false], 0, 1), 1)

func test_nenhum_outro_vivo_mantem():
	assert_eq(TargetCycler.proximo([false, true, false], 1, 1), 1)
```

- [ ] **Step 2: Rodar e ver falhar**

```bash
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_target_cycler.gd -gexit 2>&1 | tail -8
```
Expected: falha (TargetCycler inexistente).

- [ ] **Step 3: `scripts/logic/target_cycler.gd`**

```gdscript
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
```

- [ ] **Step 4: Importar e rodar — ver passar**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_target_cycler.gd -gexit 2>&1 | tail -8
```
Expected: `Passing 7 | Failing 0`.

- [ ] **Step 5: Commit**

```bash
cd "$PROJ" && git add scripts/logic/target_cycler.gd test/test_target_cycler.gd
git commit -m "feat: TargetCycler (proximo alvo vivo com wrap) com testes"
```

---

### Task 2: Colisor de toque nos inimigos

**Files:**
- Modify: `scripts/combatant.gd` (adicionar método)
- Modify: `scripts/level1.gd` (chamar nos inimigos)

**Interfaces:**
- Consumes: nada novo.
- Produces: `Combatant.adicionar_colisor_clique()` — cria um `Area3D` + `CapsuleShape3D` no combatente, com `set_meta("inimigo", self)` pro raycast identificar o dono.

- [ ] **Step 1: `scripts/combatant.gd` — novo método** (após `adicionar_barra_flutuante`)

```gdscript
func adicionar_colisor_clique() -> void:
	var area := Area3D.new()
	area.set_meta("inimigo", self)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.7
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	area.add_child(cs)
	add_child(area)
```

- [ ] **Step 2: `scripts/level1.gd` — chamar nos inimigos**

Em `_spawn_enemies`, logo após `e.adicionar_barra_flutuante(...)`:

```gdscript
		e.adicionar_barra_flutuante(barra_largura, barra_altura, barra_altura_cabeca, Color(0.95, 0.15, 0.15))
		e.adicionar_colisor_clique()
```

- [ ] **Step 3: Importar e verificar (compila + smoke)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR" | grep -viE "\.tres|\.res|\.tga|\.png|\.FBX" | head || echo "sem erros"
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gtest=res://test/test_level1_smoke.gd -gexit 2>&1 | tail -6
```
Expected: sem SCRIPT ERROR; smoke `Passing 1`.

- [ ] **Step 4: Commit**

```bash
cd "$PROJ" && git add scripts/combatant.gd scripts/level1.gd
git commit -m "feat: colisor Area3D nos inimigos para confirmar alvo por toque"
```

---

### Task 3: Botões Confirmar/Voltar na ArenaUI

**Files:**
- Modify: `scripts/arena_ui.gd`

**Interfaces:**
- Produces: sinais `confirmar_mira`, `voltar_mira`; método `mostrar_mira(v: bool)` que exibe/esconde os dois botões.

- [ ] **Step 1: `scripts/arena_ui.gd` — sinais e campos**

No topo, junto aos outros `signal`:

```gdscript
signal confirmar_mira
signal voltar_mira
```

Junto aos campos de nós (perto de `var _parry_btn`):

```gdscript
var _btn_confirmar: Button
var _btn_voltar: Button
```

- [ ] **Step 2: `scripts/arena_ui.gd` — criar os botões no `_montar`**

Logo após o bloco do `_parry_btn` (antes do fim de `_montar`):

```gdscript
	# botoes de mira (escondidos; so aparecem no modo de mira)
	_btn_confirmar = _make_btn("Confirmar", func(): confirmar_mira.emit())
	_btn_confirmar.anchor_left = 0.5; _btn_confirmar.anchor_top = 1.0
	_btn_confirmar.anchor_right = 0.5; _btn_confirmar.anchor_bottom = 1.0
	_btn_confirmar.offset_left = 10; _btn_confirmar.offset_top = -80
	_btn_confirmar.offset_right = 180; _btn_confirmar.offset_bottom = -20
	_btn_confirmar.visible = false
	add_child(_btn_confirmar)

	_btn_voltar = _make_btn("Voltar", func(): voltar_mira.emit())
	_btn_voltar.anchor_left = 0.5; _btn_voltar.anchor_top = 1.0
	_btn_voltar.anchor_right = 0.5; _btn_voltar.anchor_bottom = 1.0
	_btn_voltar.offset_left = -180; _btn_voltar.offset_top = -80
	_btn_voltar.offset_right = -10; _btn_voltar.offset_bottom = -20
	_btn_voltar.visible = false
	add_child(_btn_voltar)
```

- [ ] **Step 3: `scripts/arena_ui.gd` — método `mostrar_mira`** (perto de `mostrar_parry`)

```gdscript
func mostrar_mira(v: bool) -> void:
	if _btn_confirmar: _btn_confirmar.visible = v
	if _btn_voltar: _btn_voltar.visible = v
```

- [ ] **Step 4: Importar e verificar**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR" | grep -viE "\.tres|\.res|\.tga|\.png|\.FBX" | head || echo "sem erros"
```
Expected: sem SCRIPT ERROR.

- [ ] **Step 5: Commit**

```bash
cd "$PROJ" && git add scripts/arena_ui.gd
git commit -m "feat: botoes Confirmar/Voltar da mira na ArenaUI"
```

---

### Task 4: TargetingController

**Files:**
- Create: `scripts/targeting_controller.gd`

**Interfaces:**
- Consumes: `TargetCycler`, `Camera3D`, `EnemyCombatant`.
- Produces: `TargetingController` (Node) com:
  - `enum Modo { SINGLE, AOE }`
  - `configurar(cam: Camera3D)` — guarda a câmera.
  - `iniciar(enemies: Array, modo: int)` — entra na mira, enquadra.
  - `ativo: bool`, `resultado_ok: bool`, `resultado_alvo` (EnemyCombatant no single, `null` no AoE).
  - sinal `resolvido` (sem args; leia `resultado_ok`/`resultado_alvo` depois).
  - params de enquadramento: `dist_single, altura_single, dist_aoe, altura_aoe`.
  - conectar `ArenaUI.confirmar_mira`→`confirmar`, `ArenaUI.voltar_mira`→`cancelar` (feito no Level1).

- [ ] **Step 1: `scripts/targeting_controller.gd`**

```gdscript
class_name TargetingController
extends Node

signal resolvido

enum Modo { SINGLE, AOE }

var ativo := false
var resultado_ok := false
var resultado_alvo = null

# enquadramento (setado pelo Level1)
var dist_single := 3.0
var altura_single := 1.6
var dist_aoe := 7.0
var altura_aoe := 3.0

var _cam: Camera3D
var _transform_normal: Transform3D
var _enemies: Array = []
var _modo := Modo.SINGLE
var _foco := 0
var _px_min := 60.0
var _inicio_toque := Vector2.ZERO
var _rastreando := false

func configurar(cam: Camera3D) -> void:
	_cam = cam

func iniciar(enemies: Array, modo: int) -> void:
	_enemies = enemies
	_modo = modo
	_transform_normal = _cam.global_transform
	_foco = _primeiro_vivo()
	if _foco == -1:
		cancelar()
		return
	ativo = true
	resultado_ok = false
	resultado_alvo = null
	_enquadrar()

func _primeiro_vivo() -> int:
	for i in _enemies.size():
		if _enemies[i] != null and _enemies[i].esta_vivo():
			return i
	return -1

func _vivos() -> Array:
	var r := []
	for e in _enemies:
		r.append(e != null and e.esta_vivo())
	return r

func trocar_foco(dir: int) -> void:
	if _modo != Modo.SINGLE:
		return
	_foco = TargetCycler.proximo(_vivos(), _foco, dir)
	_enquadrar()

func confirmar() -> void:
	if not ativo:
		return
	resultado_ok = true
	resultado_alvo = _enemies[_foco] if _modo == Modo.SINGLE else null
	_sair()

func confirmar_inimigo(inimigo) -> void:
	if not ativo:
		return
	resultado_ok = true
	resultado_alvo = inimigo if _modo == Modo.SINGLE else null
	_sair()

func cancelar() -> void:
	if not ativo:
		resolvido.emit()
		return
	resultado_ok = false
	resultado_alvo = null
	_sair()

func _sair() -> void:
	ativo = false
	_tween_cam(_transform_normal)
	resolvido.emit()

func _enquadrar() -> void:
	if _modo == Modo.AOE:
		_tween_cam(_pos_para(_centro_vivos(), dist_aoe, altura_aoe))
	else:
		_tween_cam(_pos_para(_enemies[_foco].global_position, dist_single, altura_single))

func _centro_vivos() -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for e in _enemies:
		if e != null and e.esta_vivo():
			c += e.global_position
			n += 1
	return c / max(1, n)

func _pos_para(alvo: Vector3, dist: float, altura: float) -> Transform3D:
	# camera do lado do player (z positivo em relacao ao alvo), olhando pro alvo
	var t := Transform3D()
	t.origin = alvo + Vector3(0, altura, dist)
	return t.looking_at(alvo + Vector3(0, 1.0, 0), Vector3.UP)

func _tween_cam(destino: Transform3D) -> void:
	var tw := create_tween()
	tw.tween_property(_cam, "global_transform", destino, 0.3).set_trans(Tween.TRANS_SINE)

func _unhandled_input(event: InputEvent) -> void:
	if not ativo:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_inicio_toque = event.position; _rastreando = true
		else:
			_fim_gesto(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_inicio_toque = event.position; _rastreando = true
		else:
			_fim_gesto(event.position)

func _fim_gesto(pos: Vector2) -> void:
	if not _rastreando:
		return
	_rastreando = false
	var d := pos - _inicio_toque
	if d.length() < _px_min:
		# toque = confirmar no inimigo tocado (raycast)
		var alvo = _raycast_inimigo(pos)
		if alvo != null:
			confirmar_inimigo(alvo)
		return
	if absf(d.x) > absf(d.y):
		trocar_foco(1 if d.x > 0 else -1)
	elif d.y > 0:
		cancelar() # swipe pra baixo = voltar

func _raycast_inimigo(pos: Vector2):
	if _cam == null:
		return null
	var origem := _cam.project_ray_origin(pos)
	var destino := origem + _cam.project_ray_normal(pos) * 100.0
	var q := PhysicsRayQueryParameters3D.create(origem, destino)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var hit := _cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var col = hit.collider
	if col != null and col.has_meta("inimigo"):
		return col.get_meta("inimigo")
	return null
```

- [ ] **Step 2: Importar e verificar (compila)**

```bash
"$GODOT" --headless --path "$PROJ" --import 2>&1 | grep -iE "SCRIPT ERROR|Parse Error" | grep -viE "\.tres|\.res|\.tga|\.png|\.FBX" | head || echo "sem erros"
```
Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
cd "$PROJ" && git add scripts/targeting_controller.gd
git commit -m "feat: TargetingController (zoom, swipe, raycast, confirmar/voltar via await)"
```

---

### Task 5: Integração no BattleController

**Files:**
- Modify: `scripts/battle_controller.gd`

**Interfaces:**
- Consumes: `TargetingController`, `ArenaUI`, `CombatEnums`.
- Produces: `BattleController.targeting` (setado pelo Level1); `_on_atacar`/`_on_habilidade` passam a entrar na mira e aguardar.

- [ ] **Step 1: `scripts/battle_controller.gd` — campo `targeting`**

Junto aos outros campos (perto de `var reaction`):

```gdscript
var targeting = null # TargetingController (setado pelo Level1)
```

- [ ] **Step 2: Substituir `_on_atacar` e `_on_habilidade`**

Trocar as funções `_on_atacar` e `_on_habilidade` atuais por:

```gdscript
func _on_atacar() -> void:
	if not _pronto(): return
	_mira_e_executar(TargetingController.Modo.SINGLE, func():
		_executar_ataque_basico())

func _on_habilidade(h: Habilidade) -> void:
	if not _pronto(): return
	if player.vitals.mana < h.custo_mana:
		_log("Mana insuficiente para %s." % h.nome)
		return
	var modo := TargetingController.Modo.SINGLE if h.alvo == CombatEnums.TargetMode.SINGLE else TargetingController.Modo.AOE
	_mira_e_executar(modo, func():
		player.vitals.gastar_mana(h.custo_mana)
		_executar_habilidade(h))
```

- [ ] **Step 3: `scripts/battle_controller.gd` — helper `_mira_e_executar`**

Adicionar (perto de `_executar_ataque_basico`):

```gdscript
func _mira_e_executar(modo: int, acao: Callable) -> void:
	_ocupado = true
	if ui != null:
		ui.set_menu_visivel(false) # tambem esconde o painel de habilidades
		ui.mostrar_mira(true)
	targeting.iniciar(enemies, modo)
	await targeting.resolvido
	if ui != null:
		ui.mostrar_mira(false)
	if not targeting.resultado_ok:
		_ocupado = false
		_turno_jogador()
		return
	if targeting.resultado_alvo != null:
		_alvo = targeting.resultado_alvo
	else:
		_garantir_alvo()
	acao.call()
```

(No Godot o painel de habilidades vive dentro do `ArenaUI`; `set_menu_visivel(false)` já o esconde — não há `habilidadeList` separado.)

- [ ] **Step 4: Importar e rodar suíte**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -8
```
Expected: sem SCRIPT ERROR; suíte verde (nada quebrou — a mira ainda não é acionada no smoke, pois o smoke não clica em Atacar).

- [ ] **Step 5: Commit**

```bash
cd "$PROJ" && git add scripts/battle_controller.gd
git commit -m "feat: BattleController entra na mira (await) em Atacar/Habilidade; mana so no confirmar"
```

---

### Task 6: Fiação no Level1 + pausa do follow + enquadramento + smoke

**Files:**
- Modify: `scripts/level1.gd`
- Modify: `test/test_level1_smoke.gd`

**Interfaces:**
- Consumes: tudo anterior.
- Produces: `Level1` cria e fia o `TargetingController`; pausa o follow da câmera enquanto a mira está ativa; expõe `@export` de enquadramento.

- [ ] **Step 1: `scripts/level1.gd` — campo + @export**

Junto aos campos (perto de `var _lanes_chao`):

```gdscript
var _targeting: TargetingController
```

Novo grupo de `@export` (perto do grupo Camera):

```gdscript
@export_group("Mira (enquadramento)")
@export var mira_dist_single := 3.0
@export var mira_altura_single := 1.6
@export var mira_dist_aoe := 7.0
@export var mira_altura_aoe := 3.0
```

- [ ] **Step 2: `scripts/level1.gd` — criar/fiar em `_montar_sistemas`**

No fim de `_montar_sistemas` (após a fiação atual), acrescentar:

```gdscript
	_targeting = TargetingController.new()
	_targeting.configurar(_cam)
	_targeting.dist_single = mira_dist_single
	_targeting.altura_single = mira_altura_single
	_targeting.dist_aoe = mira_dist_aoe
	_targeting.altura_aoe = mira_altura_aoe
	add_child(_targeting)
	_battle.targeting = _targeting
	_ui.confirmar_mira.connect(_targeting.confirmar)
	_ui.voltar_mira.connect(_targeting.cancelar)
```

- [ ] **Step 3: `scripts/level1.gd` — pausar follow da câmera na mira**

No `_process`, trocar o bloco do follow por:

```gdscript
func _process(dt: float) -> void:
	if _cam != null and _player != null and not (_targeting != null and _targeting.ativo):
		var alvo := cam_pos.x + _player.position.x * cam_seguir
		_cam.position.x = lerpf(_cam.position.x, alvo, clampf(dt * cam_seguir_vel, 0.0, 1.0))
	# ajuste de arma em tempo real (mantido)
	if _player != null:
		if _player.tipo == CombatEnums.CharacterType.GATUNA:
			_player.ajustar_arma(arco_offset, arco_rot, arco_escala)
		else:
			_player.ajustar_arma(arma_offset, arma_rot, arma_escala)
	for e in _enemies:
		if e != null:
			e.ajustar_arma(arma_inimigo_offset, arma_inimigo_rot, arma_inimigo_escala)
```

- [ ] **Step 4: `test/test_level1_smoke.gd` — checar TargetingController presente**

Acrescentar ao final do teste existente:

```gdscript
	var alvos = inst.find_children("*", "TargetingController", true, false)
	assert_gt(alvos.size(), 0, "ha TargetingController no Level1")
```

- [ ] **Step 5: Importar e rodar suíte**

```bash
"$GODOT" --headless --path "$PROJ" --import
"$GODOT" --headless --path "$PROJ" -s res://addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit 2>&1 | tail -8
```
Expected: suíte verde (inclui o smoke exigindo o TargetingController).

- [ ] **Step 6: Commit**

```bash
cd "$PROJ" && git add scripts/level1.gd test/test_level1_smoke.gd
git commit -m "feat: Level1 fia TargetingController, pausa follow na mira, @export enquadramento; smoke"
```

---

## Self-Review (feito)

- **Cobertura da spec:** TargetCycler + testes (Task 1); colisor p/ toque (Task 2); botões Confirmar/Voltar (Task 3); TargetingController com zoom single/AoE, swipe ←→↓, raycast, confirmar/cancelar (Task 4); integração Atacar/Habilidade single/AoE + mana só no confirmar + cancelar sem gastar turno (Task 5); Level1 fia + pausa follow + enquadramento @export + smoke (Task 6). ✔
- **Placeholders:** todo passo tem código real; nenhum "TODO". O painel de habilidades é escondido por `ui.set_menu_visivel(false)` (que também esconde `_hab_panel`), sem `habilidadeList` separado. ✔
- **Consistência de tipos:** `TargetCycler.proximo`, `TargetingController` (Modo, iniciar, ativo, resultado_ok/alvo, resolvido, confirmar/cancelar/confirmar_inimigo), `Combatant.adicionar_colisor_clique`, `ArenaUI.mostrar_mira`/sinais, `BattleController.targeting` batem entre tarefas. ✔
