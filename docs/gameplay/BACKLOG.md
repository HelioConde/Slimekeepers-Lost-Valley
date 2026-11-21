# Backlog — jogo livre de fazenda

Direção atual: jogo de fazenda e vida no campo, sem missões, com a identidade do
Slimekeepers (slimes, magia, Floresta e Vale). Mecânicas no estilo do gênero; arte, nomes e
mundo próprios. Cânone: `docs/narrativa/BIBLIA_NARRATIVA.md`. Plano histórico:
`PLANO_DE_DESENVOLVIMENTO.md`.

Decisões do usuário (2026-11-21):
- **Sem venda, caixa de venda nem dinheiro.** Colheitas e comida alimentam os slimes.
- **Casa construída pelo jogador**: paredes, piso e portas em tilemap novo, interior
  acessível e mobília posicionável (diferencial em relação a uma casa pré-pronta).

Legenda: **P1** próximo · **P2** em seguida · **P3** depois.

## 1. Fazenda (núcleo)
- [x] Arar, plantar, regar, colher; crescimento por dia regado (`docs/gameplay/FAZENDA.md`)
- [x] Mapa de fazenda próprio: campo 16×10, casa provisória (cottage), saída para o Vale
- [x] Ferramentas com animação do personagem (enxada, regador)
- [ ] **P1** Construção da casa: modo construir (paredes, piso, porta, janela) em grade, tilemap
  novo (PixelLab), custo em materiais coletados (madeira/pedra), substitui a casa provisória
- [ ] **P1** Interior da casa: entrar pela porta, cama para dormir, mobília posicionável
  (cama, mesa, baú, tapete, plantas), salva no save
- [ ] **P2** Regador com carga d'água (encher no riacho/poço)
- [ ] **P2** Mais culturas e estágios próprios para repolho e beterraba (PixelLab)
- [ ] **P2** Estações do ano: culturas por estação, morrem na troca
- [ ] **P3** Espantalho, irrigador, adubo, árvores frutíferas
- [ ] **P3** Terra arada volta a ser grama se ficar vazia vários dias

## 2. Ciclo do dia e progresso
- [x] Dormir para virar o dia (porta da casa provisória; vai para a cama do interior)
- [x] Energia do jogador (ações gastam; dormir recupera)
- [x] Save/load em disco ao dormir + Continuar no menu
- [ ] **P2** Desmaio à meia-noite / acordar em casa

## 3. Inventário e recursos
- [x] Barra rápida de itens com ícones PixelLab
- [x] ~~Caixa de venda e dinheiro~~ — removido por decisão do usuário
- [ ] **P1** Coleta de materiais (madeira de galhos/tocos, pedra) para construir
- [ ] **P2** Sementes por troca/presente de slimes ou coleta silvestre (sem loja com dinheiro)
- [ ] **P2** Baú de armazenamento (mobília)

## 4. Slimes e vida no mundo
- [x] Alimentar slimes com colheitas/porção ([F] com o item da barra), 1×/dia, corações
- [ ] **P2** Slimes ajudam na fazenda (Brotinho rega/cuida das plantas)
- [ ] **P2** Brasinha e Gelito nas regiões atuais (canônicos; luz própria já existe)
- [ ] **P3** Mostrar corações de afinidade ao interagir
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
