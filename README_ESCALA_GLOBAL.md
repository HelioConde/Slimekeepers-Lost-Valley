# Escala global de objetos (Godot 4) — Slimekeepers: Lost Valley

Este sistema evita ajustar novamente centenas de sprites ao desenhar os mapas. **A tabela central é usada tanto pelo catálogo quanto pelos objetos do mundo**; não muda PNGs nem a escala do protagonista (0.40).

## Arquivos

- `scripts/world_object_scales.gd`: referência única de proporções e origem dos sprites.
- `scripts/world_object.gd` + `scenes/world_object.tscn`: prefab de objeto, com colisão opcional; atualiza a prévia no editor.
- `scripts/world_object_factory.gd`: criação por pasta/ID dos objetos exportados da PixelLab.
- `scripts/object_catalog_demo.gd`: vitrine com os mesmos tamanhos da biblioteca global.
- `scripts/forest_objects.gd`: mapa da floresta agora consulta a escala central para troncos, pedras, arbustos e outros objetos. Árvores já posicionadas conservam suas escalas de composição.

## Proporções recomendadas

| Categoria | Altura máxima relativa ao personagem |
|---|---:|
| Árvores em pé | Escala anterior aprovada — sem alteração |
| Tronco caído / toco | 37% / 43% |
| Cultivos / canteiros / solo preparado | 27% / 37% / 29% |
| Arbusto pequeno / grande | 46% / 58% |
| Gramas / flores / cogumelos | 40% / 40% / 34% |
| Pedra pequena / grande | 44% / 82% |
| Minérios / cristais | 57% / 65% |
| Baús e caixas / barris | 52% / 50% |
| Banco / cerca / ponte | 57% / 58% / 58% |
| Fornalha / poço | 84% / 84% |
| Ruínas de chão / estátuas / portais | 70% / 175% / 125% |
| Piso / parede / telhado modulares | Tamanho de célula 32×32 |

Os percentuais são tetos visuais aproximados: o código também considera a largura e a área não transparente. Uma árvore em pé continua com seu tamanho aprovado. Para terrenos e peças modulares, o encaixe da grade é prioritário.

## Criar um objeto no mundo

1. Adicione um nó `WorldObjects` (Node2D com `y_sort_enabled=true`) no mapa.
2. Instancie `scenes/world_object.tscn` como filho.
3. No Inspector, defina `asset_folder` com uma pasta do catálogo, por exemplo `rock_small_small_rounded_fie_...`. `solid` liga uma colisão perto dos pés.
4. Posicione no mapa. A escala vem de `world_object_scales.gd`.

Ou via script:

```gdscript
const Factory = preload("res://scripts/world_object_factory.gd")

func _ready() -> void:
    Factory.place($WorldObjects, "rock_small_small_rounded_fie_...", Vector2(200, 160), true)
```

O nome exato das pastas pode ser visto em `sprites/objects/pixellab_exports/`.

## Testar

- **F6** em `scenes/object_catalog_demo.tscn` para comparar as 552 imagens ao Player em 0.40.
- **F6** em `scenes/forest_meadow_demo.tscn` para comparar o ajuste nos objetos já posicionados.
- `scenes/main.tscn` permanece inalterada.

As imagens foram comparadas visualmente; a execução do Godot no seu computador é a validação final de aparência e colisão.
