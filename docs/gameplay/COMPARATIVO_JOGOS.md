# Comparativo com jogos do mesmo estilo (2026-11-23)

Pesquisa rápida em análises da imprensa (sem jogar os títulos). Jogos com fazenda e
criaturas que ajudam: Paleo Pines, Ooblets, Moonstone Island, Fae Farm e Slime Rancher;
Stardew Valley como referência de fazenda. O mundo do Slimekeepers não tem humanos
(BIBLIA_NARRATIVA), então ideias de vilarejo/NPC não entram.

## O que os outros fazem e as críticas que recebem

| Jogo | Elogiado | Criticado |
|---|---|---|
| Paleo Pines | cada dino tem uma habilidade de fazenda; ajudantes abrem áreas e quebram obstáculos | ciclo repetitivo, pouco conteúdo depois de montar a fazenda; ajudantes confusos de usar |
| Ooblets | criaturas nascem de sementes ganhas; três ciclos (fazenda, casa, pedidos) ligados às criaturas | batalhas fáceis demais; energia cara e cansativa; minijogos rasos |
| Moonstone Island | arte em pixel; muitas criaturas para colecionar | "ambicioso, mas bagunçado"; recurso raro difícil de achar; bugs |
| Fae Farm | troca automática de ferramenta; co-op | entrar no meio da partida no co-op é ruim; bugs no regador em área |
| Slime Rancher | slimes com comida favorita que rende o dobro; combinações | (não pesquisado a fundo) |
| Stardew Valley | liberdade | sem tutorial de verdade: o primeiro dia sobrecarrega quem é novo |

Boas práticas de tutorial (Unity, Roblox, Apple): ensinar um passo por vez, no momento
em que o jogador usa a mecânica pela primeira vez, e repetir dicas curtas depois.

## Onde o Slimekeepers está

Já tem: coleta, corte, pedras e picareta, fabricação (mãos e bancada), plantio livre,
casa construível, energia e vida, slimes com funções na fazenda (Brotinho planta,
Bolhinha rega, Musguinho aduba), laço por comida, multijogador para dois, tutorial
guiado com destaque.

Não tem: venda/economia, estações do ano, ferramentas melhores (picareta e machado
melhores são citados no jogo, mas não existem), pesca, música e efeitos sonoros (só
ambiente da floresta), pedidos/objetivos depois do tutorial, mapa.

## O que melhorar (prioridade sugerida)

1. **Objetivo depois do tutorial.** O tutorial termina na bancada e o jogo fica sem rumo
   (crítica de Paleo Pines e Stardew). Sugestão: pedidos curtos dos próprios slimes
   ("o Brotinho quer 3 cenouras") que destravam a próxima ferramenta ou região.
2. **Ferramentas melhores.** O jogo já diz "essa árvore/pedra é muito grande": falta o
   machado e a picareta melhores para isso ter recompensa.
3. **Slimes que mudam o jogo.** Cada espécie deve abrir algo (como os dinos de Paleo
   Pines): ex. Bolhinha atravessa água, Musguinho limpa mato grande. Explicar na hora em
   que o slime vira amigo (crítica: ajudantes confusos).
4. **Comida favorita.** Como no Slime Rancher: comida preferida dá mais laço (já existe
   LIKES em slime_feeding.gd); mostrar no HUD do slime qual é a favorita.
5. **Som e música.** Coletar, golpear, coração do slime, passos, música calma de dia e de
   noite. Hoje o jogo é quase mudo.
6. **Energia gentil.** Ooblets foi criticado por energia cara: revisar custos (balance-check)
   e avisar antes de acabar.
7. **Troca automática de ferramenta** (elogiada no Fae Farm): ao golpear árvore com a mão
   vazia, usar o machado da mochila.
8. **Co-op começando juntos.** Entrar no meio é o ponto fraco do Fae Farm; nosso convidado
   já recebe o mundo do anfitrião. Falta itens no chão e relógio sincronizados.
9. ~~Economia leve~~: decidido pelo usuário em 2026-11-21: sem venda nem dinheiro. A
   colheita serve para comer, cozinhar e alimentar slimes.
10. **Estações e eventos.** Variedade ao longo dos dias (flores, frutos, clima). Grande;
    depois dos itens acima.
11. **Qualidade e bugs.** Moonstone e Fae Farm perderam nota por bugs: manter a bateria de
    testes (tools/play_tutorial.gd e os demais) rodando a cada mudança.

## Palworld + Stardew Valley (direção do usuário, 2026-11-23)

O Slimekeepers vai ser uma mistura de Palworld (criaturas trabalhando na base) com
Stardew Valley (fazenda calma, dias e estações). Sem combate nem captura: aqui a
amizade vem pela comida.

**Palworld, segundo as análises:**
- Elogiado: cada Pal tem aptidões de trabalho (fogo cozinha e funde, água cuida das
  plantações), e escolher quem faz o quê é "a melhor parte da base". Fugir do "cortar
  400 árvores" sozinho é o grande atrativo. Progresso por níveis que liberam receitas
  (árvore de tecnologia) prende o jogador.
- Criticado: construção em grade rígida, caminhos ruins para criaturas grandes,
  automação rasa e sem prioridades de tarefa, "trabalho forçado" (sanidade caindo),
  ritmo lento e repetitivo no meio do jogo.

**Comparação com o que já temos:**

| Palworld | Slimekeepers hoje | Falta |
|---|---|---|
| Pals com aptidões de trabalho | Brotinho planta, Bolhinha rega, Musguinho aduba (4 tarefas/dia) | mais aptidões: coletar, cortar, minerar, levar ao baú, fabricar |
| Base com bancadas que os Pals operam | bancada e casa só do jogador | slimes trabalhando na bancada e guardando no baú |
| Comedouro: Pals comem sozinhos | amizade e laço por comida dada à mão | comedouro da base; laço alto = trabalha melhor |
| Árvore de tecnologia por nível | receitas fixas (mãos e bancada) | níveis/pontos que liberam receitas e ferramentas |
| Captura com esferas | amizade por comida (decisão do usuário) | — (não copiar a captura) |
| Sanidade cai trabalhando (criticado) | sem desgaste | manter assim: slime cansado descansa, nunca sofre |

**O que fazer, juntando com a lista acima (nova ordem):**

1. **Aptidões dos slimes** (o coração do jogo, como em Palworld): cada espécie tem um
   trabalho, com 1 nível só (decisão do usuário, 2026-11-23; sem subir de nível). O que muda
   o desempenho é a variante da BIBLIA_NARRATIVA §4.1: Comum (normal), Raro (trabalha mais
   rápido), Arco-íris (colheita melhor) e Boss (as duas). Raros aparecem com chance pequena
   em cada espécie; multiplicadores e chances estão EM ABERTO na Bíblia. Mostrar a função e
   a variante no HUD do slime. O bestiário de 32 com profissões já está planejado.
2. **Base de trabalho:** slimes amigos usam a bancada (fabricam sozinhos o que o jogador
   pediu), coletam gravetos/pedras/mato por perto e levam ao baú. Uma fila simples de
   pedidos com prioridade (a crítica nº 1 da automação do Palworld).
3. **Comedouro:** os slimes da base comem dele; com fome trabalham menos. Comida favorita
   dá mais laço e mais vontade de trabalhar (sem punição dura).
4. **Progresso por níveis:** experiência de coletar/fabricar/cuidar libera receitas e as
   ferramentas melhores (resolve "árvore/pedra muito grande").
5. **Objetivo depois do tutorial:** pedidos dos slimes que levam aos itens 1–4.
6. **Construção livre de verdade:** prévia seguindo o mouse (bancada já faz), sem grade
   rígida, e caminhos que os slimes conseguem andar.
7. Som e música; energia gentil; troca automática de ferramenta; co-op começando juntos;
   estações (itens 5–10 da lista acima; sem venda/dinheiro).

O que fica de fora de propósito: combate e captura (não definidos na Bíblia; amizade é
pela comida) e qualquer desgaste cruel das criaturas.

## Fontes

- Paleo Pines: [TechRadar](https://www.techradar.com/gaming/paleo-pines-review-almost-dino-mite),
  [Destructoid](https://destructoid.com/how-to-turn-dinosaurs-into-helpers-in-paleo-pines),
  [GameSkinny](https://www.gameskinny.com/?p=113948), [Softpedia](https://www.softpedia.com/reviews/games/playstation-5/paleo-pines-review-537390.shtml)
- Ooblets: [GameSpot](https://gamespot.com/reviews/ooblets-early-access-review/1900-6417509/),
  [Shacknews](https://shacknews.com/article/132110/ooblets-review),
  [Game Informer](https://gameinformer.com/review/ooblets/a-cheerful-grind)
- Moonstone Island: [Siliconera](https://www.siliconera.com/review-moonstone-island-is-ambitious-but-messy/),
  [Prima Games](https://primagames.com/gaming/moonstone-island-review-creative-and-cozy-creature-collecting)
- Fae Farm: [Prima Games](https://primagames.com/reviews/fae-farm-review-farming-has-never-been-so-magical),
  [RPGFan](https://www.rpgfan.com/review/fae-farm), [Digital Trends](https://digitaltrends.com/?p=3419363)
- Slime Rancher: [Slime Rancher Wiki](https://slimerancher.fandom.com/wiki/Slimes),
  [PC Gamer](https://pcgamer.com/slime-rancher-review)
- Tutorial: [Unity](https://unity.com/how-to/10-first-time-user-experience-tips-games),
  [Roblox](https://create.roblox.com/docs/production/game-design/onboarding-techniques),
  [PC Gamer, Stardew](https://pcgamer.com/uk/stardew-valley-tips)
- Palworld: [PC Gamer (análise)](https://www.pcgamer.com/games/survival-crafting/palworld-review/),
  [PC Gamer (cortar 400 árvores)](https://www.pcgamer.com/games/survival-crafting/for-years-survival-games-have-convinced-us-that-chopping-down-400-trees-is-somehow-part-of-the-fantasy-palworld-proves-them-wrong/),
  [VGC 1.0](https://videogameschronicle.com/review/palworld-10-review),
  [GamesRadar](https://gamesradar.com/palworld-review),
  [PCGamesN](https://www.pcgamesn.com/palworld/nothing-like-pokemon),
  [VideoGamer](https://www.videogamer.com/reviews/palworld-review)
