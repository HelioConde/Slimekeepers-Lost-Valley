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
- [x] ~~Mapa de fazenda próprio~~ — removido: plantio livre com a enxada em qualquer chão (`FAZENDA.md`)
- [x] Ferramentas com animação do personagem (enxada, regador)
- [x] Construção da casa: sem casa inicial, arrastar o retângulo em qualquer lugar, custo em madeira/pedra, uma só (`CASA.md`)
- [x] Interior da casa: porta, cama para dormir, mobília paga, fogão para cozinhar, salva no save
- [x] Regador com carga d'água: 20 regas; enche com [E] olhando para o lago/riacho
- [ ] **P2** Mais culturas e estágios próprios para repolho e beterraba (PixelLab)
- [ ] **P2** Estações do ano: culturas por estação, morrem na troca
- [ ] **P3** Espantalho, irrigador, adubo, árvores frutíferas
- [x] Terra arada volta a ser grama após 3 dias vazia e sem rega

## 2. Ciclo do dia e progresso
- [x] Dormir para virar o dia (cama da casa construída)
- [x] Energia do jogador (ações gastam; dormir recupera)
- [x] Save/load em disco ao dormir + Continuar no menu
- [x] Desmaio à meia-noite: acorda às 06:00 ao lado da cama (se a casa estiver na região), com 50 de energia

## 3. Inventário e recursos
- [x] Barra rápida de itens com ícones PixelLab
- [x] ~~Caixa de venda e dinheiro~~ — removido por decisão do usuário
- [x] Coleta de materiais: mato (fibra), graveto, pedra, árvores pequenas (madeira) na Floresta e no Vale
- [ ] **P2** Sementes por troca/presente de slimes ou coleta silvestre (sem loja com dinheiro)
- [x] Baú de armazenamento: [E] no baú da casa abre bolsa × baú; guarda pilhas sem o limite de 99

## 4. Slimes e vida no mundo
- [x] Alimentar slimes com colheitas/porção ([F] com o item da barra), 1×/dia, corações
- [ ] **P2** Slimes ajudam na fazenda (Brotinho rega/cuida das plantas)
- [ ] **P2** Brasinha e Gelito nas regiões atuais (canônicos; luz própria já existe)
- [x] Mostrar corações de afinidade ao cumprimentar um slime com [E]
- [x] Coleta silvestre diária (mato, gravetos e pedras voltam no dia seguinte)

## 5. Culinária
- [x] **P2** Receitas no fogão da casa: porção de folhas, cenoura assada (2 cenouras, +40) e sopa de legumes (cenoura + beterraba + repolho, +70)
- [x] Comida recupera energia: [F] sem slime por perto come o item da barra (colheita +12, porção +30)

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
- [ ] **P3** Multijogador P2P pela Steam (decisão do usuário, 2026-11-23). Precisa de uma integração Steam (ex.: GodotSteam GDExtension): instalar só com revisão e aprovação; App ID e modo (cooperativo ou não) A DEFINIR
