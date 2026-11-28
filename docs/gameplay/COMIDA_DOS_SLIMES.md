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

## Preferência por ingrediente (playtest ID 59, 2026-11-27)

Brotinho, Musguinho e Bolhinha têm gosto próprio por ingrediente (`PREFS` em
`slime_feeding.gd`). Isso substitui, para essas três espécies, o dobro por grupo; o grupo
de habitat continua só como dica no painel do slime ("gosta de vegetais"). As outras
espécies (Colhita, Carreguim, Construlim) seguem a regra de `LIKES`.

| Nível | Pontos de laço |
|---|---|
| Amado | ×2 |
| Gostado | ×1,5 |
| Neutro (o resto) | ×1 |

| Espécie | Amado | Gostado |
|---|---|---|
| Brotinho | cenoura | folhas frescas, beterraba |
| Musguinho | folhas frescas | repolho |
| Bolhinha | repolho | beterraba |

- **Pratos** herdam a média dos ingredientes da receita (`data/crafting/recipes.gd`):
  amado = 2, gostado = 1, neutro = 0; média ≥ 1,5 é amado, ≥ 0,5 é gostado. Assim, cenoura
  assada é amada pelo Brotinho e a sopa de legumes fica "gostado" para ele.
- **Descoberta**: o disco não revela nada antes de provar. Comida ainda não oferecida
  àquela espécie aparece como "(nova)"; depois de comer, mostra "★ favorita" ou "(gosta)".
  O registro fica em `slime_food_known` (por espécie, salvo com a sessão).
- Ao comer, a mensagem diz a reação: "amou! É o favorito", "gostou" ou "aceitou, sem
  muita vontade".
- A Bíblia não define preferências por espécie (só que "comidas específicas podem ser
  relevantes"). Esta tabela é **provisória**, escolhida como a opção mais simples para o
  playtest; os valores e as escolhas ainda precisam de balanceamento.
- Não há reação "não gostou" (rejeição): o pedido pediu três níveis; um nível negativo
  fica para decidir com o usuário.
- Ainda não verificado: sincronização das descobertas no multijogador.

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
