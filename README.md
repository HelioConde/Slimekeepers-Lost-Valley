# Slimekeepers: Lost Valley — Grass + Dirt V3 (32×32)

Tileset funcional de grama/terra plana, criado com base na **paleta do PNG PixelLab** fornecido no projeto. Não é uma folha de penhascos: as transições são finas, com uma borda orgânica curta.

## O pacote
- `assets/tilesets/grass_dirt_v3_32x32.png`: atlas PNG de 256×128 pixels (8 colunas × 4 linhas), cada peça com 32×32 pixels.
- `resources/grass_dirt_v3.tres`: TileSet para Godot 4.3+, com 16 variantes de borda e terreno em modo **Match Corners**, mais 8 variantes de solo e 8 detalhes transparentes.
- `scripts/terrain_demo.gd`: demonstração determinística com `TileMapLayer.set_cell()`, baseada nas quatro condições de cada canto.
- `scenes/terrain_v3_demo.tscn`: cena de teste com o seu `scenes/player.tscn` existente.
- `previa_terreno_36x24.png`: composição real dos tiles (36×24 células), não imagem imaginada por IA.
- `guia_visual_tiles.png`: guia dos 32 tiles e suas posições no atlas.

## Instalação (sem sobrescrever seu trabalho)
1. Extraia este ZIP na raiz de `C:\Slimekeepers Lost Valley`, mesclando pastas, sem substituir cenas existentes.
2. Abra Godot 4.3 ou mais recente para importar o PNG.
3. Abra `scenes/terrain_v3_demo.tscn` e pressione **F6**. Essa cena usa seu Player existente.
4. Para usar no seu mapa principal, crie um `TileMapLayer` e selecione `res://resources/grass_dirt_v3.tres` em `Tile Set`.
5. No editor TileMap, teste **Terrains → Match Corners**; o atlas inclui metadados de cantos para grass e dirt. Como não foi possível executar Godot neste ambiente, confirme no editor o comportamento de pintura automática. Se a ferramenta Terrain não conectar como esperado, a cena de demonstração usa correspondência determinística dos quatro cantos, sem depender do painter.

## Disposição do atlas
- Linhas 0 e 1: máscaras dos 4 cantos (TL=1, TR=2, BL=4, BR=8), indexadas de 0 a 15. Canto = 1 para terra, 0 para grama.
- Linha 2, colunas 0–3: variações de grama; colunas 4–7: variações de terra.
- Linha 3: vegetação pequena e pedras em pixels transparentes. Utilize esses detalhes sobre uma segunda camada.
- Pincel visual sem barreiras; colisões de rochas, árvores e rios devem ser configuradas em camadas separadas.

## Compatibilidade e escala
O player mantém canvas de 128×128 e oito direções. Cada tile do mapa é 32×32. A renderização deve usar filtro **Nearest** (CanvasItem Texture Filter = Nearest). Desative filtragem linear para manter pixels nítidos.

## Limitações / próximos passos
- A beleza do terreno ainda precisa de avaliação visual com o player real. Este atlas é um protótipo editável, não um tileset comercial desenhado integralmente à mão.
- O preview já é uma composição de terreno com peças conectadas, mas não contém o player (a cena Godot o inclui).
- Não exportei `tile_map_data` fixo: a cena usa um script para povoar a camada na execução.
- Não foi possível validar o arquivo `.tres` abrindo o executável Godot neste ambiente.
