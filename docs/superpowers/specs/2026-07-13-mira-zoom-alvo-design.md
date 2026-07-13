# Mira com Zoom + Escolha de Alvo — Design

**Data:** 2026-07-13
**Projeto:** RPG mobile por turnos (Godot 4.7, GDScript)
**Escopo:** modo de mira no turno do jogador — ao Atacar ou usar habilidade,
a câmera dá zoom e o jogador escolhe o inimigo alvo.

## Visão

Hoje o `Atacar` mira automaticamente no 1º inimigo vivo e habilidades AoE pegam
todos direto. Esta feature adiciona um **modo de mira cinematográfico**: ao
escolher uma ação ofensiva, a câmera aproxima e o jogador seleciona o alvo antes
de resolver.

## Fluxo

**Atacar / habilidade single-target → mira single:**
- Menu de ação some; câmera dá **zoom no 1º inimigo vivo** (enquadrado de perto).
- Aparecem botões **Confirmar** e **Voltar**.
- **Swipe ← →**: troca o inimigo em foco (pula mortos, dá a volta na lista).
- **Confirmar**: botão **ou** tocar no próprio inimigo (3D) → resolve a ação no
  inimigo em foco (se tocar um inimigo específico, o alvo é o tocado).
- **Voltar**: botão **ou** swipe **↓** → cancela; câmera volta; menu reaparece;
  **nenhum turno é gasto** (e mana não é consumida).
- **1 inimigo só**: mesma dinâmica (zoom nele → confirmar).

**Habilidade AoE → mira de área:**
- Câmera dá um **zoom menor enquadrando TODOS** os inimigos; botões Confirmar/Voltar.
- **Confirmar**: botão **ou** tocar em qualquer inimigo → acerta **todos**.
- **Voltar**: botão **ou** swipe ↓ → cancela.
- Sem swipe ← → (não há alvo único a percorrer).

## Componentes

### Lógica pura (`res://scripts/logic/`, testável com GUT)

- `TargetCycler.proximo(vivos: Array, atual: int, dir: int) -> int`
  - `vivos` = array de bool (inimigo i está vivo?); `atual` = índice atual;
    `dir` = +1 (direita) / -1 (esquerda).
  - Retorna o índice do próximo inimigo **vivo** na direção, com **wrap** e
    pulando mortos. Se não houver outro vivo, retorna o próprio `atual`.
  - Casos: 1 inimigo (retorna ele), todos mortos exceto um, wrap no fim/início.

### Runtime

- `TargetingController` (`Node`) — orquestra a mira.
  - Estado: `enemies: Array[EnemyCombatant]`, `foco: int`, `modo` (SINGLE/AOE),
    `ativo: bool`.
  - `iniciar(enemies, modo, cam, transform_normal)` — entra na mira, enquadra.
  - Escuta **swipe** (←→ troca foco no single; ↓ cancela) via `_unhandled_input`
    e **toque no inimigo** via raycast da câmera (`_unhandled_input` +
    `PhysicsDirectSpaceState3D.intersect_ray`).
  - Botões Confirmar/Voltar (na `ArenaUI`) chamam `confirmar()` / `cancelar()`.
  - **Dirige a câmera** com `Tween`: single → posição enquadrando o inimigo em
    foco (perto, olhando pra ele); AOE → posição mais afastada pegando todos.
    Troca de foco re-tweena. Ao sair, tweena de volta pro `transform_normal`.
  - Destaque discreto no inimigo em foco (ex.: leve escala/emissivo ou um marcador).
  - Sinais: `confirmado(alvo)` (alvo = EnemyCombatant no single, ou `null`/lista
    no AoE) e `cancelado`.

- **Colisor nos inimigos**: cada `EnemyCombatant` ganha um `Area3D` + `CollisionShape3D`
  (cápsula) no `preparar()`, pra o raycast do toque acertá-lo. O `Area3D` guarda
  referência ao `EnemyCombatant` dono (via `get_parent()` ou metadata).

### Integração

- `BattleController`:
  - `_on_atacar` → entra na mira **single**; em `confirmado(inimigo)` faz
    `_alvo = inimigo` e executa o ataque básico.
  - `_on_habilidade(h)` → checa mana (**sem gastar ainda**); entra na mira
    (single se `h.alvo == SINGLE`, senão AOE); em `confirmado(...)` **gasta a
    mana** e executa (single no alvo, AoE em todos vivos).
  - `cancelado` → reexibe o menu, sem gastar turno nem mana.
  - Ganha ref ao `TargetingController` (setada pelo `Level1`).

- `Level1`:
  - Cria o `TargetingController`, passa a câmera e o transform normal.
  - **Pausa o follow** da câmera (`_process`) enquanto `targeting.ativo`.
  - Expõe no Inspector os parâmetros de enquadramento (single/AoE: distância,
    altura, ângulo) pra calibração — `@export`.

- `ArenaUI`:
  - Botões **Confirmar** e **Voltar**, visíveis só na mira; chamam callbacks.
  - `set_menu_visivel(false)` já esconde o menu de ação; a mira usa isso.

## Fluxo de dados

```
Turno do jogador (menu)
  Atacar / habilidade single:
     BattleController -> TargetingController.iniciar(enemies, SINGLE)
        camera zoom no foco; swipe ←→ = TargetCycler.proximo; ↓/Voltar = cancelar
        toque no inimigo (raycast) OU Confirmar -> confirmado(inimigo)
     -> BattleController: _alvo = inimigo; (habilidade: gasta mana) executa
     -> camera volta ao normal -> segue pro turno do inimigo
  Habilidade AoE:
     TargetingController.iniciar(enemies, AOE) -> enquadra todos
        Confirmar / toque em qualquer inimigo -> confirmado(todos)
     -> executa em todos vivos
  Voltar/↓ em qualquer caso -> cancelado -> menu volta (turno/mana intactos)
```

## Casos de borda

- Inimigo em foco morre entre a mira e o confirmar (não deveria, pois é turno do
  jogador e ninguém morre nesse intervalo) → `_garantir_alvo` revalida antes de
  executar.
- Swipe ←→ com 1 inimigo vivo → foco permanece nele (TargetCycler retorna o mesmo).
- Toque que não acerta nenhum inimigo (raycast miss) → ignorado (não confirma).
- Cancelar não gasta turno nem mana.
- Durante a mira, o swipe de esquiva (turno do inimigo) não roda — são fases
  distintas; o `SwipeInput` da reação fica inativo no turno do jogador.

## Testes (GUT)

- `TargetCycler`: próximo vivo à direita/esquerda, wrap no fim/início, pula
  mortos, 1 inimigo (retorna ele), atual morto (acha o próximo vivo).
- Câmera/UI/raycast: verificação manual no editor + smoke que a Level1 instancia
  com o `TargetingController` sem erro.

## Fora de escopo

- Mira para itens (itens continuam agindo no player).
- Seleção de alvo para o turno do inimigo (a IA já escolhe as lanes).
- Marcador/HUD elaborado de alvo (um destaque simples basta).
