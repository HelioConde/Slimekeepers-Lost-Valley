# Casa construída pelo jogador

Diferencial do Slimekeepers: **não há casa inicial**. O jogador constrói a casa com os
recursos que coletou, do tamanho que quiser, em qualquer lugar livre do mapa (Floresta
do Despertar ou Vale das Nascentes). Só pode existir **uma casa** no jogo. Pedido do
usuário (2026-11-22).

## Como jogar
- **[B]** abre/fecha o modo construir em qualquer lugar; **[Q]** troca entre **Casa** e **Mobília**.
- **Casa:** segure o botão esquerdo numa ponta e solte na outra para marcar o retângulo.
  - A prévia fica verde (pode) ou vermelha (não pode) e o aviso mostra o tamanho e o custo.
  - Tamanho externo (com paredes): mínimo 4×4, máximo 16×12.
  - O jogo cria piso, paredes em volta e a porta no meio da parede de baixo.
  - Não dá para construir sobre árvore, pedra ou água, nem com o jogador dentro da área.
  - **Clique direito na casa demole** e devolve todo o material (inclusive dos móveis); aí dá para construir em outro lugar.
- **Mobília:** a roda do mouse escolhe o móvel, o clique esquerdo coloca (só dentro da casa) e o direito tira (devolve o material).
- O **telhado** cobre a casa por fora e some quando o jogador entra (ou no modo construir).
- **[E] perto da cama** dorme até 06:00 (energia cheia, dia seguinte, jogo salvo). Sem cama, não dá para dormir.
- Ao construir, mato, flores e itens coletáveis da área somem; voltam se a casa for demolida.

## Custos (`scripts/systems/house_state.gd`)
| Peça | Custo |
|---|---|
| Piso (por célula, inclui a porta) | 1 madeira |
| Parede (por célula) | 2 madeiras + 1 pedra pequena |
| Cama | 4 madeiras + 6 fibras |
| Mesa | 3 madeiras |
| Cadeira | 2 madeiras |
| Baú | 4 madeiras + 1 corda |
| Tapete | 8 fibras |
| Planta | 2 fibras |
| Estante | 4 madeiras |
| Fogão | 6 pedras pequenas + 2 madeiras |

Exemplos:
- casa 4×4: 11 paredes + 5 pisos = 27 madeiras + 11 pedras;
- casa 7×5: 19 paredes + 16 pisos = 54 madeiras + 19 pedras.

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
- `scripts/systems/house_state.gd`: casa única (região, retângulo, piso, paredes, mobília), custos, construir por retângulo, demolir, mobília paga.
- `scripts/world/house_builder.gd`: desenho dual-grid, paredes por fileira (ordem por Y), face de parede sólida, telhado, mobília, colisão, modo construir com arraste.
- `scripts/world/clearing_region.gd`:
  - `add_player_house()` cria o construtor da região (Floresta: `floresta`, Vale: `vale`) e checa o chão livre pela colisão;
  - `handle_player_house()` cuida do HUD e de dormir;
  - `sleep_until_morning()` dorme;
  - `_clear_under_house()` limpa a área da casa.
- Testes: `tests/forest/test_house_state.gd` e `tools/capture_house.gd` (na Floresta: arrastar, custo, construir, mobiliar, uma só casa, dormir).

## Pendências
- Porta e janela como peças próprias; mais móveis; girar móveis.
- A Fazenda (`Fazenda.tscn`, acessível pelo portão do Vale) é um esboço antigo; a casa dela usa a mesma regra (região `fazenda`).
