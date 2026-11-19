# Codex Proxy Astra no Slimekeepers: Lost Valley

**Origem técnica:** [VideoForge-IA](https://github.com/HelioConde/VideoForge-IA), arquivos
'./orchestrator/proxy_preflight.py', './orchestrator/providers.py',
'.github/workflows/agent-proxy-preflight.yml' e a imagem Docker compilada fixada.

## O que foi implementado

- Preflight autenticado **somente GET** em '/health' e '/v1/models'.
- Preferência pelo ID **gpt-6.2-astra**, com fallback para **gpt-6-astra** apenas se o primeiro não constar no catálogo, antes de qualquer POST.
- Cliente reutilizável em 'tools/slimekeepers_codex_proxy.py' que faz **um único** POST '/v1/responses', sem repetição em 429, timeout ou resultado inconclusivo.
- Workflow GitHub Actions com testes offline em PR/push, operação manual 'verify' (sem inferência) e 'ping' (uma inferência de texto com autorização explícita).
- Não altera as cenas Godot, não cria imagem, não publica conteúdo do jogo, não executa ferramentas na resposta da IA e não altera a Bíblia Narrativa.
- Relatórios resumidos sem prompt, respostas completas, tokens OAuth, IDs privados ou URL do servidor.

**Atenção:** 'gpt-6.2-astra' é o **nome fornecido pelo proxy usado no VideoForge**, não uma confirmação de que um modelo oficial da API OpenAI com esse nome exista. A implementação verifica disponibilidade na instância autenticada. Esse proxy é um projeto de terceiros, utiliza interfaces não oficiais do ChatGPT/Codex e pode deixar de funcionar ou depender das condições de uso do serviço.

## Credenciais necessárias no próprio repositório Slimekeepers

Configurar em [Settings → Secrets and variables → Actions](https://github.com/HelioConde/Slimekeepers-Lost-Valley/settings/secrets/actions):

| Secret | Necessário | Finalidade |
| --- | --- | --- |
| 'CODEX_PROXY_API_KEY' | Sim | Bearer utilizado pelo serviço proxy. É diferente de 'PIXELLAB_API_TOKEN'. |
| 'CODEX_PROXY_BASE_URL' | Se houver proxy persistente | URL HTTPS do proxy já em execução; não use URL pública sem autenticação. |
| 'CODEX_PROXY_ACCOUNTS_JSON' | Se não houver URL persistente | Snapshot autorizado de sessão no formato 'records' do VideoForge. É montado temporariamente no runner; nunca é versionado. |

É necessário **a chave e pelo menos uma das duas opções** (URL persistente ou snapshot). Se ambas estiverem presentes, o workflow prefere a URL persistente. Segredos do VideoForge **não são compartilhados automaticamente** entre repositórios GitHub; não há API de leitura para copiá-los em texto. Não compartilhe valores em issues, commits ou conversa.

### Dependência GHCR

O modo efêmero reutiliza:
'ghcr.io/helioconde/videoforge-codex-proxy:upstream-02f8ce3581c1'.

A imagem está fixada para evitar atualizações inesperadas. O token 'GITHUB_TOKEN' do Slimekeepers precisa de permissão de leitura do package GHCR. Se o pacote for privado, conceda acesso de leitura ao repositório Slimekeepers em *Package settings → Manage Actions access*, ou utilize proxy HTTPS persistente existente. Este workflow **não recompila** a imagem e não cria uma sessão OAuth por conta própria.

## Procedimento

1. Faça o merge desta PR na 'main' depois de verificar os testes.
2. Configure os Secrets conforme acima.
3. Abra [Actions — Slimekeepers Codex Proxy Astra 6.2](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/workflows/slimekeepers-astra-proxy.yml).
4. Execute 'Run workflow' com **operation=verify** e **confirmation=NO_INFERENCE**. O preflight reportará o modelo selecionado, se houver autenticação.
5. Para testar geração de texto uma única vez, escolha **operation=ping** e digite 'AUTHORIZE_ONE_ASTRA_TEXT_CALL'. Esse teste gera uma resposta curta e pode consumir cota do serviço. Nunca repita um run incerto sem confirmar seu resultado.
6. Confira os artifacts de 7 dias. Um ping aprovado retornará 'status=verified', modelo reportado, uso de tokens quando disponível e 'response_contract_verified=true'.

### CLI local (somente em infraestrutura autorizada)

Com 'CODEX_PROXY_API_KEY' e 'CODEX_PROXY_BASE_URL' previamente exportados no ambiente:

~~~bash
python -m unittest discover -s tests -p 'test_slimekeepers_codex_proxy.py' -v
python tools/proxy_preflight.py --output /tmp/slimekeepers-preflight.json --prefer-model gpt-6.2-astra --fallback-model gpt-6-astra
~~~

Para a inferência manual, a operação exige explicitamente 'AI_ENABLED=true', 'PAID_CALLS_ENABLED=true' e 'CODEX_PROXY_TEXT_AUTHORIZED=true', além do arquivo de preflight. Não habilite essas flags em workflows automáticos.

## Próxima etapa

Quando 'verify' e 'ping' estiverem aprovados, criaremos agentes específicos para o desenvolvimento do Slimekeepers (auditoria de gameplay, roteiro/continuidade e revisão de sprites). Cada tarefa deverá produzir uma proposta revisável, nunca alterar arquivos ou sprites existentes silenciosamente. Preserve os eventos canônicos da Bíblia Narrativa.
