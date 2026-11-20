# Fase 2 — progresso local (Claude Code, sem PR)

Registro de entregas feitas em branches locais. A fila `automation/phase2_10h_queue.json`
**não** é marcada como `completed` aqui: a regra anti-retrabalho exige evidência de PR
integrada à `main`. Ao abrir/mesclar a PR, mova a evidência para a fila.

| Tarefa | Branch | Estado | Validação |
|---|---|---|---|
| `p2-session-reset-qa` | `feat/p2-session-reset-qa` | Implementada localmente; aguarda PR | gdUnit4 `tests/forest` 78/78; `tools/test_menu.gd` 62/62; `tools/test_region_travel.gd` 9/9; `tools/test_valley_garden.gd` 88/88; Godot MCP `validate_script` válido e 0 erros no editor |

## p2-session-reset-qa — 20/11/2026

- `scripts/systems/session_state.gd`: fonte única das 14 chaves de sessão em metas do `SceneTree` e `clear_session(tree)`.
- `scripts/menu/start_menu.gd`: Novo Jogo delega o reset a `SessionState.clear_session`; comportamento inalterado.
- `tests/forest/test_p2_session_reset.gd`: limpa bolsa/canteiro/marcos gravados pelos sistemas reais; preserva metas alheias; estado sobrevive até o reset; varredura de `scripts/` falha se uma chave de sessão nova não estiver na lista ou se a lista tiver entrada morta.
- Mutação conferida: remover `valley_discoveries` da lista faz a varredura falhar apontando `valley_region.gd`.
- Viagem: coberta por `tools/test_region_travel.gd` (metas permanecem no `SceneTree`).

## Próximas tarefas prontas

1. `p2-keyboard-feedback` — foco, tecla E, pausa e mensagens (deps concluídas).
2. `p2-tutorial-guidance` — objetivo contextual breve da culinária; **checar Bíblia Narrativa** para não inventar texto canônico.
3. Bloqueadas: `p2-pixellab-controlled-job` → `p2-visual-preview` → `p2-asset-import-qa` (créditos PixelLab exigem autorização); `p2-godot-regression` e `p2-review-release` dependem delas.
