# Iluminação V4 — evidências (branch feat/visual-ambient-lights)

Capturas reais em janela 1280×720, GL Compatibility (Radeon RX 580), geradas com
`tools/capture_lighting.gd` (o Godot MCP estava desconectado nesta sessão):

```
godot --path . --rendering-driver opengl3 --script res://tools/capture_lighting.gd -- \
  --scene=FlorestaDoDespertarV2 --out=<pasta> --tag=final --fps --walk
```

| Arquivo | O que mostra |
|---|---|
| `01_manchas_0900_antes_depois.png` | 09h: manchas `PointLight2D` (bokeh) × sprites aditivos em pixel art |
| `01_manchas_zoom_antes_depois.png` | Zoom 2×: borda borrada × aberturas entre folhas nítidas, alongadas na direção do sol |
| `02_sombras_1200_antes_depois.png` | 12h com e sem as sombras de contato por silhueta |
| `02_sombras_contato_zoom.png` | Zoom: 09h V3 × 07h V4 (cima) e 12h V3 × 12h V4 (baixo) — pedras, cogumelos, arbustos e tronco com contato |
| `03_vagalumes_brilhos_2200_zoom.png` | 22h: vagalumes uniformes × enxames em arbustos/flores, brilho raro em flor especial |
| `04_clareira_antes_09_12_1830_22.png` / `04_clareira_09_12_1830_22.png` | Clareira do Despertar (área inicial da Floresta V2) às 09h, 12h, 18h30 e 22h, antes e depois |
| `04_caminhada_0900.png` | Jogador andando 6×24 px às 09h: câmera estável, manchas e sombras presas ao mundo |
| `05_vale_antes_09_12_1830_22.png` / `05_vale_09_12_1830_22.png` | Vale das Nascentes nos mesmos horários, com densidade própria de manchas |

## O que mudou

1. **Manchas de sol** (`scripts/world/ambient_lights.gd`): sprites `Sprite2D` aditivos,
   `TEXTURE_FILTER_NEAREST`, z −1 e `top_level` (mesmo plano do `DayShadows`), escala 2
   (1 pixel da textura = 2 px do mundo). 6–9 furos por mancha em 2 faixas de alfa,
   alongados nos pixels conforme `DayShadows.profile_at()` (o sprite não gira). Presas a
   células de 200 px (`dapple_homes`) numa janela 7×5 que cobre a tela inteira, então nada
   surge/some dentro da vista ao andar. Balanço de 1–2 px na grade, poeira dourada mantida,
   luz fraca (`DappleLight`) no jogador ao atravessar uma mancha. Densidade por região:
   Floresta 0,85, Vale 0,55. Textura gerada em 0,27 ms e cacheada por direção do sol.
2. **Sombras** (`scripts/world/day_shadows.gd`): `tools/diag_shadows.gd` lista quem gera
   cada sombra (5 007 na Floresta: 3 809 árvores, 1 392 objetos, jogador, slimes, fauna).
   Âncoras corretas em todos, exceto 6 flores/samambaias da `HabitatFlora` com 9 px de
   padding transparente — a sombra nascia abaixo da planta; `foot_for()` agora usa a base
   visível. Novas sombras de contato: faixa da base da própria silhueta (tronco, pedra,
   pés), mais escura, curta ao meio-dia e longa ao amanhecer/anoitecer
   (`contact_profile`); os blobs elípticos `ContactShadow` do mapa ficam ocultos em
   runtime e voltam ao sair da cena. Flores, samambaias e juncos não recebem contato.
3. **Atmosfera**: até 6 enxames de vagalumes nos pontos mais próximos — margens d'água
   (juncos, vitórias-régias, `water_sources`) antes de vegetação (arbustos, samambaias) —
   e só 1/3 dos vagalumes soltos. Até 5 brilhos mágicos cintilam de vez em quando sobre
   flores/cogumelos especiais (~1 em 11, escolhidos por hash da posição).

## Desempenho (média de 300 quadros, vsync desligado)

| Cena / hora | V3 (antes) | V4 (depois) |
|---|---|---|
| Floresta 09h | 184 FPS · 556 draw calls | 179 FPS · 539 |
| Floresta 12h | 198 FPS · 556 | 193 FPS · 530 |
| Floresta 18h30 | 200 FPS · 557 | 194 FPS · 546 |
| Floresta 22h | 202 FPS · 547 | 201 FPS · 497 |
| Vale 09h | 362 FPS · 410 | 350 FPS · 424 |
| Vale 12h | 473 FPS · 410 | 454 FPS · 423 |
| Vale 18h30 | 452 FPS · 418 | 423 FPS · 432 |
| Vale 22h | 472 FPS · 402 | 469 FPS · 403 |

Custo de ~0,1–0,3 ms por quadro (dentro do ruído entre execuções); muito abaixo de 16,6 ms.

## Pendências

- Oclusão seletiva (`LightOccluder2D`) não foi feita.
- Halo da fogueira do Vale às 18h30 ainda é um disco laranja grande (sistema V3, fora deste passo).

## Auditoria V4.1 (fogueira, sombras do jogador, manchas orgânicas, atmosfera, HUD)

"Antes" = V3 (`42527a4`, worktree temporário); "depois" = esta branch. Mesmo enquadramento
(spawn de cada região e câmera no jogador) via `tools/capture_lighting.gd`. O Godot MCP da sessão
não pôde controlar o editor (porta 6505 com outra sessão; ver correção do servidor abaixo).

| Arquivo | O que mostra |
|---|---|
| `06_fogueira_*`, `14_fogueira_v3_x_v4_1830_2200.png` | Anéis concêntricos (gradiente em faixas, raio ~130 px) × luz suave de 92 px que só domina após o pôr do sol; estação fora da copa do pinheiro |
| `07_sombra_jogador_quadros_0700/1630.png` | 8 direções × caminhada/corrida: sombra presa aos pés em todos os quadros |
| `08_manchas_organicas_0700_zoom.png` | 12 recortes com bordas irregulares e folhas cortando a luz |
| `09_atmosfera_noite_vale.png` | Noite: brasas, fogueira local, vagalumes e esporos |
| `10_hud_jogador_sob_painel_antes_depois.png` | Jogador escondido pelos painéis × HUD compacto translúcido sobre o jogador |
| `11_clareira_v3_x_v4_*.png`, `12_vale_v3_x_v4_*.png` | 07h, 12h, 16h30, 18h30, 22h — V3 à esquerda, V4 à direita |
| `13_clareira_camadas_*.png` | 07h e 16h30: completo, sem luzes locais, sem sombras, sem tom ambiente |

Causas encontradas:
- **Anéis da fogueira**: `banded_light_texture` (interpolação constante) ampliada 2×. Agora `campfire_light_texture()` cúbica, raio 92 px, `smoothstep(0.55, 1.0, noite)`.
- **Caminho laranja no Vale às 18h30**: tom ambiente do pôr do sol (`GameClock.LIGHTING_STOPS`) sobre a terra bege; a fogueira só soma no entorno (camadas comparadas). Mantido: decisão V3.
- **Estação × pinheiro**: ordem por Y correta; a copa de `TreesBack/Tree_0210` (base 1534,634) cobria a estação em (1515,460) e o jogador ao interagir. Estação em (1440,418).
- **Sombra do jogador pulando**: base por quadro varia até 11 px na corrida → `ground_bottom()` por animação.
- **Manchas repetidas**: 3 variantes por índice → 12 por hash da posição, com folhas recortando.
- **HUD**: faixa da bolsa de 742 px + guia de 398 px ocupavam o topo até y=168/540 → painéis encolhem ao texto (topo esquerdo até y≈65) e ficam com alfa 0,28 sobre o jogador.
- **Água**: reflexos já existiam (`water_reflections`), não duplicados.
- **Limitações**: não há slime "de luz" nas regiões atuais (Brasinha/Gelito só em `world.tscn`, obsoleto); a luz de slime em movimento é coberta por teste gdUnit. `LightOccluder2D` seletivo não foi feito.

### Desempenho V3 × V4.1 (300 quadros, vsync off, RX 580)

| Hora | Floresta V3 | Floresta V4.1 | Vale V3 | Vale V4.1 |
|---|---|---|---|---|
| 07h | 176 FPS / 556 dc | 169 / 526 | 371 / 488 | 366 / 417 |
| 12h | 195 / 555 | 186 / 517 | 459 / 487 | 428 / 416 |
| 16h30 | 196 / 556 | 194 / 517 | 445 / 489 | 436 / 416 |
| 18h30 | 190 / 557 | 190 / 534 | 464 / 490 | 400 / 439 |
| 22h | 190 / 548 | 198 / 497 | 470 / 492 | 415 / 406 |

Custo ≤ 0,35 ms/quadro (pior caso Vale 18h30: 2,16 → 2,50 ms); draw calls caem em todas as cenas.

### Testes
gdUnit `tests/addons` + `tests/forest`: 137/137. `tools/`: DAY_NIGHT 80/0, DAY_SHADOWS 26/0, SHADOW_RENDER PASS,
PLAYER_SHADOW_FRAMES 336/0, MAP_DEPTH 105/0 (precisa de janela), VISUAL_RULES 5526/0, VALLEY 41/0,
VALLEY_GARDEN 88/0, FORAGING 23/0, REGION_TRAVEL 9/0, ENVIRONMENT_V3 23/0, ENVIRONMENT_REGIONS 8/0,
LIVING_REGIONS 61/0, WATER_REFLECTIONS 30/0, HABITATS 37/0. `test_forest_v2` falha antes desta
branch: carrega `scenes/world.tscn`, que depende da `ClareiraDoDespertar.tscn` removida.
