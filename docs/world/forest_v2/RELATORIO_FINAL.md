# Floresta do Despertar v2 — entrega local

Projeto: `C:\Slimekeepers_Lost_Valley_v0_1`. Godot 4.7.2, GDScript, GL Compatibility. O botão **Novo Jogo** inicia `scenes/regions/FlorestaDoDespertarV2.tscn`. O menu existente continua sendo a cena principal.

A floresta agora possui **200×200 tiles reais de 32 px**, cobrindo **6.400×6.400 px**, sem ampliar o personagem ou mudar o zoom 1.14. O núcleo efetivo da cena editada foi deslocado em 1.600 px e cercado por novas trilhas, bosques e micro-locais. Há quatro habitats com oito Brotinhos, oito lugares observáveis, vento discreto, borboletas, folhas, sombras ocasionais de aves e áudio próprio. A conexão sul com o Vale das Nascentes está funcional nos dois sentidos.

## Preservação e restauração

- Checkpoint restaurável: `docs/backups/before_forest_v2_20261027.zip`, 89.896.483 bytes. A integridade de todas as entradas do ZIP foi verificada.
- Os **183 PNGs originais** são byte-idênticos aos do checkpoint.
- `scenes/world.tscn`, `scenes/regions/ClareiraDoDespertar.tscn` e `scenes/player.tscn` permanecem byte-idênticos. A nova cena é adicional.
- O teste compara pintura original de GroundDetails/VegetationLow com as células transladadas e verifica todos os overrides de visibilidade das árvores.
- Dentro da cópia ampliada, 177 props foram reposicionados para abrir novas conexões, com as sombras correspondentes acompanhando. Lago e marco receberam ajustes locais para liberar o centro. O lago continua sem a formação de nascente rejeitada.
- Nenhum commit, push ou geração paga. Auditoria completa: `preservation_audit.json`. Para restaurar, extraia o checkpoint em outra pasta e abra o `project.godot` dessa cópia; o cache `.godot` será reconstruído.

## Espaços e população

| Elemento | Coordenada global | Função |
|---|---:|---|
| PlayerSpawn | 3200, 3200 | Clareira segura |
| H01 — Jardim das Folhas | 4480, 3270 | Dois slimes, primeiro encontro |
| H02 — Círculo Musgoso | 1980, 2120 | Dois slimes, desvio oeste/noroeste |
| H03 — Campo dos Brotos | 3350, 4580 | Dois slimes, sul intermediário |
| H04 — Bosque Silencioso | 4880, 1700 | Dois slimes, nordeste |
| Mirante Rochoso | 5110, 1260 | Platô, barranco e escada transitável |
| Passagem Úmida | 3220, 5680 | Pequena lagoa e pistas da região seguinte |
| Saída sul | 3220, 6280 | E para viajar ao Vale |
| Retorno do Vale | 3220, 6140 | Chegada afastada do gatilho de saída |

Há ainda Bosque dos Cogumelos, Árvore Centenária, Tronco do Tempo e Jardim Escondido. As três rotas anteriores mantêm o traçado do núcleo e ganham extensões e laços. Paredes do mirante bloqueiam; a escada deixa passagem real. O Mapa 01 continua predominantemente florestal e sem boss.

A exclusão de spawn tem raio de 960 px, acrescido do raio da cápsula ao validar criaturas. O gerenciador verifica terreno, colisões, distância entre slimes e enquadramento inicial/atual. Cooldown de 20 s, limite global de 10, população atual de 8. IDs por habitat/slot preservam amizade na recriação e impedem duplicação. O movimento usa colisão real, interesse por flores, curiosidade e recuo moderado; a IA distante suspende decisões. Amizade permanece um estado de sessão, sem sistema de save ou seguidor inventado.

## Água e vida ambiental

O Vale recebeu leito mineral separado, profundidade costeira, filme transparente, plantas submersas, pequenos cardumes e espuma fragmentada nas três cascatas. Rochas laterais integram as quedas ao barranco. As cinco pontes e colisões foram mantidas. Detalhes em `../vale/WATER_POLISH.md`.

Na floresta, um controlador central a 8 Hz mantém até quatro borboletas, oito folhas e uma sombra de ave. Flores e copas usam material compartilhado com fases espaciais; troncos e colisões não se movem. Sombras de aves são restritas a áreas abertas e têm intervalo de 25–60 s. Efeitos complexos consultam apenas buckets próximos da câmera. A opção **Reduzir movimento ambiental** mantém a cena legível.

O áudio procedural tem vento, água posicional e três cantos curtos, sintetizados em pequenos lotes com cache. Não há gravações de terceiros. Volume e mute foram adicionados às opções. Origem e limitações em `AUDIO.md`; inventário visual em `ASSETS.md`.

## Verificação executada

| Suíte | Resultado |
|---|---:|
| Clareira original | 59 verificações, 0 falhas; 1.972 amostras físicas |
| Floresta v2 | 150 verificações, 0 falhas; 2.317 amostras físicas |
| Habitats isolados | 37 verificações, 0 falhas |
| Ambiente headless | 16 verificações, 0 falhas |
| Áudio PCM/controle | 16 verificações, 0 falhas |
| Vale/navegação | 41 verificações, 0 falhas; 2.096 amostras físicas |
| Ecossistema aquático | 20 verificações, 0 falhas |
| Viagem entre regiões | 9 verificações, 0 falhas |
| Menu/teclado/controle/mouse/amizades | 57 verificações, 0 falhas |
| GdUnit4 | 7 testes, 0 falhas/erros/skips/orphans |
| Ambiente nativo OpenGL | 19 verificações, 0 falhas, incluindo comparação de pixels do shader |

Total da suíte principal: **405 verificações**, mais os **7 testes GdUnit4**. A validação nativa adicional confirma copa animada, tronco pixel-idêntico e preservação de cor. Logs ficam nesta pasta; GdUnit gera relatórios em `reports/`.

Comando repetível: `tools/validate_forest.ps1`. Captura: `Godot --path C:\Slimekeepers_Lost_Valley_v0_1 --script res://tools/capture_forest_v2.gd -- spawn` (ou east, mushrooms, old_tree, hills, garden, south, overview).

Problemas encontrados e corrigidos durante a validação:

- Filhos duplicados da cena instanciada do jogador ao empacotar: preservar ownership interno eliminou nós/RIDs órfãos.
- Espaço inicial ocupado pela borda do lago: pequeno ajuste do lago e marco na nova cópia.
- Contador de amizade dependente de eventos de spawn: agora conta IDs persistentes, inclusive após respawn.
- Título da zona permanecia anterior quando havia slime próximo: atualização antecede a interação.
- HUD quebrava uma contagem em linha isolada: texto compacto cabe no painel.
- Árvore no interior da lagoa sul: relocada para solo seco; teste protege ambas as lagoas contra troncos submersos.
- Água sul usava coordenadas globais no shader: passou a usar coordenadas locais e raio próprio, recuperando profundidade e ondulações.

## Percurso e desempenho real

`tools/explore_forest_v2.gd` executou **300 segundos reais de exploração**, mais 12 s de comparação de efeitos. Usa as ações de Input e o controlador original a 145 px/s; AStarGrid amostrado na física planeja o caminho. **Nenhum teleporte, 14 destinos alcançados, zero travamentos.** Incluiu os quatro habitats, micro-locais, chegada sul e saídas norte/leste. Evidências em `exploration.log` e `performance.json`.

Medição nativa em 1280×720, Radeon RX 580, GL Compatibility, descartando os três primeiros segundos das estatísticas de FPS:

- Carregamento até a cena estabilizar: **1.468 ms**.
- FPS observado: **121–181**, mediana **162**.
- Memória estática reportada pelo Godot: pico **151,3 MiB** (não é a memória total do processo/GPU).
- Até **24.249 nós** e **636 draw calls** no percurso.
- Ambiente observado: máximo de quatro borboletas, cinco folhas e uma sombra de ave; quatro eventos de ave no percurso.
- Panorama a 1600×1600/zoom0.25 é uma captura de inspeção que desenha o mapa inteiro; registrou cerca de 20 FPS. Não representa a câmera de gameplay.

Essa medição longa precedeu apenas o último ajuste local da lagoa (relocação de troncos/remoção de plantas sobre água); após esse ajuste, navegação completa, regressões e captura sul foram repetidas. A comparação curta ligado/desligado não demonstrou ganho confiável de FPS: 836 versus 765 frames em janelas de cinco segundos. Não se afirma melhoria de FPS por desativar efeitos com base nesses dados. Os testes verificam que a animação deixa de avançar e que os limites de efeitos são respeitados.

## Estado das 28 etapas

| Etapa | Estado / evidência |
|---:|---|
| 1 Auditoria | Concluída: versão, arquitetura, input, cenas, grid e dependências |
| 2 Backup | Concluída: ZIP íntegro e auditoria de preservação |
| 3 Assets | Concluída: ASSETS.md, nenhuma geração paga |
| 4 Planejamento | Concluída: forest_layout.gd e plano Superpowers |
| 5 Expansão | Concluída: 40.000 células reais, núcleo preservado |
| 6 Terreno/caminhos | Concluída: extensões e laços navegáveis |
| 7 Primeira validação | Concluída: cápsula física nas rotas |
| 8 Massas arbóreas | Concluída: núcleo e anel externo com densidade variável |
| 9 Botânica | Concluída: arbustos, gramíneas, samambaias e fungos |
| 10 Flores | Concluída: quatro famílias de cor, 187 âncoras florais |
| 11 Micro-locais | Concluída: oito recantos observáveis |
| 12 Relevo/sul | Concluída: platô com escada e lagoa discreta |
| 13 Colisões/Y-sort | Concluída: testes físicos e capturas |
| 14 Vento | Concluída: shader compartilhado, troncos estáveis |
| 15 Flores ao vento | Concluída: grupos selecionados com fase espacial |
| 16 Borboletas | Concluída: voo/pouso/culling, máximo4 |
| 17 Aves | Concluída: sombras raras, somente áreas abertas |
| 18 Folhas | Concluída: fontes em árvores, orçamento8 |
| 19 Áudio | Implementado e testado tecnicamente; escuta subjetiva pendente |
| 20 Validação ambiental | Concluída: simulação de10min, render nativo e percurso real |
| 21 Exclusão | Concluída: raio30tiles, câmera e colisões |
| 22 Habitats | Concluída: quatro áreas, oito indivíduos |
| 23 Comportamento/população | Concluída: IA pacífica, limites, IDs, cooldown e amizade |
| 24 Conexão Mapa02 | Concluída: ida/volta por E e estado preservado |
| 25 Testes/documentação | Concluída: suíte, métricas, capturas e relatório |
| 26 Primeiro contato | Alternativa automatizada concluída; observação de jogador humano pendente |
| 27 Ritmo de descoberta | Parcial: distância/exclusão validadas; alvo humano de1–3min ainda não comprovado |
| 28 Polimento final | Concluído no escopo local: correções derivadas de capturas e testes |

## Limitações e próximos ajustes

O primeiro slime entrou no enquadramento após **7,962 s** e o primeiro habitat foi alcançado em **11,617 s**, incluindo pausa inicial de2s. O GDD combina percurso sugerido de35–55tiles com alvo de1–3min de exploração voluntária; à velocidade atual, não são tempos equivalentes. Não foi imposto atraso, labirinto artificial ou redução de velocidade. A distância funciona tecnicamente, mas o ritmo precisa de teste humano e eventual ajuste de trilha/habitat.

Áudio sintético está integrado e tecnicamente válido; ainda cabe escuta para julgar timbre e volume. Amizades/recantos são preservados entre regiões na mesma sessão, não em disco. Não foram adicionados combate, coleta, fazenda, pesca ou seguidores.

O teste isolado de áudio com driver headless emite um aviso de dois objetos de playback ao encerrar a simulação acelerada. O mesmo teste foi repetido com áudio/renderização nativos: 16 verificações passaram sem esse aviso. O percurso nativo de cinco minutos também encerrou sem erros ou vazamentos reportados. Essa diferença está registrada nos logs, sem ocultar o aviso headless.

Godot MCP está instalado como addon, mas não havia ferramentas conectadas no chat; validação ocorreu pela CLI nativa. Graphify retornou workspaces vazios. OmniRoute não estava disponível. Caveman foi inspecionado como estilo de comunicação. Subtarefas usaram GPT-6 Astra; não houve alegação de troca do modelo principal. O diretório não contém checkout Git, portanto não houve publicação de GitHub Actions; o runner PowerShell permite repetir a validação local.

## Capturas

- Antes: `before_spawn.png`.
- Depois: `after_spawn.png`, `after_east.png`, `after_mushrooms.png`, `after_old_tree.png`, `after_hills.png`, `after_garden.png`, `after_south.png` (1280×720).
- Visão geral: `after_overview.png` (1600×1600).
- Água: `../vale/vale_springs.png`, `../vale/vale_bridge.png`, `../vale/vale_overview.png`.

Lista completa de fontes novas/alteradas: `preservation_audit.json`. Arquitetura principal em `scripts/world/forest_{layout,region,habitats,slime,life,audio}.gd`, `forest_wind.gdshader`; builder em `tools/build_forest_v2.gd`. Pontos de entrada atualizados em `scripts/menu/start_menu.gd` e `scripts/world/region_travel.gd`.
