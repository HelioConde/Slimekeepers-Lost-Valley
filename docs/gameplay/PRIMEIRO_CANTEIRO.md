# Primeiro canteiro do Vale das Nascentes (removido)

> **Removido em 2026-11-22** a pedido do usuário: os canteiros de madeira não fazem parte do jogo. O plantio agora é livre, com a enxada em qualquer chão (ver `FAZENDA.md`). O texto abaixo fica como histórico.

## Prototipo jogavel

Este e o primeiro **ciclo de cultivo** depois da coleta de sementes com um Brotinho. A mecânica usa o `GameClock` existente, nao exige salvamento em disco e nao altera nenhum evento da Biblia Narrativa.

1. Na floresta, faça amizade com um **Brotinho** e recolha sementes silvestres com **E**.
2. Viaje ao **Vale das Nascentes** e procure os **dois canteiros** próximos ao caminho de entrada.
3. Em um canteiro vazio, use **E** para plantar **uma semente**. A bolsa desconta exatamente um item.
4. O plantio cresce ao longo de **120 minutos do tempo do jogo**. A interação informa o tempo restante.
5. Quando a planta estiver madura, use **E** para colher **uma folha fresca**, registrada na mesma bolsa.
6. Cada canteiro pode ser plantado e colhido **uma vez por partida** neste prototipo. Não é possível multiplicar sementes apertando E repetidamente.
7. Se o jogador sair do vale, o estado dos canteiros e a contagem dos itens persistem na **mesma sessão**; o crescimento usa o relogio global e nao para quando a região e descarregada.
8. **Novo Jogo** limpa sementes, folhas e ambos os canteiros e reinicia o relogio global.

## Arquivos

- `scripts/systems/forest_bag.gd` — bolsa agora suporta sementes e folhas frescas
- `scripts/systems/valley_starter_garden.gd` — regras de plantio, amadurecimento e colheita sem duplicações
- `scripts/world/valley_garden_bed.gd` — arte pixelada procedural dos estados vazio, crescendo, pronto e colhido
- `scripts/world/valley_region.gd` — dois canteiros sem colisão, interação e feedback
- `scripts/ui/forest_bag_hud.gd` — exibe os dois recursos
- `scripts/menu/start_menu.gd` — reinicialização dos canteiros
- `tools/test_valley_garden.gd` — teste headless nativo de ida, volta e cultivo completo

## Limites

Sem save persistente, cozinha, venda, irrigação, múltiplas culturas ou replantio automático por enquanto. As folhas frescas ficam guardadas para o próximo sistema (receita/consumo), sem inventar efeitos de jogo não aprovados.

O teste e executado pelo workflow `Slimekeepers - Testes reais de gameplay no Godot` com **Godot 4.7.2 stable**, junto dos testes anteriores. A automação comprova lógica técnica, nao substitui revisão visual humana.
