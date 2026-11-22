# Sobrevivência, coleta e fabricação

Pedido do usuário (2026-11-22): o início deve ser difícil de propósito, para que domesticar slimes valha a pena. Progressão pretendida:

trabalho manual → fabricação → agricultura → culinária → amizade com slimes → ajuda nas tarefas.

## Cadeia inicial

| Etapa | O quê | Onde |
|---|---|---|
| 1 | Coletar fibra (mato), graveto e pedra pequena com as mãos | Floresta, perto da Clareira |
| 2 | Corda = 3 fibras · Machado rudimentar = 2 gravetos + 2 pedras + 1 corda | Mãos (sem bancada) |
| 3 | Cortar árvore comum com o machado → tronco caído → processar em madeira | Floresta |
| 4 | Bancada = 6 madeiras + 3 cordas + 4 pedras; posicionar no mundo | Mãos, depois colocar |
| 5 | Enxada e regador (e futuras ferramentas), exigindo o machado na bolsa | Bancada |

As quantidades ficam em `data/crafting/recipes.gd` (só dados). A lógica está em `scripts/systems/crafting.gd`: as receitas são filtradas por estação (`maos`/`bancada`), os itens de `requires` precisam estar na bolsa mas não são gastos, e a transação é atômica: ou gasta tudo e entrega o resultado, ou não muda nada.

## Inventário

- Itens novos em `scripts/systems/item_catalog.gd`: `fibra`, `graveto`, `pedra_pequena`, `corda`, `madeira` (material), `machado` (ferramenta) e `bancada` (estação).
- Capacidade: até 99 unidades de cada material; ferramentas e estações, 1. O limite é aplicado em `forest_bag.add_item`.
- A barra rápida só mostra as ferramentas que o jogador tem.

## Estado (verificável)

| Parte | Estado |
|---|---|
| Itens, ícones, receitas, fabricação, capacidade | Feito, `tests/forest/test_crafting.gd` |
| Sprites da bancada (de frente) e do baú (de frente) | Feito |
| Coleta manual no mundo | Feito: **todo o mato da floresta dá fibra** (cerca de 4.280 tufos: os tiles de mato da `VegetationLow` e o mato do detalhe de chão da Clareira). Para arrancar, é preciso **segurar [E] por 4 s** (pedido do usuário: "não pode ser fácil"); soltar ou se afastar recomeça, e o personagem fica parado enquanto arranca. Dá 1 fibra por tufo. Graveto (6) e pedra (8) continuam como pontos na Clareira, pegos com um toque em [E]. Tudo volta no dia seguinte (`scripts/world/forage_spots.gd`, estado salvo em `forage_taken`). Com o machado selecionado e uma árvore ao alcance, cortar tem prioridade sobre arrancar o mato. Animações: o mato usa `pick_big` (agachado, duas mãos; fica no quadro das mãos no chão enquanto [E] está segurado e levanta ao arrancar); graveto e pedra usam `pick_small` (ajoelhado, uma mão). O personagem vira para o item. Captura: `docs/gameplay/ferramentas/pegar_no_jogo.png` (`tools/capture_pick_anims.gd`) |
| Interface de fabricação (mãos e bancada) | Feito: [C] abre (`scripts/ui/crafting_panel.gd`), ↑↓ escolhem, E fabrica, jogador parado enquanto aberta. Modo bancada pronto, falta a bancada no mundo |
| Árvores cortáveis, toco, regeneração, processar tronco | Feito (`scripts/world/choppable_trees.gd`): machado selecionado + [E]; 3 golpes derrubam (3 de energia cada), fica toco e tronco; 2 golpes no tronco dão 4 madeiras (2 de energia); volta a crescer em 3 dias; 3.778 árvores comuns, protegidas as de habitats de slimes (+80 px) e pontos de interesse (160 px, inclui a Árvore Centenária). Golpe usa a animação da enxada: **animação própria de machado pendente** |
| Posicionar a bancada no mundo, persistir | Feito (`scripts/world/station_placer.gd`): bancada selecionada mostra prévia à frente (verde/vermelha); só em chão livre, fora do lago e longe de outra bancada; [E] coloca e gasta o item; salva por região em `placed_stations`; [E] perto dela abre a fabricação da bancada. Por enquanto só na Floresta |
| Começar sem enxada/regador | Feito: o jogo começa sem ferramentas. Saves de antes da fabricação (sem a marca `crafting` no save) recebem enxada e regador ao carregar, para a fazenda não travar (`save_game.restore`, `tests/forest/test_save_game.gd`) |

## Decisões

- O machado é exigido na bolsa para fabricar na bancada e não é gasto. Não há durabilidade por enquanto: não faz falta para o design atual.
- A picareta fica para quando existir mineração; fabricar uma ferramenta sem uso seria simular algo que não existe.
- Os slimes não recebem habilidades novas aqui: a Bíblia diz só que slimes conquistados ajudam nas tarefas, e as habilidades por espécie continuam EM ABERTO.

## Evidências

- `tools/test_crafting_flow.gd` (jogo real, controle de verdade): coleta nos 26 pontos, [C] abre a janela, corda e machado fabricados, machado na barra, ponto coletado volta no dia seguinte. Resultado: 0 falhas.
- `docs/gameplay/criacao/00_coleta_clareira.png`: pontos de coleta na Clareira.
- `docs/gameplay/criacao/01_janela_fabricacao.png`: janela de fabricação.
- O mesmo teste corta uma árvore comum (3 golpes), processa o tronco (+4 madeiras), confere que nenhuma árvore de habitat é cortável e que a árvore volta após 3 dias. `docs/gameplay/criacao/02_arvore_cortada.png`.
- O teste segue até o fim: 4 árvores (16 madeiras), bancada fabricada, colocada e salva, [E] abre a bancada, enxada e regador fabricados. 21 verificações, 0 falhas. `docs/gameplay/criacao/03_bancada_colocada.png`, `04_janela_bancada.png`.
- Floresta ao meio-dia na Clareira: 123 FPS (antes 117–121 nas mesmas capturas).
