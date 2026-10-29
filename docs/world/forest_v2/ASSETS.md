# Inventário e origem dos recursos

Todos os PNGs originais foram reaproveitados sem pintura, redimensionamento destrutivo ou substituição. Escalas dos sprites foram mantidas em 1×/2× conforme a família já usada pelo projeto; personagem e zoom continuam com os valores anteriores.

| Categoria | Recurso existente | Aplicação |
|---|---|---|
| Solo | `assets/tilesets/grass_dirt_v3_32x32.png`, `assets/world/clearing_tileset.tres` | 40.000 células reais de 32×32, grama e trilhas |
| Árvores | `assets/menu/environment/oak.png`, `oak_medium.png` | Bosques, núcleo antigo, marco centenário |
| Pinheiro/jovem | `assets/world/forest/pine_crisp.png`, `oak_young.png` | Mata norte, copas de tamanhos variados |
| Vegetação baixa | `assets/menu/environment/grass.png`, `flowers.png`, `crops.png` | Grupos de flores brancas/amarelas/azuis/rosadas por modulação Godot |
| Samambaia/fungos | `assets/world/forest/fern.png`, `mushroom_red.png`, `mushroom_brown.png`, `mushroom_glow.png` | Bosque sombreado e bordas de trilha |
| Arbustos | `assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png` | Composição em grupos |
| Tronco | `assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png` | Tronco do Tempo e mata antiga |
| Pedra nítida | `assets/menu/environment/stone.png` | Círculo musgoso, encostas e rochas antigas |
| Relevo | `assets/world/valley/cliffs_low.{png,json,tres}`, `stone_steps.png` | Mirante com paredes bloqueadas e passagem pelas escadas |
| Água/vegetação | `assets/world/valley/reeds.png`, `lily_pad.png`, `waterfall_medium.png` | Passagem úmida e polimento do Vale |
| Slime verde | `assets/slimes/bestiary/brotinho/brotinho_frames.tres` | Idle, move, happy em oito indivíduos com IDs próprios |
| Jogador | `assets/player/rotations/`, `assets/player/animations/` | Controlador e animações originais intactos |

Novos elementos visuais são código nativo: borboletas, folhas, sombra de pássaro, peixes pequenos, plantas submersas, espuma e shaders. Não são imagens de mapa geradas nem letras por IA. O áudio é síntese própria descrita em `AUDIO.md`. Nenhuma geração paga adicional foi realizada.

A origem histórica dos assets PixelLab do Vale permanece documentada em `docs/world/vale/PIXELLAB_ASSETS.md`; esta etapa apenas os reutiliza.
