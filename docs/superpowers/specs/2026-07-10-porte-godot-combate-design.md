# Porte do RPG por Turnos para Godot (GDScript) — Design

**Data:** 2026-07-10
**Origem:** porte do projeto Unity `D:\Unity\projetos\RPG tatico mobile`
(sistema de combate já implementado e testado) para um projeto Godot novo.
**Engine alvo:** Godot 4.7 (preset Mobile), GDScript.
**Local:** `D:\Godot\Projetos\rpg-tatico-mobile`.

## Visão e escopo (Marco 1)

Portar o **núcleo jogável** do combate para o Godot com GDScript, mantendo o
design de combate já validado (ver spec Unity
`2026-07-10-sistema-de-combate-design.md`): 1 herói, 3 lanes (-1/0/1), turno do
jogador (Atacar/Habilidades/Itens), defesa reativa em tempo real no turno do
inimigo (arrastar troca de lane = esquiva; botão parry na janela = anula +
contra-ataque; ataque nas 3 lanes força parry). Ataque inimigo = sequência de
hits (v1 = 1 hit).

**O Marco 1 entrega, jogável de ponta a ponta:**
- Fluxo completo de telas: **MainMenu → CharacterSelect → Level1**.
- Combate funcional com **placeholders** (cápsulas coloridas, sem modelos/animações).
- Lógica pura portada e **testada com GUT** (espelhando os 21 testes do Unity).

**Fora do escopo do Marco 1 (specs futuras):** modelos 3D reais + animações,
cenário/floresta bonito, arte final de UI, tap-to-target refinado, progressão.

## Setup do projeto

- `project.godot` com preset Mobile, `config/features` = `"4.7"`.
- GUT vendorizado em `addons/gut/` (espelhando o dragon-runner) para rodar a
  suíte de lógica headless.
- Testes em `res://test/`.
- Binário para testes/imports: `C:\godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`.

## Mapeamento Unity → Godot

| Unity (C#) | Godot (GDScript) |
|---|---|
| `Vitals`, `ReactionResolver`, `CombatMath`, `Targeting`, `EnemyAI` (classes puras) | `RefCounted` com `class_name` + `static func` — testáveis via GUT |
| enums `Lane`/`HitOutcome`/`TargetMode`/`CharacterType` | enums GDScript (em um script de constantes com `class_name`) |
| `HabilidadeSO`/`EnemyAttackSO`/`ItemSO` (ScriptableObject) | `Resource` com `@export`, salvos como `.tres` |
| `Combatant`/`PlayerCombatant`/`EnemyCombatant` (MonoBehaviour) | scripts em `Node3D` (cápsula placeholder) |
| `BattleController` (corrotinas) | Node com máquina de turnos via `await` + signals + `get_tree().create_timer().timeout` |
| `ReactionController` (tempo real) | Node com timer + polling de input via `_process` |
| `SwipeInput` (touch/drag) | `_unhandled_input` (arrasto) + Button de parry |
| UI uGUI (Canvas) | `CanvasLayer` + `Control` (Button, `TextureProgressBar`, `Label`) |
| Cenas `.unity` | `.tscn` |
| `PlayerPrefs` (personagem escolhido) | autoload simples `GameState` (ou `ProjectSettings`/arquivo) guardando a classe escolhida entre cenas |

**Diferença conceitual principal:** as corrotinas do Unity viram fluxo
`await`/signal no Godot. O *design* dos turnos é idêntico; só a mecânica de
espera muda (`await get_tree().create_timer(t).timeout` no lugar de
`yield return new WaitForSeconds(t)`).

## Componentes

### Dados (`res://data/` como `Resource` + `.tres`)

- `Habilidade` (`Resource`): `nome, descricao, custo_mana, dano_min, dano_max,
  alvo (TargetMode), cast_time`; método `gerar_dano()`.
- `AtaqueInimigo` (`Resource`): `nome`, `hits: Array[Hit]`; cada `Hit` =
  `{dano_min, dano_max, telegraph_time, parry_window_start, parry_window_duration}`.
  v1: 1 hit.
- `Item` (`Resource`): `nome, tipo (Cura/Mana), quantidade`.

### Lógica pura (`res://scripts/logic/`, `RefCounted` + `class_name`)

- `Vitals` — HP/mana: `hp, mana, max_hp, max_mana`, `esta_vivo()`,
  `receber_dano()`, `curar()`, `gastar_mana()`, `restaurar_mana()`.
- `ReactionResolver.resolve(player_lane, lanes_ameacadas, parry_pressed,
  parry_na_janela) -> HitOutcome` (`static func`).
- `CombatMath.rolar_dano(min, max, rng=null)`, `CombatMath.dano_contra(base)`.
- `Targeting.resolver(modo, selecionado, todos, callable_vivo) -> Array`.
- `EnemyAI.escolher_qtd_lanes(roll100)`, `EnemyAI.escolher_lanes_ameacadas(qtd, rng)`.
- `Enums` — `Lane {LEFT=-1, CENTER=0, RIGHT=1}`, `HitOutcome {DODGED, PARRIED, HIT}`,
  `TargetMode {SINGLE, AOE}`, `CharacterType {PALADINO, MAGO, GATUNA}`.

### Runtime (`res://scripts/`, Nodes)

- `Combatant` (`Node3D`) — segura um `Vitals`, stats exportados, `receber_dano()`,
  move placeholder.
- `PlayerCombatant` — + `lane_atual`, `habilidades`, `mover_para(lane)`.
- `EnemyCombatant` — + `ataques`, `escolher_ataque(rng)`.
- `BattleController` (`Node`) — máquina de turnos (setup, turno jogador, resolve
  ação, turno inimigo, checa fim) via `await`.
- `ReactionController` (`Node`) — roda telégrafo + janela + resolução do hit.
- `SwipeInput` (`Node`) — arrasto horizontal → sinal de troca de lane; botão parry.

### Telas (`res://scenes/`)

- `MainMenu.tscn` — botões Novo Jogo / (Continuar) / Sair.
- `CharacterSelect.tscn` — 3 botões de classe; ao confirmar, grava em `GameState`
  e carrega `Level1`.
- `Level1.tscn` — chão + luz + câmera + herói + inimigos + `CanvasLayer` de UI
  (menu de ação, HUDs, telégrafo por lane, botão parry, log).

## Fluxo de dados

```
MainMenu → CharacterSelect → GameState.classe_escolhida
  → Level1 (_ready): BattleController spawna herói (cápsula da classe) na lane 0
                     + 1–3 inimigos (cápsulas)
  → Turno do jogador (menu): Atacar / Habilidade (mana, single/AoE) / Item
  → Turno do inimigo: por inimigo vivo → IA escolhe AtaqueInimigo
        ReactionController: telégrafo (ColorRect por lane) + janela (timer)
           arrasto move lane; botão parry
           → ReactionResolver.resolve(...) → esquiva/parry/hit
           → parry: contra-ataque no inimigo
  → checa vitória/derrota → repete
```

## Input (mobile + editor)

- **Arrastar horizontal** (`InputEventScreenDrag`/mouse relativo em
  `_unhandled_input`) move o herói de lane durante a fase de reação.
- **Botão PARRY** (`Control`) chama o parry; só conta dentro da janela.
- **Mirar**: no Marco 1, mira automática no 1º inimigo vivo (tap-to-target fica
  para depois); habilidades AoE pegam todos.

## Testes (GUT, headless)

Espelham os 21 testes EditMode do Unity, cobrindo a lógica pura:
- `ReactionResolver` — esquiva/parry/hit para cada combinação.
- `CombatMath` — rolagem de dano dentro dos limites, contra-ataque, RNG injetado.
- `Vitals` — HP/mana (limites, morte, gasto/recuperação).
- `Targeting` — single vs AoE, alvo morto.
- `EnemyAI` — pesos de quantidade de lanes, lanes distintas.

Comando: `"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gdir=res://test
-ginclude_subdirs -gexit` (após um `--import` inicial para registrar class_names).

## Balanceamento (igual ao Unity atual)

- Herói: 10 HP. Inimigos: 3 HP. Dano de ataque inimigo: 2–3. Habilidades e
  ataque básico conforme os dados portados.

## Casos de borda

- Sem inimigos vivos → vitória; herói morre na reação → game over.
- Ataque nas 3 lanes sem parry → dano garantido (intencional).
- Mana insuficiente → ação bloqueada, sem consumir turno.
- Inimigo morto pelo contra-ataque → sai da ordem, hits restantes cancelados.
- Arrasto para lane fora de -1..1 → clamp.

## Nota sobre reaproveitamento

O `GameState` (autoload) substitui o `PlayerPrefs`. Não replicamos o singleton
`PlayerStats` do Unity — o `PlayerCombatant` vivo é a fonte de verdade e a UI lê
dele (evita o bug de dessincronização que o Unity tinha originalmente).
