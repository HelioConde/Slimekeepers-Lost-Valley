# Claude Code: skills e PixelLab — Slimekeepers: Lost Valley

Configuração do projeto para **Godot 4.7.2 / GDScript**. Nenhum arquivo de gameplay ou sprite é alterado por esta integração. A configuração fica no repositório; **a autenticação PixelLab permanece no computador do desenvolvedor**.

## Inventário configurado

| Recurso | Caminho / origem | Estado e observações |
| --- | --- | --- |
| `godot-prompter` | Plugin `godot-prompter@claude-community` | Declarado em `.claude/settings.json`; Claude Code pode solicitar confiança e instalação. Inclui hook `SessionStart` do fornecedor. |
| `godot-specialist` | `.claude/agents/godot-specialist.md` | Agente local adaptado, sem Bash nem delegação. |
| `godot-gdscript-specialist` | `.claude/agents/godot-gdscript-specialist.md` | Agente local adaptado, sem Bash. |
| `generate2dsprite` | `.claude/skills/generate2dsprite/SKILL.md` | Skill local funcional para planejar, revisar e integrar arte; gera por PixelLab MCP quando disponível. |
| `generate2dmap` | `.claude/skills/generate2dmap/SKILL.md` | Skill local para mapas Godot/TileMapLayer; não roda scripts externos. |
| `asset-gen` | `.claude/skills/asset-gen/SKILL.md` | Skill de planejamento e integração; stack GPU/áudio upstream não foi instalada. |
| `balance-check` | `.claude/skills/balance-check/SKILL.md` | Skill local sem o hook shell de configuração do upstream. |
| `systematic-debugging` | `.claude/skills/systematic-debugging/SKILL.md` | Skill local de diagnóstico por evidência, sem shell. |
| `pixellab` | `.claude/skills/pixellab/SKILL.md` + `.mcp.json` | Servidor oficial MCP HTTP, exige token de ambiente e aprovação local. |

As skills locais são **adaptações de escopo** dos projetos pesquisados, não cópias completas. Isso evita instalar centenas de KB de scripts, geradores de mídia, dependências pagas e hooks que não fazem parte do Godot atual. Elas aparecem como skills de projeto no Claude Code após carregar a pasta. O `godot-prompter` é um plugin de terceiros separado.

## Origens e versões examinadas

| Recurso | Origem fixada para referência | Licença |
| --- | --- | --- |
| GodotPrompter | https://github.com/jame581/GodotPrompter/tree/3dfd9425569f7a067f4a99e6d0bd74c1a2d90a8f | MIT |
| Agentes Godot e balance-check | https://github.com/Donchitos/Claude-Code-Game-Studios/tree/05ad7c8a5b8aa2aa86bbd3439ae7cf7295cac41846d | MIT |
| generate2dmap | https://github.com/0x0funky/agent-sprite-forge/tree/64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2 | MIT |
| generate2dsprite | https://github.com/0x0funky/agent-sprite-forge/tree/5324342fdfab72430f4e9604f3fe427009f8596d | MIT |
| asset-gen | https://github.com/htdt/godogen/tree/40542b6c8efbdc40112c2b004fbaa6d67141846d | MIT |
| systematic-debugging | https://github.com/obra/superpowers/tree/bb92a77741419a4ab5f06e711a283343f1ada0c3 | MIT |

O marketplace `anthropics/claude-plugins-community` referenciava o GodotPrompter no commit acima em 20/11/2026. A fonte do marketplace pode mudar: **revise atualizações antes de aceitá-las**. O plugin contém um hook `SessionStart` que, na versão examinada, lê `project.godot` e seu estado local e imprime contexto, sem rede ou escrita no projeto. A presença de um hook shell exige confiança no fornecedor; se preferir não executá-lo, desative `godot-prompter@claude-community` em `.claude/settings.json` e mantenha os agentes/skills locais.

## Ativar no computador

1. Clone/atualize este repositório e abra o terminal na raiz que contém `project.godot`.
2. Abra `claude`. Revise e aprove a confiança na pasta, o marketplace/plugin e o servidor MCP quando solicitados. Não use flags para ignorar permissões.
3. Confira `/plugin` e `/agents`; as skills locais ficam em `.claude/skills/`. Para o plugin, consulte `claude plugin list` no terminal. Se não for instalado automaticamente, dentro do Claude Code use:
   - `/plugin marketplace add anthropics/claude-plugins-community`
   - `/plugin install godot-prompter@claude-community`
4. Para PixelLab, obtenha o token **diretamente** em https://api.pixellab.ai/mcp e configure `PIXELLAB_API_TOKEN` no ambiente do processo `claude`, não em arquivo versionado. Não cole tokens em chat, PR, issue ou workflow.
5. Execute `claude mcp list` no terminal ou `/mcp` dentro do Claude Code. Confirme que `pixellab` está conectado. Se faltar token, o servidor pode falhar na autenticação; isso é esperado até configurar a variável.

### Token local no PowerShell (não grava em arquivo)

Execute **somente no seu computador**, antes de iniciar `claude`:

```powershell
$secret = Read-Host "Token PixelLab" -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
try {
    $env:PIXELLAB_API_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}
claude
```

A variável fica no ambiente do processo e de seus filhos; não é gravada no Git. Ao terminar a sessão, feche o terminal ou execute `Remove-Item Env:PIXELLAB_API_TOKEN`. Nunca faça `echo`, `printenv` ou `git add` com o token. Prefira o gerenciador de segredos do seu sistema se tiver um.

## Segurança e custos

- O repositório é público. `.mcp.json` contém somente `Bearer` com **referência a variável**, nunca um token.
- `.gitignore` já exclui `.env` e `output/pixellab/`; também ignora `.claude/settings.local.json` e `.mcp.local.json`.
- `.claude/settings.json` nega leituras diretas de `.env` e configurações locais; não substitui cuidado com Bash ou programas externos.
- Não há `hooks` novos no projeto. Skills locais são instruções Markdown, sem execução automática, `curl | bash` ou `pip install`.
- O plugin de terceiros contém hook próprio. A configuração pode exigir aprovação do usuário no primeiro uso.
- O PixelLab cobra conforme o modelo/operação. Consulte saldo e jobs antes de gerar. Não reenvie POST após timeout/429 sem verificar o estado.
- Links de download PixelLab e IDs podem dar acesso a assets. Não os inclua em logs públicos ou artefatos de Actions.
- Preserve a integração **já existente** `tools/pixellab_bridge.py`, `docs/PIXELLAB_INTEGRACAO.md` e `.github/workflows/pixellab-connection.yml`. Ela é independente do MCP do Claude Code e continua read-only para o workflow.
- Esta alteração não verifica token, saldo, conexão real, execução do Godot ou instalação do plugin no computador.

## Exemplos de uso no Claude Code

- `Use godot-specialist para revisar a arquitetura da Floresta do Despertar V2 sem modificar cenas ainda.`
- `Use godot-gdscript-specialist para revisar scripts de coleta e preservar sinais e testes.`
- `Use generate2dsprite e pixellab para planejar uma nova animação do Brotinho; confira assets existentes e saldo antes de gerar.`
- `Use generate2dmap para adicionar um pequeno ponto de interesse sem refazer o mapa existente.`
- `Use balance-check para comparar o ciclo de cultivo de 120 minutos com os valores do código e testes.`
- `Use systematic-debugging: ao voltar do Vale para a Floresta, a transição falha. Encontre a causa raiz antes de editar.`

Referências de configuração: https://code.claude.com/docs/en/mcp e https://api.pixellab.ai/mcp/docs.

