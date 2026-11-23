# Próximos passos de desenvolvimento (2026-11-23)

Cruzamento do comparativo (`COMPARATIVO_JOGOS.md`: Palworld + Stardew Valley e jogos de
criaturas), da Bíblia (`docs/narrativa/BIBLIA_NARRATIVA.md`), do `BACKLOG.md`, do
`PLANO_DE_DESENVOLVIMENTO.md` e das decisões guardadas na memória do projeto.

## Regras que filtram a lista

- Sem venda nem dinheiro (decisão de 2026-11-21).
- Amizade com slime só pela comida; depois vem o carinho (Bíblia §4; decisão de 2026-11-23).
- Cada slime tem 1 nível de trabalho; o desempenho vem da variante (Bíblia §4.1). Números
  decididos em `SLIMES_VARIANTES.md`.
- Mundo sem humanos; elfos só no Reino Élfico, no meio do jogo (Bíblia §6).
- Slimes sem braços nem pernas. Sem captura, sem desgaste cruel (crítica ao Palworld).
- Jogo livre: o HUD não mostra missões. Pedidos dos slimes, se entrarem, são opcionais e
  sem lista de tarefas na tela.

## Fase A — Base de slimes (o coração Palworld + Stardew)

1. **Variantes dos slimes.** Sorteio ao aparecer: Comum 93%, Raro 5% (trabalha 1,5× mais
   rápido), Arco-íris 2% (colheita melhor). Visual próprio (brilho no raro, reflexo
   arco-íris) e nome da variante no painel do slime. *Decidido; pronto para fazer.*
2. **Aptidão no painel do slime.** Mostrar a função ("Planta", "Rega", "Aduba") e a comida
   favorita (a regra de comida preferida já existe em `slime_feeding.gd`).
3. **Slimes guardam no baú.** O que os ajudantes colhem ou juntam vai para o baú da casa,
   como o transporte do Palworld. Hoje só plantam, regam e adubam.
4. **Comedouro da base.** Os slimes amigos comem dele sozinhos; com fome trabalham menos
   (sem sofrer). Comida favorita dá mais laço.
5. **Novas funções do bestiário.** Próximas espécies, conferindo o bestiário de 32:
   Capinito (mato), Lenhoco (árvores), Pedrito (pedras). Cada uma precisa de arte nova
   aprovada pelo usuário.
6. **Brasinha e Gelito nas regiões** (BACKLOG P2, já canônicos e com arte).

## Fase B — Progressão e rumo

7. **Ferramentas melhores.** Machado e picareta melhores para as árvores e pedras grandes
   (o jogo já avisa "muito grande"). Falta decidir o material (minério?).
8. **Rumo depois do tutorial, sem missões na tela.** Slimes com balão de pedido opcional
   ("quero cenoura"); atender dá laço ou uma semente nova (BACKLOG: sementes por presente
   de slimes, P2). *Decisão do usuário: pode entrar dessa forma?*
9. **Mais culturas e estações** (BACKLOG P2): repolho e beterraba com estágios próprios;
   culturas por estação.
10. **Pedido do PLANO Etapa 1:** sistema de diálogo e identidade dos slimes (nome,
    personalidade). A Bíblia (§6.3) reserva os relatos da história para os elfos.

## Fase C — Mundo e história (dependem de decisões EM ABERTO)

11. **Primeiro Boss Slime** como anomalia com rota pela comida (Bíblia §5). Quantidade,
    receitas e recompensas estão EM ABERTO: precisa de decisão antes.
12. **Reino Élfico e o Véu** (Bíblia §6). Desafio e número X EM ABERTO.
13. **Abrigo no começo:** a memória registra o conflito "encontrar abrigo" × "casa
    construída pelo jogador". Hoje vale a casa construída.

## Fase D — Qualidade (pode correr em paralelo)

14. **Som e música:** coletar, golpear, coração do slime, passos, música de dia e de noite.
15. **Revisão da energia** (skill balance-check), com aviso antes de acabar.
16. **Troca automática de ferramenta** (elogiada no Fae Farm).
17. **Co-op:** sincronizar itens no chão e o relógio; investigar a falha intermitente do
    teste com dois jogos.
18. **Construção sem grade rígida** e caminhos que os slimes conseguem andar.
19. **Visual pendente** (BACKLOG §6): sombras de pontes, pedras no rio, chuva.
20. **Antes de lançar:** remover os comandos de admin (`scripts/debug/`).

## Ordem sugerida

Fase A (1 → 2 → 3 → 4), depois 7 e 8, com a Fase D em paralelo. Fase C só depois das
decisões de narrativa.
