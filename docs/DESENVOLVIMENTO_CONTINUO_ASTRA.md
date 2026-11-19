# Agente de desenvolvimento do jogo — Codex Proxy Astra

**Jogo-alvo:** Slimekeepers: Lost Valley (Godot 4.7.2).

## Ordem de modelos

1. **Principal:** \`gpt-6.2-astra\`.
2. **Reserva:** \`gpt-6-astra\`, *somente quando o modelo principal estiver ausente do catálogo autenticado*. A checagem é \`GET /health\` + \`GET /v1/models\` **antes** do POST.

O nome do modelo é o identificador do proxy VideoForge, não um produto garantido da API oficial. No teste autenticado de 19/11/2026, o proxy listou 10 modelos, **não listou \`gpt-6.2-astra\`** e selecionou o fallback. A preferência continua em 6.2; não substituímos silenciosamente a política.

## Objetivo

Transformar chamadas de texto isoladas em **entregas de desenvolvimento**: uma tarefa da fila, código GDScript, testes GdUnit4 e **uma PR no GitHub**. Sem alterar cenas, sprites, modelos 3D, arte aprovada, Bíblia Narrativa, projeto Godot, workflows ou Secrets.

## Arquivos principais

- \`automation/dev_tasks.json\`: fila de tarefas com metas, contexto, critérios e caminhos **exatos** permitidos.
- \`tools/slimekeepers_dev_agent.py\`: seleciona a tarefa, extrai contexto, solicita JSON e valida a lista de arquivos antes de gravar.
- \`tools/slimekeepers_codex_proxy.py\`: cliente existente de Responses; uma chamada única sem repetição.
- \`.github/workflows/slimekeepers-ai-dev.yml\`: workflow de desenvolvimento.
- \`tests/test_slimekeepers_dev_agent.py\`: testes offline de escopo, fila, proteção e geração simulada.

A primeira fila contém três fundamentos, **não** alterações no mapa: inventário, regras de alimentos/vínculo e livro básico de receitas. Esses componentes entram como **propostas** até passarem no Godot; integrá-los às cenas e ao ciclo do jogador é outra etapa.

## Testar sem gastar inferência

Abra [Slimekeepers - Agente de desenvolvimento Godot via Astra](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/workflows/slimekeepers-ai-dev.yml).

Escolha \`mode=plan\`, \`task_id=auto\`, \`confirmation=NO_INFERENCE\`. O workflow exibe os itens e roda testes offline. Nenhum token do proxy é exigido no modo plan.

## Criar uma PR com uma tarefa real

Execute o mesmo workflow na branch \`main\` com:

- \`mode=develop\`
- \`task_id=auto\` (ou um ID explícito da fila)
- \`confirmation=AUTHORIZE_ONE_DEV_TASK\`

O workflow verifica as credenciais já instaladas, **reserva uma branch remota \`ai/<task-id>\` antes de chamar o modelo**, consulta o catálogo, executa **um único** POST de texto e gera os arquivos estritamente permitidos. Se a saída for válida, publica uma branch e tenta abrir PR contra \`main\`.

**Esse modo pode consumir cota de IA.** Caso a sessão expirada, timeout, erro HTTP, JSON inválido ou falha de PR impeça a conclusão, **não repetimos o POST automaticamente**. A branch de reserva permanece para auditoria e impede gerar de novo silenciosamente. Se precisar recuperar, avalie os logs da Action e a branch primeiro; não a apague sem saber se houve inferência.

As respostas do modelo não podem instruir o workflow a executar comandos ou ler Secrets. O job **não executa GDScript gerado**. A PR informa que a validação real no Godot/GdUnit4 está pendente e exige revisão antes do merge. Se as permissões de Actions não permitirem criar PR, poderá ser necessária configuração em *Settings → Actions → General → Allow GitHub Actions to create and approve pull requests*. A branch fica preservada se essa etapa falhar.

## Continuidade recorrente (opt-in, inicialmente DESLIGADA)

O workflow define uma agenda de **segunda e quinta-feira às 13:17 UTC**. Esse horário não gera nenhuma inferência por padrão. Para habilitar, o dono precisa criar a **variável de repositório** (não Secret) \`SLIMEKEEPERS_AUTO_DEV_ENABLED=true\` em *Settings → Secrets and variables → Actions → Variables*.

Quando habilitada, a Action seleciona **a primeira tarefa sem branch reservada**. Há no máximo **uma tarefa e uma chamada de inferência por execução agendada**; os resultados seguem como PRs para revisão. Ao terminar a fila, não há novas chamadas. Para pausar, defina \`SLIMEKEEPERS_AUTO_DEV_ENABLED=false\` ou remova a variável.

**Antes de habilitar recorrência**, execute um desenvolvimento manual e revise o código/qualidade produzido. As cotas e políticas da sessão ChatGPT usada por este proxy não oficial podem mudar. Não assuma que a chamada é gratuita; nenhum preço foi inferido ou garantido.

## Feedback e critérios de conclusão

- Action executada e modelo usado: logs e relatório JSON sanitizado;
- tarefa feita e arquivos alterados: branch \`ai/<id>\` e PR;
- QA: testes de orquestração offline e \`git diff --check\` automáticos; Godot/GdUnit4 é validação separada;
- estado de produção: **não integrado** até que a PR seja testada e aprovada.

Não usar \`git pull --allow-unrelated-histories\` ou reset forçado no computador local para puxar essas mudanças. Preservar arquivos Roblox locais, \`.env\`, assets e modelos 3D. Resolver o histórico Git divergente separadamente.
