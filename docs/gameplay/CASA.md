# Casa construída pelo jogador

Diferencial do Slimekeepers: a casa não é pré-pronta. O jogador desenha piso, paredes e
mobília célula a célula (32 px), entra nela e organiza como quiser. Segue o modelo de
construção em camadas já usado no projeto irmão `Slime-Harvest` (`docs/house_building.md`).

## Como jogar (na Fazenda)
- **[B]** abre/fecha o modo construir. **[Q]** troca a camada: Piso, Parede, Mobília.
- Clique esquerdo coloca, direito remove; a **roda do mouse** escolhe o móvel.
- Regras: parede só onde não há móvel; móvel só sobre piso, sem parede nem outro móvel;
  nada sólido na célula do jogador; piso com móvel em cima não pode ser removido.
- O **telhado** cobre a casa por fora e some quando o jogador entra (ou no modo construir).
- **[E] perto da cama** dorme até 06:00 (energia cheia, culturas crescem, jogo salvo).
- Começa com uma casa inicial 7×5 (cama, mesa, cadeira, baú, tapete, planta) e porta ao sul.

## Arte (PixelLab)
| Arquivo | Origem | Gerações |
|---|---|---|
| `assets/tilesets/house/floor.png/.json` | tileset padrão grama→piso de carvalho 32 px | 1 |
| `assets/tilesets/house/wall.png/.json` | tileset pro, face alta: reboco creme, vigas e base de pedra | 15 |
| `assets/tilesets/house/roof.png/.json` | tileset padrão grama→telha de barro | 1 |
| `assets/objects/furniture/*.png` | cama, mesa, cadeira, baú, tapete, planta, estante, fogão | 8 |

`tools/pixellab/convert_house_tilesets.py` remove a grama dos tilesets (fica transparente) e
gera o mapa de cantos (`NW,NE,SW,SE` → posição) usado pelo dual-grid de `house_builder.gd`.

## Código
- `scripts/systems/house_state.gd` — estado (piso, paredes, mobília), regras, casa inicial.
- `scripts/world/house_builder.gd` — desenho dual-grid, paredes por fileira (ordem por Y),
  face de parede sólida, telhado, mobília, colisão e modo construir.
- `tools/capture_house.gd` — capturas por fora, por dentro, construindo e ampliada.

## Pendências
- Custo em materiais (madeira/pedra) quando houver coleta de recursos.
- Porta e janela como peças próprias; mais móveis; girar móveis.
