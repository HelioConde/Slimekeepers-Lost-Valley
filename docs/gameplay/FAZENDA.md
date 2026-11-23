# Plantio livre (arar, plantar, regar, colher)

Não há campo nem canteiros prontos (pedido do usuário, 2026-11-22: "essas fazendas não
existem"). O jogador ara a grama com a **enxada** em **qualquer chão livre** da Floresta do
Despertar ou do Vale das Nascentes e cultiva ali. O campo de teste 6×4, os dois canteiros de
madeira, a fogueira de cozinhar e o portão da Fazenda foram removidos do Vale.

## Como jogar
- Selecione o item na barra, olhe para a célula à frente e aperte **[E]**. A ação depende do
  item e da célula: **colher** (pronta) › **arar** (enxada na grama) › **regar** (regador na
  terra seca) › **plantar** (semente na terra arada vazia).
- Grama sem enxada/regador/semente não toma o [E]: mato, gravetos e árvores continuam normais.
- Não se ara sobre árvore, pedra, água, arbusto nem dentro da casa. Ao arar, mato, flores,
  cogumelos e pedrinhas da célula somem.
- **Regador:** leva água para **20 regas**; cada rega gasta 1. Com o regador na mão, olhe para o lago ou o riacho e aperte **[E]** para encher. Vazio, ele avisa e não rega.
- **[R]** troca a semente (pula as que acabaram).
- A cultura sobe **um estágio por dia em que foi regada**; toda a terra seca na virada do dia.
- Terra arada **vazia e sem rega por 3 dias** volta a ser grama.
- **Sementes silvestres** (recolhidas com o Brotinho) viram **folhas silvestres** → colheita de
  **folhas frescas** → cozinhar no **fogão da casa** → porção para alimentar os slimes.
- Plantar e colher marcam os mesmos marcos de sessão dos antigos canteiros.

## Arte
| Arquivo | Origem | Gerações |
|---|---|---|
| `assets/tilesets/farm/soil_dry.png/.json` | PixelLab tileset pro 32 px: terra arada seca ↔ grama | 15 |
| `assets/tilesets/farm/soil_wet.png/.json` | PixelLab tileset pro 32 px: terra arada molhada ↔ a mesma grama (encadeada) | 15 |

- Duas tentativas no modo padrão (1 geração cada) foram descartadas: a terra seca parecia tábuas e a molhada tinha gravetos.
- `tools/pixellab/convert_soil_tilesets.py` deixa a grama transparente e grava o mapa de cantos.
- O jogo desenha em dual-grid (como a casa): a terra molhada vai por cima da seca, e a borda irregular se mistura à grama do mapa.
- Culturas: sprites PixelLab já exportados (`crop_catalog.gd`).

## Código
| Arquivo | Papel |
|---|---|
| `scripts/systems/crop_catalog.gd` | Culturas: estágios, semente, colheita |
| `scripts/systems/farm_state.gd` | Estado da sessão por região (`floresta`, `vale`): arar, plantar, regar, crescer, colher |
| `scripts/world/farm_field.gd` | `free_area`: célula arável por `farmable` (sem colisão nem casa, sem arbusto); terra em dual-grid; [E]/[R] |
| `scripts/world/clearing_region.gd` | `add_free_farm()`, `handle_farming()`, `hide_forage_on_farm()` |
| `tools/test_free_farm.gd` | Arar, plantar, regar, colher na Floresta e no Vale; árvore não é arável |
| `tools/test_valley_garden.gd` | Ciclo completo Brotinho → sementes → arar no Vale → colher → cozinhar → alimentar → Novo Jogo |
| `tools/capture_farm_field.gd` | Captura de um pedaço arado com terra seca, molhada e plantas |

## Slimes ajudantes (2026-11-23)

Slimes que já são amigos (Floresta ou Vale) ajudam na fazenda da Floresta, das 6h às 19h,
com até 4 tarefas por espécie por dia (`scripts/world/farm_helpers.gd`):

- **Brotinho** planta sementes da bolsa na terra arada vazia (animação `plantar`).
- **Bolhinha** rega culturas com sede (animação `regar`).
- **Musguinho** aduba: a cultura adubada e regada cresce 2 estágios na virada do dia
  (`FARM.fertilize`; animação `adubar`, provisoriamente o "feliz").

Teste: `tests/forest/test_farm_helpers.gd`; prova no jogo: `tools/capture_farm_helpers.gd`.
