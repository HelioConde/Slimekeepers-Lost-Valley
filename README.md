# Slimekeepers-Lost-Valley

Projeto Godot 4.7.2. Abra `project.godot` e escolha **Novo Jogo**.

O Mapa 01 ativo é `scenes/regions/FlorestaDoDespertarV2.tscn`: 200×200 tiles, quatro habitats e oito Brotinhos. A saída sul conecta ao Vale das Nascentes; use **E** junto à passagem.

Relatório, capturas e limites conhecidos: [Floresta v2](docs/world/forest_v2/RELATORIO_FINAL.md).

Primeira coleta jogável: faça amizade com um Brotinho e use **E** junto às pequenas plantas dos caminhos para guardar sementes na **Bolsa**. O inventário da sessão acompanha a viagem ao Vale e é reiniciado em **Novo Jogo**. Detalhes e limitações: [Primeira coleta](docs/gameplay/PRIMEIRA_COLETA.md).

Primeiro cultivo jogável: no **Vale das Nascentes**, use **E** em um dos dois canteiros próximos ao caminho de entrada. Uma semente é consumida; após **120 minutos do tempo do jogo**, volte e colha **folhas frescas**, que aparecem na mesma bolsa. O progresso acompanha a viagem entre regiões e é reiniciado em **Novo Jogo**. [Guia do primeiro canteiro](docs/gameplay/PRIMEIRO_CANTEIRO.md).

Validação local: `tools/validate_forest.ps1`. As cenas antigas foram preservadas; o checkpoint restaurável está em `docs/backups/before_forest_v2_20261027.zip`.

## História e direção narrativa

A referência oficial de história, personagens, slimes, revelações e progressão está na [Bíblia Narrativa](docs/narrativa/BIBLIA_NARRATIVA.md). **Atenção:** este documento contém spoilers completos da campanha principal e da DLC planejada. Os pontos marcados como **EM ABERTO** ainda não foram definidos.

O [plano de desenvolvimento](PLANO_DE_DESENVOLVIMENTO.md) registra etapas e hipóteses de implementação, mas decisões narrativas provisórias não substituem a Bíblia Narrativa.
