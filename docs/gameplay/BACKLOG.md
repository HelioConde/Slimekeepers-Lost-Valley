# Backlog — jogo livre de fazenda

Direção atual: jogo de fazenda e vida no campo, sem missões, com a identidade do
Slimekeepers (slimes, magia, Floresta e Vale). Mecânicas no estilo do gênero; arte, nomes e
mundo próprios. Plano histórico: `PLANO_DE_DESENVOLVIMENTO.md`.

Legenda: **P1** próximo · **P2** em seguida · **P3** depois.

## 1. Fazenda (núcleo)
- [x] Arar, plantar, regar, colher; crescimento por dia regado (`docs/gameplay/FAZENDA.md`)
- [ ] **P1** Mapa de fazenda próprio: campo grande, casa do jogador, saída para Floresta/Vale
- [ ] **P1** Ferramentas com animação do personagem (enxada, regador já em `assets/Create_a_*`)
- [ ] **P2** Regador com carga d'água (encher no riacho/poço)
- [ ] **P2** Mais culturas e estágios próprios para repolho e beterraba (PixelLab)
- [ ] **P2** Estações do ano: culturas por estação, morrem na troca
- [ ] **P3** Espantalho, irrigador, adubo, árvores frutíferas
- [ ] **P3** Terra arada volta a ser grama se ficar vazia vários dias

## 2. Ciclo do dia e progresso
- [ ] **P1** Dormir na cama para virar o dia (com tela de resumo do dia)
- [ ] **P1** Energia do jogador (ações gastam; dormir recupera)
- [ ] **P1** Save/load em disco (fazenda, bolsa, relógio, amizades)
- [ ] **P2** Desmaio à meia-noite / acordar em casa

## 3. Inventário e economia
- [ ] **P1** Barra rápida de itens (sementes, ferramentas, colheitas) no lugar da bolsa em texto
- [ ] **P1** Caixa de venda e dinheiro
- [ ] **P2** Loja de sementes (substitui o kit inicial)
- [ ] **P2** Baú de armazenamento
- [ ] **P3** Ícones PixelLab para cada item

## 4. Slimes e vida no mundo
- [ ] **P2** Slimes ajudam na fazenda (Brotinho rega/cuida das plantas)
- [ ] **P2** Brasinha e Gelito nas regiões atuais (canônicos; luz própria já existe)
- [ ] **P3** Presentes e afinidade com slimes, alimentação com as colheitas
- [ ] **P3** Coleta silvestre diária na Floresta (renasce por dia)

## 5. Culinária
- [ ] **P2** Receitas com cenoura, beterraba e repolho na estação do Vale
- [ ] **P3** Comida recupera energia

## 6. Visual e atmosfera (pendências das etapas de iluminação)
- [ ] **P2** Sombras das pontes e penhascos acompanharem o horário
- [ ] **P2** Pedras dentro do rio com sombra/contato na água
- [ ] **P3** `LightOccluder2D` seletivo (árvores/pedras grandes) se houver ganho claro
- [ ] **P3** Chuva e clima por dia

## 7. Técnico
- [ ] **P1** Teste jogável real da fazenda no editor (Godot MCP livre)
- [ ] **P2** Remover/arquivar cena e ferramentas obsoletas (`world.tscn`, `test_clearing.gd`, `build_forest_v2.gd`) — pedir confirmação
- [ ] **P2** Commitar a correção do servidor `godot-mcp` (porta ocupada) no repositório dele
- [ ] **P3** Integrar `feat/visual-ambient-lights` na `main` (precisa de autorização)
