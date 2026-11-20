# Slimekeepers: Lost Valley — sprint Fase 2 (meta de 10 horas)

**Fila oficial proposta:** [`automation/phase2_10h_queue.json`](../automation/phase2_10h_queue.json)  
**Discussão e objetivo jogável:** [Issue #39](https://github.com/HelioConde/Slimekeepers-Lost-Valley/issues/39)  
**Engine:** Godot 4.7.2 | **IA:** `gpt-6.2-astra` (principal) e `gpt-6-astra` (reserva segundo o preflight)

## Escopo e estimativa

| Ordem | Etapa | Tarefas | Minutos |
|---|---|---:|---:|
| 01 | Auditoria e automação segura | 5 | 110 |
| 02 | Inventário e culinária jogável | 7 | 160 |
| 03 | Alimentação e vínculo com slimes | 5 | 110 |
| 04 | Cultivo, progresso e sessão | 5 | 110 |
| 05 | PixelLab e consistência visual | 4 | 70 |
| 06 | UX, regressão e entrega | 4 | 40 |
| **Total** | **30 tarefas** | **30** | **600 = 10 h** |

As estimativas representam blocos de trabalho e validação, **não uma garantia de 10 horas reais de computador, crédito ou inferência contínua**. O tempo pode aumentar por QA, código do projeto, bloqueios de cota, análise humana ou recursos externos.

## Como esta fila funciona

Esta é a fila de integração da **Fase 2** e não substitui a fila de nove módulos já concluída. A nova automação `slimekeepers-phase2.yml` a consome com guard de patches e revisão independente; a fila antiga continua isolada.

As **cinco primeiras tarefas** preparam o inventário de integração, contrato dos sistemas, guard de patches, CI sem segredos e baseline de gameplay. Só depois de validar esse mecanismo a fila pode ser conectada ao proxy para tarefas que alteram cenas/scripts existentes. Os campos `candidate_paths` são **caminhos propostos para revisão**, e não uma autorização genérica de escrita. Cada execução deverá fixar explicitamente seu escopo e SHA da branch-base antes de gerar código.

A fila registra `depends_on`, `acceptance`, `estimated_minutes`, `execution_mode` e `status` para cada item. Uma tarefa termina somente com evidência de código/testes reais, PR e aprovação de QA ou relatório honesto de impedimento. Não tratar branch, Action verde ou chamada de IA isolada como prova de funcionalidade jogável.

## Resultado esperado em tela

Jogador coleta ingredientes reais na Floresta do Despertar, viaja ao Vale das Nascentes, interage com o ponto de culinária, recebe feedback de ingredientes disponíveis/faltantes, prepara uma refeição com débito atômico da bolsa e consegue prosseguir sem quebrar coleta, cultivo ou transições. A oferta de alimento aos slimes será integrada sem sobrescrever o sistema original de amizade e sem criar informação narrativa canônica.

A parte PixelLab começa pelo inventário dos PNGs existentes (Brotinho, Gelito, Brasinha, Musguinho, Bolhinha, jogador, tilesets e objetos). Somente gerar ou animar itens realmente ausentes; documentar job, deduplicação, crédito/saldo quando disponível, checksums, transparência e revisão visual. A autorização foi registrada em `docs/PIXELLAB_INTEGRACAO.md`, mas o workflow atual não implementa POST pago de geração.

## Controle de execução

- Manter verificação de quota/GET, uma tentativa por tarefa e checkpoint remoto para não repetir gastos.
- Preservar a Bíblia Narrativa, cenas e sprites aprovados, salvo PR específica e revisada.
- O código gerado pelo proxy deve ser executado somente em runner separado, **sem credenciais**, com Godot 4.7.2, GdUnit4 e regressões nativas.
- A automação atual do GitHub executa apenas duas verificações agendadas por dia (09h35/18h35 BRT); **não** promete terminar esta fila em 10 horas corridas. A nova fila exigirá agendamento/orquestrador próprios antes de produção autônoma de patches.
- Avançar tarefas dependentes só depois de validar suas predecessoras. Gerar relatório por PR/run, sem afirmar conclusão por mera criação de tarefa.

## Atualização: executor fase 2 controlado (PR #42)

O workflow [`slimekeepers-phase2.yml`](../.github/workflows/slimekeepers-phase2.yml) agora executa **uma tarefa da Fase 2 por rodada** quando a quota permitir. Escolhe tarefas por dependências realmente integradas à `main`, reserva `p2/<id>` antes de qualquer POST, usa `gpt-6.2-astra` (fallback somente pelo catálogo) e **não repete uma inferência ambígua**. O trabalho ocorre em `docs/phase2/` (auditoria) ou em pequenos patches com substituição literal, no máximo dois scripts/cenas reais + suite GdUnit4.

Um segundo runner **sem credenciais** confere base SHA, diff, escopo, Godot 4.7.2, GdUnit4 e regressões. O repositório ainda impede que `GITHUB_TOKEN` crie Pull Requests; a branch e os testes são preservados e uma PR pode ser aberta pela integração GitHub do ChatGPT. Por segurança **não há merge automático de cenas/scripts nesta Fase 2**. A automação não avança dependências até o merge.

As tarefas `p2-scoped-change-guard` e `p2-native-ci-guard` estão concluídas pela própria infraestrutura da PR #42. As tarefas de geração PixelLab permanecem intencionalmente bloqueadas até existir controle real de créditos, deduplicação e QA visual. O cron tenta a cada ~20 minutos, mas a fila de **600 minutos estimados** não tem conclusão garantida em 10 horas corridas.

## Entregas manuais durante bloqueio de quota Astra

- [PR #44 — ciclo de culinária jogável](https://github.com/HelioConde/Slimekeepers-Lost-Valley/pull/44): auditoria, inventário transacional, estação de preparo (E), uma receita provisória, HUD, Novo Jogo e testes.
- [PR #45 — alimentação dos slimes](https://github.com/HelioConde/Slimekeepers-Lost-Valley/pull/45): porções consumíveis, oferta com F a slimes amigos, registro por identidade, sem duplicação ou efeito narrativo definitivo.
- [PR #46 — colheitas e crescimento](https://github.com/HelioConde/Slimekeepers-Lost-Valley/pull/46): controle de colheita por canteiro, registro de ciclo, tempo contínuo através da meia-noite e testes Godot.

**Proteção anti-retrabalho:** o executor da Fase 2 deve reconhecer as tarefas `completed` da fila `automation/phase2_10h_queue.json` somente quando houver `evidence` referenciando a PR já integrada à `main`. As tarefas não validadas ou de arte continuam abertas. A cota do proxy é independente das entregas manuais e continua sujeita ao preflight.
