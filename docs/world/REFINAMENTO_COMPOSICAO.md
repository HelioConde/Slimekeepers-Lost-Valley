# Clareira do Despertar — composição e navegação

Revisão de 26/10/2026 a partir do briefing “Prompt melhorado — Clareira do Despertar”. Projeto: `C:\Slimekeepers_Lost_Valley_v0_1`.

## Resultado

O spawn continua em `(1600,1600)`, com uma área imediata de 160 × 160 px livre de colisões. Um marco de pedra ancestral em `(1430,1560)` fica próximo ao jogador, visível por inteiro no enquadramento inicial: pedra central com pequeno símbolo de folha desenhado no Godot, círculo interrompido de pedras, flores, musgo e um cogumelo azul. A abertura sul permite aproximação. As pedras possuem colisões na base e ordenação por Y.

A floresta passou de 1.162 para **943 árvores**. A retirada foi seletiva: regiões de baixa densidade seguem um campo espacial contínuo e áreas de interesse, em vez de retirar uma árvore a cada intervalo. Blocos densos e a borda externa da mata foram preservados. Também foram retiradas sete copas que, embora não bloqueassem fisicamente, encobriam o personagem ao chegar aos novos pontos de interesse.

As três saídas principais norte/leste/sul continuam abertas. As três ramificações anteriores foram mantidas e duas novas trilhas curtas foram adicionadas:

- **LogHollow**, a oeste da trilha sul: tronco com musgo cercado de flores, junto a um toco existente.
- **BlueFernNook**, a leste da trilha norte: pequena abertura com samambaias e cogumelos luminosos.

As trilhas têm largura variável, bordas discretamente recortadas e terminações arredondadas. Todas as margens de grama são desenhadas antes de todas as faixas de terra, eliminando as sobreposições triangulares nos cruzamentos. A vegetação baixa foi retirada do corredor central mais estreito; invasões de grama ficam nas margens. Obstáculos antigos próximos aos novos desvios foram reposicionados para fora da passagem.

Sombras projetadas sob árvores grandes reforçam a profundidade, enquanto o chão recebe uma transição discreta de iluminação em direção ao centro. Os sprites permanecem nítidos e a ordenação por Y foi preservada. O lago simples solicitado pelo usuário permanece sem nascente, pedras adicionais ou jato. Esta etapa não alterou a UI nem criou sistemas de gameplay.

## Arquivos criados

- `scripts/world/composition_refinement.gd`: revisão incremental, seleção de densidade, trilhas, sombras, marco, recantos e desobstrução visual.
- `tools/refine_composition.gd`: aplica a revisão à cena já salva, sem reconstruir o projeto.
- Este documento e capturas de `hollow`/`fern_nook`.

## Arquivos modificados

- `scenes/regions/ClareiraDoDespertar.tscn`: composição final editável.
- `scripts/world/clearing_layout.gd`: duas novas curvas de trilha.
- `scripts/world/forest_ground.gdshader`: transição discreta de iluminação central.
- `scripts/world/clearing_polish.gd`: evita recolocar plantas em cima do marco em uma execução posterior do acabamento.
- `tools/build_clearing.gd`: incorpora a revisão em uma reconstrução explícita futura.
- `tools/test_clearing.gd`: verifica colisão do marco, aproximação livre e sombras, além das novas rotas.
- `tools/capture_clearing.gd`: inclui enquadramentos dos dois novos recantos.
- `LEIA-ME.md` e `docs/world/CLAREIRA_DO_DESPERTAR.md`: documentação atualizada.

## Assets reaproveitados

Carvalhos e pinheiros existentes; `assets/menu/environment/stone.png`, `flowers.png`, `grass.png`; `assets/world/forest/fern.png` e `mushroom_glow.png`; o tronco original em `assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/`. O chão continua usando `grass_dirt_v3_32x32.png`.

**Nenhum PNG foi gerado ou modificado nesta revisão. Nenhuma chamada paga ao PixelLab foi realizada.** O pequeno símbolo da pedra, as sombras e os contornos do solo são elementos nativos do Godot.

## Validação real

Godot 4.7.2 foi executado com física headless e renderizador OpenGL Compatibility para as capturas.

- **59 verificações da região, zero falhas**, incluindo oito trilhas, spawn, acesso ao marco, base sólida do marco, colisões das 943 árvores, limites, lago e aproximação aos três slimes.
- **43 verificações do menu e missão, zero falhas**, incluindo entrada em Novo Jogo, amizade por E, retorno ao menu e preferências intactas.
- Capturas 1280 × 720: `clareira_spawn.png`, `clareira_east.png`, `clareira_north.png`, `clareira_hollow.png`, `clareira_fern_nook.png`.
- Visão geral 1280 × 1280: `clareira_overview.png`.

A inspeção visual levou a dois ajustes adicionais: o marco foi deslocado para não ficar atrás do HUD, e as copas que escondiam o personagem nos novos recantos foram removidas. As capturas foram feitas novamente após esses ajustes. O lago continua bloqueando a entrada física e não possui colisões da nascente removida.

## Preservação e limites

O mapa anterior e a geometria anterior estão em `docs/backups/before_composition_refinement_20261026/`. A revisão incremental é versionada; rodar novamente o aplicador na versão atual não refaz a floresta nem apaga ajustes manuais. Executar o construtor completo continua sendo uma reconstrução explícita da cena e exige preservar alterações manuais antes.

O marco e os recantos são pontos ambientais, sem novas recompensas, NPCs ou missões. As regiões além das três saídas, coleta de água, agricultura, inventário e salvamento continuam fora desta entrega. Não houve commit nem push.
## Substituição da pedra borrada — 26/10/2026

As seis ocorrências de `mossy_rock_tall.png` foram substituídas pelo sprite existente `assets/menu/environment/stone.png`, com escala inteira 2×, filtro nearest e uma samambaia existente atrás da pedra. Posições dos objetos, sombras e colisões foram preservadas. Nenhum PNG original foi modificado e não houve geração paga.

A aplicação está em `scripts/world/rock_clarity.gd`, integrada ao construtor da região; `tools/replace_soft_rocks.gd` permite aplicar a troca incrementalmente. A captura `clareira_spring.png` foi revisada em 1280 × 720. Validação final: 59 verificações da região, zero falhas, 1972 amostras de colisão.

Foram removidas de `scenes/world.tscn` seis referências herdadas a nós já inexistentes: cinco árvores e o antigo Trickle. As alterações locais dos tiles foram comparadas e preservadas exatamente, assim como as demais substituições de propriedades. Cópias anteriores das duas cenas estão em `docs/backups/before_rock_clarity_20261026/`.
