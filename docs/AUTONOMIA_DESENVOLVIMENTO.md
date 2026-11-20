# Desenvolvimento autonomo do Slimekeepers

Configurado com autorizacao do criador em **19 de novembro de 2026**. O workflow principal fica em `.github/workflows/slimekeepers-ai-dev.yml`.

## Frequencia e limites

- **Todos os dias, 09h35 e 18h35** (horario de Brasilia; GitHub Actions pode atrasar ou omitir disparos agendados).
- **Uma unica tarefa** por execucao e, no maximo, **uma requisicao de inferencia de texto** por tarefa, sem repeticao automatica apos HTTP 429, timeout, JSON invalido ou problema de codigo.
- Fila versionada em `automation/dev_tasks.json`; inicialmente contem **9 tarefas finitas**. A ordem inicia por base de culinaria, regras de alimento/vinculo e inventario generico.
- O sistema nao cria novas tarefas infinitas, nao altera arte, mapa, historia, cenas, arquivos existentes nem publica o jogo.
- Quando nao houver tarefa nova ou quota disponivel, nao faz inferencia nem reserva branch. A proxima execucao agendada tentara novamente a tarefa ainda nao reservada.

## Como o fluxo avanca sem acompanhamento humano

1. Executa testes offline do orquestrador, seleciona a primeira tarefa cujo checkpoint remoto `ai/<id>` nao exista.
2. Inicia o proxy autenticado, espera atualizar a lista de modelos, consulta **GET /v1/models** e a **cota real da conta por GET**.
3. Se a cota estiver liberada, reserva a branch remota `ai/<id>` ANTES do primeiro POST. Se a quota estiver bloqueada, **nenhuma branch e criada**, evitando perder a tarefa.
4. Pede um componente novo a `gpt-6.2-astra` (fallback `gpt-6-astra` apenas quando ausente no catalogo).
5. Aceita apenas arquivos novos no escopo `scripts/systems/` e `tests/forest/`. Arquivos de cena, ativos, scripts anteriores, segredos e configuracao nao podem ser alterados.
6. Cria PR com detalhes tecnicos e um artifact contendo o relato da chamada, sem dados pessoais ou credenciais.
7. Em **outro runner**, sem os secrets do proxy, compara o diff com a tarefa autorizada, bloqueia instrucoes arriscadas, importa os arquivos com **Godot 4.7.2 oficial e checksum publicado**, executa os testes **GdUnit4 da tarefa** e as **329 verificacoes nativas existentes**.
8. Se tudo passar e as regras do repositorio permitirem, integra **somente esses modulos isolados** por merge squash. Se a protecao do GitHub impedir o merge, deixa a PR aberta. Se a validacao falhar, mantem a PR/branch e seus logs, sem merge.
9. Nao apaga a branch checkpoint, evitando reexecutar a mesma inferencia nas proximas janelas de agenda.

## Limites do que significa evolucao autonoma

O desenvolvimento automatico, por seguranca, cria componentes de regras e testes isolados. **Eles nao ficam automaticamente conectados a cenas ou mecânicas existentes.** Integrar uma receita jogavel, mudar o mapa, introduzir personagem, mexer em sprites, ou publicar versoes ainda exige um trabalho especifico e validacao. Testes automatizados nao substituem inspecao visual.

## Relatorios e controle

- [Actions — Agente de desenvolvimento via Astra](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/workflows/slimekeepers-ai-dev.yml)
- [Pull requests](https://github.com/HelioConde/Slimekeepers-Lost-Valley/pulls)
- Each run: `unit-tests`, `develop-one-task` (quota/modelo), `validate-generated` (testes no Godot), `merge-validated-module` (quando aprovado)
- Artifacts guardados de **7 a 14 dias**.

**Pausar sem modificar scripts:** GitHub → Settings → Secrets and variables → Actions → Variables → criar ou alterar `SLIMEKEEPERS_AUTO_DEV_PAUSED=true`. Alterar para `false` ou excluir reativa a agenda. Tambem e possivel desabilitar o workflow pela guia Actions. Manter `CODEX_PROXY_API_KEY` e `CODEX_PROXY_BASE_URL` ou `CODEX_PROXY_ACCOUNTS_JSON` como secrets; nunca colocar valores na fila, logs ou arquivos.

## Falhas nao recuperadas automaticamente

- Conta/cota bloqueada: nao gasta inferencia, retenta a leitura na proxima agenda.
- Modelos ausentes: preflight falha sem POST.
- Resultado gerado invalido, HTTP 429, timeout ou falha na criacao da PR: checkpoint permanece; exigir diagnostico antes de recuperar a tarefa.
- GdUnit/Gameplay reprovados: manter PR sem integrar e continuar pelas demais tarefas.
- Permissao de criar PR ou merge bloqueada por configuracoes GitHub: nao contorna as restricoes; verificar permissoes de Actions (`contents:write`, `pull-requests:write`), protecoes de branch e configuracao do `GITHUB_TOKEN`.
- Fila esgotada: encerra com status `no_unreserved_tasks`, sem inferencia.

## Planejamento da Fase 2 — 10 horas

A fila inicial de 9 módulos foi concluída. O novo planejamento de **30 tarefas e 600 minutos estimados** está em [`automation/phase2_10h_queue.json`](../automation/phase2_10h_queue.json), detalhado em [`FASE2_SPRINT_10H.md`](FASE2_SPRINT_10H.md) e associado à [Issue #39](https://github.com/HelioConde/Slimekeepers-Lost-Valley/issues/39).

**Atenção:** o arquivo novo **ainda não é lido pelo executor** e não libera edição automática de scripts ou cenas existentes. Primeiro são necessários guard de patch e CI independentes, com escopos estritos por tarefa. Manter os agendamentos atuais até o novo executor ser validado. A meta de dez horas é **estimativa de esforço, não tempo de execução garantido**; a programação atual de duas rodadas por dia não consome esta fila automaticamente.
