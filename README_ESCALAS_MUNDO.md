# Escalas globais PixelLab

As cenas de catalogo e os futuros mapas usam uma unica tabela: scripts/world_object_scales.gd.

## Usar no editor
1. Coloque scenes/world_object.tscn dentro de um Node2D WorldObjects com Y Sort Enabled.
2. Na instancia, escolha Asset Folder: uma pasta res://sprites/objects/pixellab_exports/NOME_DO_OBJETO.
3. Ajuste a posicao. Solid permite colisao nos pes. Variation=1.0 usa a escala aprovada.

## Usar por codigo
const ObjectFactory = preload("res://scripts/world_object_factory.gd")
# Dentro de _ready:
# ObjectFactory.place($WorldObjects, "NOME_EXATO_DA_PASTA", Vector2(100, 180), true)

## Escalas de referencia (percentual de altura do Player visual=0.40)
- Arvores em pe: tamanho do catalogo anterior preservado
- Troncos/tocos: 37%/43%; gramas/flores: 40%; cogumelos: 34%
- Arbustos pequenos/grandes: 46%/58%; cultivo/canteiro/terra: 27%/37%/29%
- Pedra pequena/grande: 44%/81%; minerios: 57%
- Caixas/baus/barris: 52%/53%/50%; bancos/cercas/pontes: 56%/58%/58%
- Furnaces/pocos: 84%; fogueira: 42%; cristais: 65%
- Ruinas/estatuas/portais: 70%/175%/125%
- Piso/parede/telhado modular: grade 32x32px, sem deformacao.

O percentual representa limite de altura visivel; o limite de largura tambem pode reduzir a escala.
O Player usa referencia aproximada de 42px com visual_scale=0.40.
Deixe Preview Only Non Tree Scale=1.0 no catalogo para manter equivalencia com o mundo.
A cena de floresta antiga foi preservada para evitar alterar o mapa de testes.
