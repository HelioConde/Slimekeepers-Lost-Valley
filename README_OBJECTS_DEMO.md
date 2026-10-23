# Slimekeepers: Lost Valley — objetos no mapa de teste da floresta

A cena `scenes/forest_meadow_demo.tscn` agora utiliza as imagens PixelLab que ja existem em `sprites/objects/` para montar uma clareira com objetos.

## Como testar

1. Atualize o projeto local com `git pull origin main` (salve ou faça commit das alteracoes locais antes).
2. Abra `scenes/forest_meadow_demo.tscn` no Godot.
3. Use **F6** para executar a cena. WASD ou setas movem o personagem; Shift corre e Espaco usa dash.
4. Passe na frente e atras das arvores para testar Y-sorting. A colisao e aplicada aos pes dos objetos (troncos, rochas e arbustos), nao as copas.
5. Abra o Inspetor do node `WorldObjects` para desativar a geracao automatica ou as colisoes durante os testes.

## Implementacao

- Cena principal `scenes/main.tscn`: nao foi modificada.
- Cena de teste: `scenes/forest_meadow_demo.tscn` (mantem o mesmo tileset).
- Script novo: `scripts/forest_objects.gd`, com lista deterministica de 44 posicionamentos.
- Arvores, pinheiros, arbustos, rochas, tocos e troncos caidos bloqueiam os pes do protagonista.
- Grama alta e flores sao decoracao e nao bloqueiam movimento.
- O ponto de contato do sprite com o solo e calculado pela area visivel de cada PNG, considerando margens transparentes.
- A raiz da cena e o container de objetos usam `y_sort_enabled` para desenhar o jogador na frente ou atras das arvores.
- Algumas arvores sao ampliadas para diferenciar tamanhos, pois a exportacao PixelLab utilizou canvases de 96x96 px para todos os carvalhos.

## Cuidados

Os objetos surgem durante a execucao (_ready), nao ficam pintados como nodes persistentes antes de apertar F6. A cena e apenas para validacao visual e de colisao. Para o mapa final recomendamos criar cenas reutilizaveis de arvore/recurso com vida, queda, inventario e interacoes.

Nenhuma imagem PixelLab foi substituida. Se um objeto nao carregar, confira se a pasta `sprites/objects` esta presente. O editor Godot nao foi executado durante a preparacao da alteracao, portanto valide possiveis erros no painel Debugger.
