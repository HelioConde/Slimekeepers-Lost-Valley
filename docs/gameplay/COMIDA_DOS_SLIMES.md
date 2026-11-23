# Comida dos slimes e Boss Slimes — decisões do usuário (2026-11-22)

> Fonte: pedido do usuário em 2026-11-22. Complementa a Bíblia (`docs/narrativa/BIBLIA_NARRATIVA.md`,
> §4 e §5). O que segue **A DEFINIR** continua aberto e não deve ser inventado.

## A comida é a mecânica principal

- Com comida o jogador **conquista slimes** para ajudar e **resolve os Boss Slimes**.
- A Bíblia (§5) já diz que um Boss pode ser superado por **combate** ou por **alimentação**.
  As duas rotas contam igualmente para o requisito do Reino Élfico.

## Grupos de comida

Cada comida pertence a um grupo:

| Grupo | Itens que já existem | Itens futuros |
|---|---|---|
| Vegetal | folhas frescas, cenoura, beterraba, repolho, porção de folhas, cenoura assada, sopa de legumes | — |
| Fruta | — | A DEFINIR (frutas silvestres, árvores frutíferas) |
| Marinha | — | A DEFINIR (pesca, algas, conchas) |

## Preferência por habitat

O slime gosta mais da comida que combina com o lugar onde vive:

| Espécie | Habitat | Comida preferida |
|---|---|---|
| Brotinho | Floresta | Vegetal |
| Musguinho | Floresta (sombra, musgo) | Vegetal |
| Bolhinha | Perto da água | Marinha |
| Slimes de pomar/campos | A DEFINIR | Fruta |
| Gelito, Brasinha | A DEFINIR | A DEFINIR |

Regra de jogo implementada (`scripts/systems/slime_feeding.gd`, `LIKES` e `gain`):

- Comida do grupo preferido dá **o dobro** de pontos de laço.
- As outras comidas dão os pontos normais.
- Pratos cozidos continuam valendo mais que a colheita crua.

## Boss Slimes: batalha de time e habilidade

Direção do usuário para a rota de combate:

- É uma **batalha de time**: o jogador luta junto com os slimes que conquistou.
- Cada participante usa **habilidades**.
- **Zona vermelha**: antes de um golpe muito forte do Boss, aparece no chão a área de
  impacto em vermelho. O jogador (e o time) tem um tempo curto para sair dela.
- A rota de alimentação continua existindo (Bíblia §5).

A DEFINIR (não inventar):

- Quantos Bosses existem e onde ficam.
- Habilidades de cada espécie de slime (a Bíblia marca as habilidades como EM ABERTO).
- Padrões de ataque de cada Boss, vida, dano e recompensas.
- Que comida e quantos preparos resolvem cada Boss pela rota pacífica.
- Como cada rota entrega os orbes de energia (Bíblia §8).
