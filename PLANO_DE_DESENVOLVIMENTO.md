# Slimekeepers: Lost Valley — Plano de desenvolvimento

**Data inicial:** 25 de outubro de 2026  
**Engine:** Godot 4.x  
**Prioridade:** jogo pequeno que funciona antes de aumentar escopo.

## Identidade provisória

Um jogo 2D em pixel art, com exploração top-down, uma protagonista com uma bolsa mágica herdada da mãe e criaturas slime com diferentes personalidades e funções. Esta formulação é um ponto de partida baseado nos assets, e deve ser confirmada no documento de visão do jogo.

## Etapa 0 — base de trabalho (v0.1)

- [x] Inventário de assets fornecidos
- [x] Projeto Godot com cena inicial
- [x] Movimento e animação em oito direções
- [x] Mapa provisório de grama/terra
- [x] Três slimes com animação de idle
- [x] Interação com tecla E e objetivo na HUD
- [x] Execução real no Godot 4.7.2, capturas e testes de integração

**Critério de aceite:** personagem se move, três slimes aparecem, cada um aceita uma interação, HUD marca 3/3.

## Etapa 1 — primeiro ciclo jogável (v0.2)

- [ ] Definir o ciclo central: explorar → encontrar slime → vínculo → habilidade → melhorar vale
- [ ] Sistema de diálogo e identidade dos slimes
- [ ] Um recurso coletável com inventário simples
- [x] Limites de mapa e colisões reais na Clareira do Despertar
- [x] Tela inicial funcional com opções e retorno pelo gameplay
- [ ] Menu de pausa durante a exploração

## Primeira região — Clareira do Despertar (26/10/2026)

- [x] Mapa editável de 100 × 100 tiles e spawn central
- [x] Floresta densa, árvores em pixel art nítida e diversidade de vegetação
- [x] Trilhas norte/leste/sul e três pequenas áreas secundárias
- [x] Colisões de troncos, árvores e rochas; vegetação baixa livre
- [x] Câmera limitada ao mapa e ordenação visual pelos pés
- [x] Cogumelos vermelho, marrom, luminoso e samambaia gerados com autorização
- [x] 86 verificações automáticas aprovadas; capturas nativas do cenário
- [ ] Conectar as saídas a futuras regiões (fora do escopo desta entrega)

## Etapa 2 — expansão controlada (v0.3)

- [ ] Uso da bolsa mágica como inventário
- [ ] Um slime ajuda na coleta ou agricultura
- [ ] Uma missão narrativa curta com começo, meio e fim
- [ ] Salvamento/carregamento local

## Etapa 3 — vertical slice (v0.4)

- [ ] Uma área finalizada do vale
- [ ] Arte, sons e interface consistentes
- [ ] Tutorial de 5 a 10 minutos
- [ ] Testes de desempenho e experiência

## Regras do projeto

1. Um recurso novo por vez, testado antes de prosseguir.
2. Cada versão deve abrir no Godot e ter uma meta alcançável.
3. Evitar adicionar mais mapas, ferramentas ou slimes sem necessidade do ciclo principal.
4. Documentar decisões de mecânica, arte e história.
5. Usar versionamento Git e manter backups.
