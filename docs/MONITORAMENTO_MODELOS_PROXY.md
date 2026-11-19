# Monitoramento dos modelos do Codex Proxy — Slimekeepers

O Slimekeepers monitora os modelos do proxy periodicamente via GitHub Actions, sem alterar o jogo.

## Agenda e relatórios
- Diariamente às **11h43, 15h25 e 17h43**, horário de Brasília (UTC−3), sujeito a atrasos do GitHub Actions.
- Workflow: https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/workflows/slimekeepers-model-watch.yml
- Dados saneados por execução em artifacts (14 dias).

## Como funciona
1. Inicializa o proxy autorizado e espera 20 segundos pela atualização do catálogo.
2. Consulta somente GET /health, GET /v1/models e GET /admin/accounts/{id}/usage.
3. Registra a lista de modelos, quota principal/secundária, atualização e disponibilidade.
4. Prioriza **gpt-6.2-astra**; **gpt-6-astra** é reserva quando o principal não está no catálogo.
5. Quando a quota estiver comprovadamente disponível, o workflow agendado tenta criar uma única branch de reserva **ai/proxy-model-smoke-once**, antes da inferência.
6. Se conseguir reservar, faz exatamente um POST mínimo de texto e nunca repete o POST automaticamente, mesmo se falhar ou não for possível comprovar sucesso. Após a primeira reserva, as execuções seguintes continuam somente com GET.

A branch de reserva é propositalmente um checkpoint: não deve ser apagada sem avaliar os logs e o histórico do teste. O modelo listado não equivale a capacidade garantida de inferência. A chamada mínima de texto pode consumir cota.

## Privacidade
Não registra e-mails, IDs de contas, tokens, prompts, corpos de resposta brutos ou credenciais. Relatórios de leitura contêm somente dados saneados. O container e a cópia temporária da sessão são descartados ao final.

## Controle
Desabilite o workflow no GitHub Actions para pausar todos os testes. Para acompanhar apenas GET sem permitir a primeira tentativa de smoke, reserve manualmente a branch ai/proxy-model-smoke-once antes de ativar a agenda.

**Limitação:** o monitor diagnostica modelos e quota; não modifica Godot nem implementa o jogo. Para isso, usar separadamente a fila de desenvolvimento do Slimekeepers e revisar PRs.

## Feedback no proprio GitHub Actions

Cada execucao agora apresenta no **Summary** uma tabela de modelos: identificado no catalogo, GET individual, inferencia verificada ou ainda nao testada. O resumo tambem indica o consumo das janelas de cota e horarios de reset retornados pelo servico, sem publicar dados de autenticacao. A checagem das 15h25 foi adicionada para observar a janela depois da redefinicao inicialmente informada para 15h14; o reset nao significa que toda a quota necessariamente sera liberada.
