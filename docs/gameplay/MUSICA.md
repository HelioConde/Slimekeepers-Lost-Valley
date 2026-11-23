# Música (2026-11-23)

Opção recomendada: música gerada no PixelLab (`create_music`), com aprovação do usuário antes de entrar no jogo.

## Estado

| Parte | Estado |
|---|---|
| Tocador `scripts/world/region_music.gd` | Feito. Toca a introdução uma vez, depois repete o trecho do loop sem emenda. Usa o volume e o "silenciar" das opções de áudio, × 0,45, para ficar abaixo do ambiente, e entra com fade de 4 s. Sem o arquivo da faixa, fica em silêncio. Entra nas regiões vivas (`living_region.gd`). Teste: `tests/forest/test_region_music.gd` |
| Faixa "Floresta — dia" | Aguardando o usuário escolher a versão 1 ou a 2. As prévias ficam em `docs/gameplay/audio_previa/`, fora do Git, com `.gdignore` para o Godot não importar |

## Pontos de loop (versões em loop do PixelLab, `make_music_loop`)

| Versão | Duração | Loop (volta de → para) |
|---|---|---|
| 1 | 224,0 s | 167,221 s → 63,181 s |
| 2 | 218,6 s | 157,173 s → 58,491 s |

Para instalar a escolhida:
1. Copiar `floresta_dia_takeN_loop.mp3` para `assets/audio/music/floresta_dia.mp3`.
2. Preencher `loop_start` e `loop_end` em `region_music.TRACKS`.
3. Rodar `--import`.

## Pendências

- Por enquanto, uma faixa só para todas as regiões vivas.
- Ainda não há variação de dia e noite nem por estação.
