# Clareira Encantada — primeira cena explorável

Cena de demonstração inspirada na arte-conceito da clareira inicial de **Slimekeepers: Lost Valley**. É uma **composição jogável aproximada** usando os assets existentes, não a imagem-conceito como fundo nem uma reprodução pixel a pixel.

## Como executar

Na raiz local do projeto:

```powershell
git pull origin main
```

Abra **`scenes/enchanted_clearing_demo.tscn`** no Godot e pressione **F6**. O `main.tscn` existente não foi alterado.

## Organização e composição

- **Ground (TileMapLayer)**: terreno 32×32, grama e caminhos naturais feitos com os tiles oficiais do projeto.
- **EnchantedClearingDemo**: desenha a lagoa, píer, canteiros e um pequeno desnível rochoso. Elementos de protótipo, sem sprites definitivos de água/penhasco.
- **WorldObjects**: árvores nas dimensões aprovadas, props PixelLab importados e ordenação por Y.
- **Player**: `player.tscn`, escala visual `0.40` preservada, colisões e animações.
- **HUD**: atalhos de navegação.

A cena contém uma horta cercada à esquerda, lagoa com píer no canto inferior esquerdo, estrada sinuosa central, desvio à direita, troncos, pedras, flores, rochas e árvores nas bordas. A maioria dos objetos usa `world_object_factory.gd` / `world_object_scales.gd`; as árvores legadas usam a mesma escala aprovada da floresta anterior.

A seleção das variantes depende das pastas da PixelLab que estiverem disponíveis sob `sprites/objects/pixellab_exports`. Os sprites antigos de árvores usam os arquivos de `sprites/objects`. As duas pastas já estão versionadas neste repositório.

## Teclas

- **WASD / setas:** mover
- **Shift:** correr
- **Espaço:** dash
- **Tab:** alternar zoom de passeio e visão geral
- **1:** início | **2:** horta | **3:** lagoa | **4:** saída leste

## Próximas etapas

A lagoa, píer, canteiros e paredão são desenhados de forma procedural para testar composição e navegação; podem futuramente ser substituídos por tiles de água, margem, pedras e estruturas de um tileset final. O terreno nasce em tempo de execução ao pressionar F6. A cena ainda não foi validada executando o Godot neste ambiente.
