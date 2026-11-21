# V11 — Água encantada (2026-11-21)

Referência: `referencias_v11/ref_ponte_noite.webp`. Capturas: `39_` (água viva), `40_` (protótipo A/B/C/D), `41_` (sequência animada), `42_` (final × referência).

## Camadas
- **Água base** (`valley_water.gdshader`, noite): campo de correnteza arrastado rio abaixo e torcido por ruído; faixas de profundidade turquesa → azul-marinho; ondulações horizontais curvas por linha; vegetação submersa no raso; espuma e ondinhas na borda.
- **Camada encantada** (`water_magic.gdshader` + `water_magic.gd`, aditiva, uma por corpo d'água, instalada por WaterReflections):
  1. Fios luminosos em duas escalas (correntes amplas e reflexos rápidos), curvas de nível de ruído no referencial do fluxo; segmentos acendem e apagam. Direção de fluxo por superfície (rio para baixo, lago lateral).
  2. Bordas molhadas: máscara de distância à margem calculada da geometria real (scanline + transformada chanfrada, grade de 4 px); faixa colada à margem com ondinhas e trechos fortes/fracos (sem neon contínuo).
  3. Cintilações: células de 22 px com semente fixa; vida própria (sobe, pico, some); ~30% com 4 pontas; mais densas perto das fontes de luz.
  4. Reflexos das fontes: plantas mágicas (juncos ciano, flores lilás), plantas do lago e slimes luminosos (grupo `water_light_sources`), atualizados a cada 0,2 s; os slimes refletem conforme se movem.
- **Vegetação** (`river_flora.gd`): juncos luminosos na beira e vitórias-régias na água rasa ao longo dos rios.
- **Reflexo da Lua**: o sistema V10 (único), coluna mais larga e longa.

## Testes
- Mundo: `tools/test_reflection_world.gd -- 21 magic` → concordância 0,925 em 6 enquadramentos (4 posições + zoom 0,64/0,8/1,0); reflexo lunar 0,993.
- Animação: diferença média entre quadros a 0,25 s ≈ 5 níveis (água viva com o jogador parado).
- gdUnit 242/0; FOREST_V2, VALLEY (3), DAY_NIGHT, MENU ok.
- Desempenho: camada encantada custa ~0,3–1 ms; Vale 150–180 FPS.

## Diferenças que permanecem
Margens da referência têm barranco de terra escura e pedras molhadas; névoa sobre a água mais densa; coluna de luar mais larga à direita da ponte; mais vitórias-régias. Ponte da referência sem plantas-lanterna.
