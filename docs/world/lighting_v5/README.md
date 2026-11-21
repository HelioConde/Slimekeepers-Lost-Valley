# Iluminação V5 — sombras com dono e cachoeiras vivas

Branch `feat/visual-ambient-lights`. Capturas reais em janela 1280×720, GL Compatibility,
via `tools/capture_lighting.gd` (mesma posição do jogador e mesma câmera; `--layers` liga e
desliga camadas; `--anim=N` grava sequências para provar movimento). O Godot MCP desta sessão
não controla o editor enquanto outra sessão ocupa a porta 6505.

## 1. Diagnóstico das sombras (`tools/diag_shadows.gd`)

| Categoria | Floresta/Clareira | Vale |
|---|---|---|
| Corretas (projetam da base, direção do sol) | 5 213 objetos | 1 489 objetos |
| Deslocadas (> 8 px da base) | 0 | 0 |
| Sem dono | manchas `moss` do chão (até −14%, ~86 px) | 71 blobs sob vitórias-régias boiando; 6 blobs nas pedras da borda das cachoeiras; ruído do chão (−12%) |
| Faltando | — | fogueira da estação; 6 pedras da borda das cachoeiras |
| Fortes/longas demais | faixas diagonais onde copas vizinhas se sobrepunham (opacidade somada); copas de 140 px cobrindo a clareira | idem |
| Fracas/ausentes | noite ~0,1 (luar) — mantido | idem |

Isolamento por renderização: só a categoria "árvore" gerava as faixas à esquerda do jogador;
com o `DayShadows` desligado ainda restavam manchas escuras — vinham dos shaders de chão.

## 2. Correções

| Commit | O quê |
|---|---|
| `aa97b59` | Sombras projetadas desenhadas opacas num `CanvasGroup` (opacidade aplicada uma vez: sem faixas de sobreposição); projeção máxima 140 → 110 px. `tools/test_shadow_overlap.gd` falha no código anterior e passa agora. |
| `a34b51c` | Sombras estáticas ordenadas por textura: 638 → 479 draw calls (o grupo tinha quebrado os lotes). |
| `4f73792` | Pedras da borda das cachoeiras e a fogueira projetam sombra + contato; blobs sob objetos que boiam ocultos em runtime; variação do gramado mantém o tom sem manchas escuras. |
| `4512003` | Cachoeiras (abaixo). |

**Removido** (em runtime, reversível ao sair da cena; nenhum arquivo de mapa alterado): 71 blobs
sob vitórias-régias, 6 blobs elípticos das pedras da borda (trocados pela sombra própria).
**Sombra nova**: fogueira da estação de culinária, 6 pedras da borda das cachoeiras.
**Mantidos com dono**: sombras das 5 pontes (estáticas, fonte clara) e blobs sob tufos de grama.

Camadas: contato (faixa da base da silhueta) → projetada (silhueta, `CanvasGroup`) → luz
filtrada pelas folhas (manchas nas copas, `8c5a366`) → tom ambiente (`CanvasModulate`).

## 3. Cachoeiras

- `valley_cascade.gdshader`: colunas de 3 px com velocidade/fase próprias e aceleração na
  queda; fios escuros lentos; gotas cintilantes na cor refletida do horário (dourado de manhã,
  âmbar ao entardecer, azulado à noite); bordas laterais mais claras; crista brilhante; espuma
  da base em bolsões que trocam de lugar.
- `waterfall_life.gd`: névoa (14 partículas) e respingos (14) no impacto, cintilação
  azul-esverdeada sobre o lago só à noite; respeita "reduzir movimento".
- `03_cachoeira_antes.gif` / `03_cachoeira_depois.gif`: 12 quadros com o relógio parado — só a
  água se move.

## 4. Evidências

| Arquivo | Conteúdo |
|---|---|
| `01_sombras_sem_acumulo_0700_1830.png`, `01_teste_sobreposicao_antes_depois.png` | Faixas diagonais × sombra uniforme |
| `02_chao_sem_manchas_sem_dono_antes_depois.png` | Chão sem `DayShadows`: manchas escuras × variação de tom |
| `03_cachoeira_*` | 07h/12h/16h30/18h30/22h e GIFs |
| `04_*` | Comparação final antes × depois (ver abaixo) |
| `04_clareira_antes_depois_07_12_1630_1830_22.png` | Clareira, mesmo enquadramento (esquerda antes = `8c5a366`, direita depois) |
| `04_vale_cachoeira1_*`, `04_vale_cachoeira3_*` | Duas cachoeiras do Vale nos 5 horários |
| `04_vale_cachoeira3_camadas_1630.png` | Completo / sem luzes / sem sombras / sem tom ambiente (antes em cima) |
| `04_fogueira_antes_depois_1830_2200.png` | Fogueira com sombra própria e contato |

## 5. Desempenho (300 quadros, vsync off, RX 580; máquina com editor e outra sessão abertos)

| Cena | Antes (`8c5a366`) | Depois |
|---|---|---|
| Floresta 07h–22h | 5,9–6,5 ms · 585–648 draw calls | 5,1–6,2 ms · 427–488 |
| Vale (cachoeira) 07h–22h | 3,4–4,1 ms · 416–440 | 2,9–3,6 ms · 266–292 |

As partículas novas da cachoeira (≈ 38 por queda) não aparecem na média; o ganho vem dos lotes
por textura. Um quadro isolado de 60–90 ms aparece em quase toda medição (também antes), não é
recorrente.

## 6. Testes

gdUnit `tests/core` + `tests/addons` + `tests/forest`: **165/165** (novos: `test_shadow_ownership`,
`test_waterfall_life`). `tools/` sem janela: FOREST_V2 158/0, HABITATS 37/0, FOREST_LIFE 16/0,
FOREST_AUDIO 22/0, VALLEY 41/0, VALLEY_WATER 20/0, REGION_TRAVEL 9/0, SLIME_ECOSYSTEM 36/0,
ENVIRONMENT_V3 23/0, ENVIRONMENT_REGIONS 8/0, LIVING_REGIONS 61/0, VISUAL_RULES 5526/0,
CURATED_EXPORTS 4550/0, MAP_COMPOSITION 9/0, POND_BANKS 9/0, DAY_NIGHT 80/0, WATER_REFLECTIONS 30/0,
DAY_SHADOWS 26/0, FORAGING 23/0, VALLEY_GARDEN 88/0, SWIMMING 32/0, MENU 62/0. Com janela:
SHADOW_RENDER PASS, SHADOW_OVERLAP PASS, PLAYER_SHADOW_FRAMES 336/0, MAP_DEPTH 105/0,
NATIVE_DEPTH 8/0, NATIVE_BRIDGES e CONTACT_DISTANCE exit 0. Nenhuma falha antiga restante.

## 7. Pendências

- Sombras das 5 pontes e as paredes `cliffs_tall` continuam estáticas (não seguem o horário).
- Blobs sob tufos de grama (169 no Vale) mantidos: têm dono, mas não projetam sombra direcional.
- Slimes luminosos (Brasinha/Gelito) nas regiões atuais e `LightOccluder2D` seletivo: não feitos.
- Pedras dentro do rio (`river_stones`, 6) sem sombra/contato na água.

## 8. Sombra fora do lugar (relato com captura `05_relato_sombra_fora_do_local.jpg`)

Investigação com `tools/debug_shadow_owners.gd` (sombra projetada em vermelho, contato em
laranja, pé de cada objeto em ciano, `--probe`, `--only`, `--hide`, `--outline`):
- A faixa circulada vinha só das árvores (`--only=VegetationHigh`), mas nenhum quad calculado
  cobria aquele ponto. Isolando uma árvore espelhada: **retângulo de largura negativa no GL
  Compatibility não espelha — desloca o desenho uma largura inteira** (192 px numa árvore).
  Toda árvore com `flip_h` (e o contato dela) projetava a sombra no meio da clareira.
  Correção: espelhamento por transform (`DayShadows.mirror_for`). `tools/test_shadow_flip.gd`
  falhava (normal 422–598 × espelhada 610–788) e passa (418–596).
- Altura real por tipo (`height_factor`): na arte 3/4, parte do sprite é a face de cima, não
  altura. Personagens 1,0; árvores 0,42 (máx. 70 px); pedras/tocos/troncos 0,35;
  arbustos 0,45; flores/cogumelos 0,55.
- Objetos desenhados por código sem sombra: canteiros do Vale e brotos de sementes da
  Floresta entram no grupo `shadow_boxes` e ganham sombra projetada + contato.

`05_donos_das_sombras_depuracao_antes_depois_1630.png`: depuração antes × depois (Clareira e
Vale). `05_clareira_sem_sombra_solta_0700_1630.png`: captura normal antes × depois.
