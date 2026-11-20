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

Esta é uma fila **de planejamento de integração (Fase 2)**; não é a fila inicial esgotada `automation/dev_tasks.json`. O workflow atual `slimekeepers-ai-dev.yml` ainda lê somente a fila inicial e limita as entregas automáticas a **arquivos novos**, por isso não pode executar diretamente mudanças em scripts/cenas já existentes.

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
