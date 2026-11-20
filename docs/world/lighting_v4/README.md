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
