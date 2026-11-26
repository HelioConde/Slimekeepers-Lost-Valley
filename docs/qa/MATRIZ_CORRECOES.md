# Matriz das correções do playtest v1.0

Fonte: `docs/qa/RELATORIO_PLAYTEST_v1.0.md`, transcrito do .docx de 2026-11-26.

Regras do relatório:
- Só marcar "Feito" com teste executado e evidência.
- Os saves (56–58) vêm antes dos playtests longos.
- Os itens P0 vêm primeiro.
- **O PixelLab está suspenso**: arte nova fica pendente.
- A regra 54 (atualização 0.7) substitui os bloqueios por nível descritos em 06, 07, 43, 48 e 50.

Estados possíveis: Pendente · Em andamento · Feito (com teste) · Bloqueado (motivo).

| ID | Correção | Prio | Estado | Arquivos / teste / observação |
|---|---|---|---|---|
| 56 | Continuar abre progresso antigo | P0 | Feito (com teste) | 5fbe3f24 · save_game (espaços, .bak), start_menu · test_save_game, test_menu |
| 57 | Autosave a cada amanhecer | P0 | Feito (com teste) | 5fbe3f24 · clearing_region._on_time_for_autosave · tools/test_autosave.gd |
| 58 | Slots independentes de save | P0 | Feito (com teste) | 5fbe3f24 · start_menu (escolha e confirmação) · test_save_game (espaços isolados) |
| 35 | Energia zerada: exaustão e sono no local (50%) | P0 | Feito (com teste) | b886a650 (sessão Luz V4) · energy_state, clearing_region · tools/test_exhaustion.gd. Pendência MP: o dia só deve virar quando os dois dormirem |
| 39 | Virada do dia não recupera energia | P0 | Feito (com teste) | 663335d5 (sessão Luz V4) · farm_field, energy_state · test_farm_field |
| 22 | B/Esc não pausam o mundo em MP | P0 | Feito (com teste, MP simulado) | 23390052 · menu do Esc não pausa em MP; B/E/baú já não pausavam · test_pause_menu. Falta teste com duas instâncias |
| 20 | Coleta e drops visíveis para todos | P0 | Pendente | |
| 12 | Menu MP trava / troca P2P↔Local | P0 | Pendente | |
| 24 | Construir a mesma planta em dupla | P0 | Pendente | |
| 40 | Construção em etapas (planta sem custo, depósito de materiais) | P0 | Pendente | |
| 46 | Baú sincronizado em tempo real no MP | Crítica | Pendente | |
| 47 | Cama na progressão da casa | Crítica | Feito (com teste) | 98415b60 (aviso, sessão Luz V4) + entrada Cama na aba Construção (crafting_panel) · tools/test_craft_select.gd |
| 01 | Recursos básicos perto da estrada | P1 | Feito (com teste) | 214eae2a (sessão Luz V4): gravetos e pedrinhas à beira das trilhas perto do início · test_forest_foraging |
| 06 | Pedras no início | P1 | Feito (com teste) | 214eae2a (sessão Luz V4) + 54 (sem bloqueio por nível) · test_rocks, test_crafting_flow |
| 07 | Quebrar pedras, mais rendimento | P1 | Feito (com teste) | b3092823 (sessão Luz V4): pedra média 5, grande 12 · test_rocks |
| 05 | Árvores fantasmas | P1 | Feito (com teste) | 7c16705b (sessão Luz V4): árvores ocultas sem colisão nem alvo; árvores do início visíveis · tools/test_tree_collision.gd |
| 03 | Botão X nos painéis | P1 | Feito (com teste) | close_button.gd · tools/test_close_buttons.gd (disco do slime e lista do Vale ficam sem X: não são janelas) |
| 04 | Selecionar receita sem fabricar | P1 | Feito (com teste) | a4b187dc · crafting_panel · tools/test_craft_select.gd |
| 02 | Idle prematuro da Moni | P1 | Pendente | |
| 08 | Animação da foice (Moni) | P1 | Pendente | Foice longa instalada em 2026-11-23 (e7a21fa6); revisar com o playtest |
| 09 | Foice corta em área | P1 | Feito (com teste) | 471371b3 (sessão Luz V4): foice corta todo o mato do arco no contato · test_sickle |
| 10 | Aragem no frame do impacto | P1 | Feito (com teste) | bd40f798 (sessão Luz V4): enxada ara no contato · test_free_farm |
| 11 | Animação e duração do plantio | P2 | Pendente | Arte nova bloqueada pelo PixelLab; usar pose existente |
| 13 | Agente de playtest sem conhecimento privilegiado | P1 | Pendente | |
| 14 | "Multijogador" sem "(MP)" | P2 | Feito (com teste) | start_menu · tools/test_menu.gd (rótulo) |
| 15 | Idioma e volume de música separado | P1 | Em andamento | volume do ambiente e silenciar no menu do Esc (23390052); falta idioma e volume de música separado |
| 16 | Tutorial explicativo no menu | P1 | Feito (com teste) | botão Como jogar no menu principal + Tutorial no menu do Esc (23390052) · test_menu, test_pause_menu |
| 17 | MP começa na seleção de protagonista | P1 | Pendente | |
| 18 | Tutorial para os dois jogadores | P1 | Pendente | |
| 19 | Pedra inicial não coletável | P1 | Pendente | |
| 21 | Soltar itens para o outro jogador | P1 | Pendente | |
| 23 | Prévia da planta visível aos dois | P1 | Pendente | |
| 25 | Brilho estourado dos cogumelos | P1 | Pendente | |
| 26 | Alcance menor para interagir com slimes | P1 | Feito (com teste) | world.gd SLIME_REACH 48 · test_slime_disc, test_slime_reaction |
| 27 | Amanhecer gradual | P1 | Pendente | |
| 28 | Física de contato das árvores | P1 | Feito (com teste) | 7c16705b (sessão Luz V4) · tools/test_tree_collision.gd |
| 29 | Queda da árvore para o lado do corte | P1 | Feito (com teste) | 0074c132 (sessão Luz V4) |
| 30 | Pá para remover tocos | P1 | Pendente | Ícone e animação: verificar assets (PixelLab suspenso) |
| 31 | Foice do Aren | P1 | Pendente | Ver 08 |
| 32 | Tremor e impacto do machado no contato | P1 | Feito (com teste) | 5d7cf5c7 (sessão Luz V4) |
| 33 | Números legíveis (2/5/8) | P1 | Pendente | |
| 34 | Respawn diário por tipo (pedras limitadas) | P1 | Pendente | |
| 36 | Tremor da árvore no J2 | P1 | Pendente | |
| 37 | Barra rápida alarga no modo construção | P1 | Feito (com teste) | c0317d49 · hotbar_hud · tools/test_hotbar_click.gd |
| 38 | Barra: 1–9 e 0 | P1 | Feito (com teste) | de6841c9 · hotbar_hud · tools/test_hotbar_click.gd |
| 41 | Objeto visual bugado | P1 | Pendente | Precisa da imagem do .docx |
| 42 | Arrastar e soltar no inventário e na barra | Alta | Pendente | |
| 43 | Durabilidade e quebra de ferramentas | Alta | Pendente | |
| 44 | Escala do tronco caído | Alta | Feito (com teste) | 5cc04936 (sessão Luz V4) |
| 45 | Baú em duas colunas, arrastar, 1/metade/tudo | Alta | Pendente | |
| 48 | Balões contextuais (ferramenta, cansaço, cama) | Alta | Em andamento | 98415b60 (sessão Luz V4): aviso de pouca energia sem cama/com cama |
| 49 | Tamanho mínimo da casa | Alta | Feito (com teste) | mínimo 5×5 (3×3 por dentro, cama + passagem); aviso ao arrastar menor · test_house_state, capture_house |
| 50 | Cortar tocos e troncos de cenário | Alta | Pendente | |
| 51 | Porta e piso da casa | Alta | Feito (com teste) | house_builder._draw_floor: piso interno na célula da porta e soleira · capture_house. Pendência: tufos de capim da região ainda por cima do piso |
| 52 | Escala personagem × casa | Alta | Pendente | |
| 53 | Monte pequeno de pedras num toque | P1 | Feito (com teste) | be44a472 (sessão Luz V4) |
| 54 | Sem bloqueio por nível: o nível muda eficiência e desgaste | P1 | Feito (com teste) | f416a25b (sessão Luz V4) |
| 55 | Impacto da picareta no contato | P1 | Feito (com teste) | 5d7cf5c7 (sessão Luz V4) |
| 59 | Alimentar com ingredientes e pratos; preferências por ingrediente | P1 | Pendente | |
| 60 | Disco do slime só com ações disponíveis | P1 | Feito (com teste) | slime_action_disc: só ações disponíveis (desconfiado = só comida) · test_slime_disc |
| 61 | Menu de Esc centraliza a navegação; tirar o botão Menu do HUD | P1 | Feito (com teste) | 23390052 · pause_overlay, world.gd (sem botão Menu) · tools/test_pause_menu.gd, test_menu |
| 62 | Playtest solo por observação visual | P1 | Pendente | Depois dos P0 |
| 63 | Usuário no J1 e Claude no J2 | P1 | Pendente | Precisa do usuário |
| 64 | Comparativo com Stardew Valley | P1 | Pendente | Precisa de Stardew instalado e controlável |
| — | Roteador de modelos (Guided Model Router 2.2.0) | — | Declarado | Ver "Preparo do ambiente" abaixo |

## Preparo do ambiente (atualização 1.0, 2026-11-26)

| Item | Situação | Observação |
|---|---|---|
| Superpowers: TDD, Verification Before Completion, Systematic Debugging, Requesting Code Review | Já existia | Plugin `superpowers` |
| Balance Check, Generate2DSprite, Generate2DMap, Asset Gen | Já existia | Skills locais em `.claude/skills/`. As de arte não chamam o PixelLab enquanto ele estiver suspenso |
| GodotPrompter, godot-specialist, godot-gdscript-specialist | Já existia | Plugin e agentes locais |
| GdUnit4 e Godot MCP | Já existia | `addons/` |
| Guided Model Router 2.2.0 (`nobodyohm-web/claude-code-model-router`, MIT) | Declarado em `.claude/settings.json` | Fixado no commit revisado `351d044`. O Claude Code pede confiança e instala ao abrir a próxima sessão |

Revisão do roteador antes de declarar:
- **Hooks:** `UserPromptSubmit` roda `bin/classify.sh`, que dá uma dica de modelo e grava log em `~/.claude/router/`. `PreToolUse` (Task) roda `bin/log-dispatch.sh`, que registra a delegação.
- **Fallback pago:** `classify.sh` tem um fallback que manda o pedido ao Haiku pela API (`haiku_fallback: true` por padrão). Ele só dispara se `ANTHROPIC_API_KEY` existir no ambiente. Hoje a variável não existe (conferido sem ler o valor), então o fallback não roda. **Não definir essa variável** sem autorização.
- **`jq`:** não está instalado. Sem ele os hooks se abstêm (não fazem nada) e o `/router-stats` não funciona. Os subagentes fixados (`quick-haiku`, `worker-sonnet`, `deep-opus` e outros) funcionam mesmo assim. Instalar o `jq` (ex.: `winget install jqlang.jq`) é decisão do usuário.
- **Pendente:** registrar a versão instalada, os modelos disponíveis e uma delegação simples e outra complexa. Fica para depois de reiniciar a sessão.

> Nota (2026-11-26): `tools/test_living_regions.gd` falha na linha 45 (nenhum slime no habitat V03 do Vale). Passava em 2570dd4c; causa ainda não investigada.
