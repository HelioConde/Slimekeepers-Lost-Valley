# Clareira do Despertar — primeira região jogável

Implementada em 26/10/2026 no projeto `C:\Slimekeepers_Lost_Valley_v0_1`, validada com Godot 4.7.2. A referência da ilha orienta a floresta e os caminhos para expansões futuras; não foi utilizada como fundo nem transformada em um mapa completo nesta etapa.

**Revisão atual:** marco ancestral próximo ao spawn, 943 árvores com densidade variada, oito trilhas (três principais e cinco ramificações), novas microclareiras e sombras de copas. Validação: 59 testes da região + 43 do menu, sem falhas. Consulte `REFINAMENTO_COMPOSICAO.md` para arquivos, recursos, capturas e limites. As seções de evolução abaixo preservam o histórico das etapas anteriores.

## Jogar e editar

F5 abre o menu existente. **Novo Jogo** entra em `scenes/world.tscn`, que instancia a cena reutilizável `scenes/regions/ClareiraDoDespertar.tscn`. O jogador começa em `(1600,1600)`. WASD/setas movimentam em oito direções, Shift corre e E conversa com os três slimes. O botão Menu retorna à abertura.

O mapa tem 3200 × 3200 px, organizado em 100 × 100 tiles de 32 px. A clareira principal possui raio irregular de aproximadamente 306 px, com núcleo livre de obstáculos. Três trilhas curvas conduzem a marcadores de saída: norte para futuras montanhas, leste para exploração de slimes e sul para a futura fazenda. Três ramificações menores terminam em recantos da floresta. Nenhuma saída carrega outra região por enquanto; a chegada exibe uma mensagem explícita.

## Cena e recursos

- `Ground`: 10.000 células reais de TileMapLayer, com espelhamentos de tiles para diminuir repetição.
- `GroundDetails`: pequenos detalhes transparentes de chão.
- `VegetationLow`: cerca de 3.000 células com grama, flores, samambaias e cogumelos, sem colisão.
- `WoodlandDetails`: detalhes individuais agrupados, com posições fora da grade nas bordas da clareira, trilhas e recantos; plantas sob a nascente foram retiradas.
- `Obstacles`: 66 pedras em TileMapLayer com polígonos de colisão no TileSet.
- `VegetationHigh`: 1.162 árvores em quatro silhuetas e escalas inteiras 1×/2×.
- `Decorations`: arbustos, troncos, tocos e rochas; 1.328 objetos no total, contando as árvores.
- `ForestFloor` e `NaturalTrails`: polígonos Godot com texturas dos tiles existentes, para contornos orgânicos sem alterar PNGs.
- `SpawnPoints`: PlayerSpawn, três marcadores de slime e três saídas.
- `Exits`: áreas de detecção sem bloqueio físico.
- `Player`: instância original, animações preservadas e limites configuráveis.
- `ForestAmbience`: pequenos vagalumes e folhas caindo, atualizados a 8 Hz e respeitando a preferência existente de reduzir animações.

Troncos, árvores e rochas usam camada física 2; o jogador mantém camada 1 e máscara 2. A ordenação por Y utiliza os pés dos objetos, e as copas não são colliders. Sombras de contato ficam abaixo da vegetação. A câmera mantém sua suavização, com limites de 0 a 3200 nos dois eixos.

## Árvores nítidas e procedência

Os pinheiros ilustrados `pine_wide.png` foram retirados de todas as instâncias do mundo após a revisão visual solicitada. O arquivo permanece preservado, sem uso nesta cena. Foram copiadas as árvores originais abaixo, sem edição dos PNGs:

| Uso | Origem | Destino |
|---|---|---|
| Pinheiro nítido | `C:\Slimekeepers Lost Valley\assets\sprites\objects\tree_pine_tall_evergreen_pin\rotations\tree_pine_tall_evergreen_pin.png` | `assets/world/forest/pine_crisp.png` |
| Carvalho jovem | `C:\Slimekeepers Lost Valley\assets\sprites\objects\tree_oak_small_small_oak_tre\rotations\tree_oak_small_small_oak_tre.png` | `assets/world/forest/oak_young.png` |
| Carvalhos grande/médio | Arquivos existentes nesta cópia | `assets/menu/environment/oak.png`, `oak_medium.png` |

Todas as árvores usam Nearest e escalas inteiras, com mipmaps desabilitados na importação. As duas rochas musgosas foram copiadas do pacote fornecido pelo usuário: `06_Plantacoes_Objetos/pedra_com_musgo.png` e `vaso_cesta_01.png` (apesar do nome, a segunda é uma pedra). Flores, grama, tocos, arbustos, troncos, personagem e animações dos slimes foram reutilizados.

As quatro gerações PixelLab autorizadas produziram cogumelos vermelho, marrom e luminoso de 32 × 32, e uma samambaia de 48 × 48. Todas estão integradas ao TileSet. IDs, prompts, hashes, validação de transparência e consumo observado de 4,00 unidades estão em `PIXELLAB_ASSETS.md`. Não houve geração adicional de árvores.

## Arquivos de implementação

- `scenes/regions/ClareiraDoDespertar.tscn`: mapa editável, já salvo; não é construído novamente ao jogar.
- `assets/world/clearing_tileset.tres`: chão, plantas e pedras com colisão.
- `scripts/world/clearing_region.gd`: herda os sistemas existentes de HUD/amizade; configura a região e as saídas.
- `scripts/world/clearing_layout.gd`: dimensões, spawn, curvas e áreas reservadas.
- `scripts/world/forest_ambience.gd`: pequenos pontos de luz.
- `tools/build_clearing.gd`: construtor determinístico com seed 261026.
- `tools/test_clearing.gd`, `tools/capture_clearing.gd`: validação física e capturas reais.

Modificações limitadas no projeto existente: `scenes/world.tscn` passou a instanciar a região, `scripts/player.gd` ganhou o parâmetro exportado `world_bounds` e passou a usá-lo no clamp. O menu, o controlador original `world.gd`, a cena e as animações do personagem e os sistemas de amizade foram preservados. Backups anteriores à alteração estão em `docs/backups/before_clearing_20261026/`.

**Edição manual:** é possível editar a cena e o TileSet diretamente no Godot. O construtor só executa mediante comando explícito; reexecutá-lo substitui a cena gerada e o TileSet, portanto preserve primeiro eventuais mudanças manuais nesses dois arquivos.

## Validação executada

Godot foi executado de fato, com importação, física headless e renderizador OpenGL Compatibility para capturas.

- `tools/test_clearing.gd`: **43 verificações, zero falhas**, com **2.089 consultas usando a cápsula real do jogador**. Inclui spawn após frames de física, seis rotas contínuas, acesso aos três slimes, colisões de todas as 1.162 árvores, rochas/logs/tocos, limites e detecção das três saídas.
- Movimento testado com eventos de entrada nas oito direções. As rotas usam consulta de forma e varredura contínua via `test_move`; não são apenas testes de distância no desenho.
- `tools/test_menu.gd`: **43 verificações, zero falhas**. Inclui teclado, mouse, D-pad simulado, foco, opções, Novo Jogo, interação E com os três slimes, ausência de duplicação de amizade e retorno ao menu. Preferências persistidas permaneceram idênticas.
- Capturas nativas em 1280 × 720: `clareira_spawn.png`, `clareira_north.png`, `clareira_east.png`. Visão geral de inspeção em 1280 × 1280: `clareira_overview.png`.
- A inspeção visual motivou a substituição dos pinheiros suaves e o reposicionamento dos slimes, para os três ficarem visíveis no enquadramento inicial. Os sprites originais não foram modificados.

Comandos, usando o console Godot instalado:

```powershell
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Slimekeepers_Lost_Valley_v0_1' --script res://tools/test_clearing.gd
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Slimekeepers_Lost_Valley_v0_1' --script res://tools/test_menu.gd
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\Slimekeepers_Lost_Valley_v0_1' --rendering-method gl_compatibility --script res://tools/capture_clearing.gd -- spawn
```

## Próximas etapas ainda não implementadas

As regiões de montanhas/cachoeiras, exploração e fazenda continuam reservadas. Agricultura, inventário, coleta, salvamento, companheiros completos, áudio e missões narrativas permanecem fora desta entrega. O arquivo de referência não representa áreas já implementadas. Não houve commit nem push.

## Segunda revisão visual — 26/10/2026

O chão recebeu variação discreta de tons e as trilhas ganharam grãos e pequenas manchas, com shaders próprios da região (`forest_ground.gdshader` e `forest_surface.gdshader`). Os shaders do menu não foram alterados. Os sprites permanecem originais, com filtro Nearest.

Na clareira, a distribuição uniforme de vegetação alta foi substituída por pequenos agrupamentos de flores, samambaias e cogumelos nas bordas. A área central permanece aberta e os três slimes ficam visíveis. As ramificações têm recantos de cogumelos luminosos, samambaias e cogumelos marrons. A vegetação nas margens das trilhas possui espaçamento irregular.

O painel de missão e a faixa de controles foram compactados para liberar área de exploração na tela, mantendo os textos e as funcionalidades existentes. Folhas discretas em queda complementam os vagalumes. A opção de reduzir animações interrompe ambos.

O acabamento foi aplicado de forma incremental por `tools/polish_clearing.gd` e `scripts/world/clearing_polish.gd`, preservando as árvores, colisões, marcadores e caminhos já salvos. O construtor também chama esse acabamento para futuras reconstruções explícitas. Backups desta revisão: `docs/backups/before_world_polish_20261026/`.

As duas suítes foram executadas novamente: 43 verificações de região e 43 de menu, sem falhas. Foram renovadas as capturas de spawn, norte, leste e visão geral, além da nova `clareira_grove.png`. Não foram realizadas gerações pagas nem consumidos créditos nesta revisão.

## Nascente natural — 26/10/2026

Acrescentada `NaturalSpring` em `(1785,1465)`, no nordeste da clareira. Reutiliza `assets/menu/environment/waterfall.png`, pedras, grama e flores originais. O lago foi construído com polígonos Godot, margem irregular e shader de água com pixels definidos. Não houve geração de imagens nem consumo de créditos.

O lago possui colisão correspondente ao polígono da água, na camada 2. A base rochosa também possui colisão. A margem oeste, em `(1675,1485)`, é acessível desde o spawn. Próximo a ela, **E** examina a nascente e exibe uma descrição; a interação com slimes mantém prioridade. Não há coleta, inventário ou irrigação nesta etapa. O nó integra o grupo `water_sources` para futura integração dessas mecânicas.

Água e espuma animam a 8 Hz e respeitam a preferência de reduzir animações. Foram removidas plantas sob o lago e reposicionado um arbusto que aparecia sobre a água, preservando árvores e rotas. Arquivos novos: `scripts/world/spring_builder.gd`, `spring_source.gd`, `spring_water.gdshader` e `tools/add_spring.gd`. O construtor da região incorpora a nascente, e o acabamento posterior evita recolocar plantas sobre ela. Backup anterior: `docs/backups/before_spring_20261026/`.

Validação atual: **51 verificações da região + 43 do menu, zero falhas**. Foram realizadas 2.106 consultas com a cápsula do jogador, incluindo entrada bloqueada no lago, margem livre, acesso desde o spawn, interação E e preservação das trilhas e amizades. Captura real em 1280×720: `clareira_spring.png`.

### Correção da origem da água

Após a revisão do usuário, a cachoeira alta isolada foi removida da composição. O sprite original permanece no acervo. A nascente agora é baixa: um pequeno filete sai de uma fenda escura entre pedras com musgo e deságua diretamente no lago. As pedras usam o sprite original `stone.png` em escalas inteiras, com samambaia, grama e uma mancha de terra úmida na base. Isso estabelece uma origem subterrânea visível sem exigir uma cachoeira sem relevo ou um rio fora do mapa.

O filete possui animação própria em `spring_trickle.gdshader`, também interrompida pela preferência de reduzir animações. A colisão da formação rochosa foi ajustada ao novo conjunto baixo; o acesso, a interação E e as trilhas foram preservados. As duas suítes passaram novamente, totalizando 94 verificações sem falhas. A captura `clareira_spring.png` foi atualizada. Backup antes da correção: `docs/backups/before_grounded_spring_20261026/`. Nenhuma geração paga foi necessária.

### Versão atual — somente o lago

Atendendo à revisão seguinte do usuário, foram removidos o conjunto `RockSpring` inteiro (pedras, fenda, filete e colisão), a espuma de queda, a mancha de terra da nascente e as pedras decorativas adicionais da margem. Permanecem a água animada, sua colisão, a margem e vegetação baixa. O shader de filete e os sprites originais foram preservados no acervo, sem uso no lago atual.

A interação agora mostra **Examinar lago**, com descrição de água cristalina, sem alegar uma nascente visível. O construtor também aplica essa versão simples em futuras execuções. Backup: `docs/backups/before_pond_only_20261026/`. A captura `clareira_spring.png` mostra a versão atual. Os testes verificam explicitamente a ausência da formação e de sua colisão invisível, além da água bloqueada e da margem acessível.
