# SDD ledger — plan: docs/superpowers/plans/2026-10-27-forest-v2.md

2026-10-27. Checkpoint: `docs/backups/before_forest_v2_20261027.zip` (89.896.483 bytes, sem cache .godot nem backups recursivos). GDD de 20 páginas lido integralmente. Projeto usa 100×100 tiles de 32 px; controlador 145 px/s, sprint 220 px/s, zoom 1.14.

Etapas 1–4 concluídas: auditoria, plano e backup. Núcleo original possui overrides de usuário na cena herdada; a expansão partiu da instância final de `world.tscn`, preservando essa fonte.

Pre-flight: contratos do plano conferidos: novas coordenadas globais; interfaces de habitats e ambiente independentes; viagem por ID estável. Mapa 02 recebe polimento de água em frente independente, preservando física.

Ferramentas: GdUnit4 e Godot MCP instalados no projeto. Godot MCP sem ferramentas conectadas nesta sessão; CLI nativa disponível. Graphify respondeu workspaces=[]; nenhum grafo utilizável. Sem ferramenta OmniRoute. Caveman inspecionado: somente compressão de linguagem. Subagentes GPT-6 Astra acionados para ambiente, habitats e água. Tentativa anterior de outro agente falhou por quota; frentes atuais responderam.

Ruling: criar cena v2 adicional e alterar pontos de entrada — evita regravar cenas originais e preserva integralmente o núcleo editado. Custo: testes do legado e da versão nova serão distintos.

Ruling: respeitar raio/percursos mensuráveis e não prometer 1–3 min de descoberta humana. A velocidade atual atravessa 35–55 tiles em 8–12 s; percurso automatizado com paradas será identificado como tal.

## Implementação e evidências

- Task expansão: teste RED inicial falhou por cena inexistente. Nova cena construída com 40.000 células e 2.876 objetos adicionais de mata (árvores, pedras e troncos). As 943 árvores originais continuam presentes; 177 props do núcleo copiado foram reposicionados para liberar os novos corredores, com sombras acompanhando o deslocamento. Cenas-fonte preservadas.
- Ruling: manter propriedade interna das cenas instanciadas durante empacotamento. A primeira versão achatava os filhos do Player e deixava três nós duplicados órfãos; diagnóstico `--verbose` identificou CollisionShape/AnimatedSprite/Camera. O builder agora preserva a fronteira de propriedade do PackedScene; integração e transição terminaram sem esse vazamento.
- Ruling: deslocar ligeiramente lago (+120,-40) e marco (-60,-20) dentro da nova cópia para ampliar o espaço livre de spawn. O lago continua sem a nascente rejeitada; núcleo reconhecível e originais intactos.
- Task navegação: 150 verificações / 0 falhas, incluindo 2.317 amostras da cápsula física, preservação de pintura/visibilidade, troncos fora da água e espaço central livre 256×256. Mirante usa tiles de barranco e passagem real sem colisão na escada.
- Task habitats: 37 verificações isoladas e 7 testes GdUnit4 passaram. Quatro habitats com oito Brotinhos, raio de exclusão 960+cápsula, cooldown20s, teto10, IDs por habitat/slot.
- Task amizade: teste adicional revelou contador dependente de eventos. Corrigido para contar IDs persistentes; teste de respawn confirma uma amizade, nunca duplicada.
- Task ambiente: módulo visual passou 16 verificações headless / 19 nativas, incluindo comparação pixel a pixel de tronco imóvel/copa animada e 10 minutos simulados. Borboletas≤4, folhas≤8 e sombra≤1, vinculadas à câmera e a fontes vegetais.
- Task áudio: síntese própria incremental implementada, 16 verificações técnicas passaram. Opções do menu oferecem volume/mute. Não há gravação de terceiros.
- Task menu: teste RED confirmou destino antigo; integração atual 57 verificações / 0 falhas, teclado/controle/mouse, novo mundo, oito amizades, retorno, foco modal e preferências preservadas.
- Task viagem: 9 verificações / 0 falhas, chegada sul atualizada, amizade por ID e oito indivíduos após ida/volta.
- Os subagentes de áudio e água foram interrompidos por quota após gravarem os arquivos. A raiz assumiu revisão, integração e validação final; não se considera o estado do agente prova de conclusão.
- Percurso nativo concluído: 300 segundos mais comparação de efeitos; Input real, AStar amostrado na física, 14 destinos, nenhum teleporte ou travamento. FPS121–181/mediana162; memória estática pico151,3MiB; carga1468ms. Comparação curta de efeitos inconclusiva para ganho de FPS, registrada sem omissão.
- Polimento visual final: árvore dentro da lagoa sul relocada para margem; plantas em água removidas; shader da lagoa usa coordenadas locais/raio. Nova regressão protegendo troncos em solo seco passou. O teste isolado de áudio headless ainda emite aviso de dois objetos de playback ao encerrar; resultados funcionais passam. Não confundir ausência de falhas com ausência desse aviso.
- Task validação final: 405 verificações principais +7 GdUnit4 passaram; 19 verificações nativas de shader/ambiente passaram. Checkpoint íntegro, 183 PNGs originais e três cenas-fonte byte-idênticos.
- Estado final: implementação local concluída; etapas26/27 exigem julgamento humano de descoberta. Primeiro slime visível7,962s no percurso direto; alvo voluntário1–3min não comprovado. Escuta subjetiva do áudio pendente. Ver RELATORIO_FINAL.md para as28etapas, evidências e limitações.
