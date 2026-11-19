# Reutilizar a sessão Codex Proxy do VideoForge no Slimekeepers

Este projeto contém o script `tools/importar_sessao_videoforge.ps1`, adaptado do
`scripts/migrar-codex-proxy.ps1` de
[VideoForge-IA](https://github.com/HelioConde/VideoForge-IA).
Ele configura apenas **Slimekeepers-Lost-Valley**, sem modificar o VideoForge.

## 1. Pré-requisitos

- Windows PowerShell 5.1 ou superior, [GitHub CLI](https://cli.github.com/) autenticado com `gh auth login`.
- Uma sessão OAuth **válida e autorizada** do Codex Proxy guardada em contêiner Docker local
  (com `/app/data/accounts.json`) ou em um backup local **privado** do mesmo arquivo.
- Nunca enviar `accounts.json`, `access_token`, `refresh_token` ou chave de proxy
  para GitHub público, comentário, chat, artifact ou commit.

## 2. Executar a migração no seu computador

Abra PowerShell na pasta do projeto Slimekeepers e execute:

```powershell
gh auth status
.\tools\importar_sessao_videoforge.ps1
```

O comando detecta um contêiner de proxy em execução. Se houver mais de um:

```powershell
.\tools\importar_sessao_videoforge.ps1 -Container chatgpt-codex-proxy
```

Se tiver somente um backup privado:

```powershell
.\tools\importar_sessao_videoforge.ps1 -ArquivoContas 'C:\privado\accounts.json'
```

O script verifica o estado e gera uma **nova chave de autenticação aleatória** exclusiva
do Slimekeepers. Ele cadastra automaticamente dois GitHub Actions Secrets via `gh`:

- `CODEX_PROXY_ACCOUNTS_JSON`: snapshot privado autorizado.
- `CODEX_PROXY_API_KEY`: chave nova do proxy efêmero Slimekeepers.

A nova chave **não é o mesmo valor** usado no VideoForge; ambos podem autenticar
seus próprios proxies efêmeros usando uma sessão autorizada. Os Secrets do VideoForge
**não são lidos nem alterados**.

## 3. Validar sem executar modelo

Depois de salvar os Secrets, abra
[Slimekeepers - Codex Proxy Astra 6.2](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/workflows/slimekeepers-astra-proxy.yml).

Execute `operation=verify` e `confirmation=NO_INFERENCE`.
O workflow consulta apenas `GET /health` e `GET /v1/models`, selecionando
`gpt-6.2-astra` se constar do catálogo (senão `gpt-6-astra`).
Não gera imagens, texto ou mudanças no jogo.

## 4. Limitações importantes

- Se a sessão válida existir **somente** em Secrets antigos do GitHub, não é possível
  recuperar seus valores pela interface/API. Será preciso reautorizar uma sessão
  em infraestrutura própria ou localizar backup privado válido.
- O snapshot do Actions pode expirar; prefira proxy persistente privado com HTTPS
  para tarefas contínuas. No modo persistente, configure a chave da instância em
  `CODEX_PROXY_API_KEY` e seu endereço em `CODEX_PROXY_BASE_URL`. Não use a
  chave aleatória gerada pelo script para autenticar um servidor persistente
  já existente, a menos que ela também tenha sido configurada no servidor.
- A imagem GHCR do VideoForge deve ser acessível ao repositório Slimekeepers;
  se privada, autorize o repositório em *Manage Actions access* do pacote.
- Trata-se de um proxy de terceiros para uma interface não oficial. Respeite
  condições de uso, limites da conta e os mecanismos oficiais de autenticação.
