# Economia de tokens — Claude Code no Slimekeepers

**Escopo:** orientações e scripts locais do Claude Code. Esta instalação **não altera o proxy Astra/Codex, o Godot, o PixelLab MCP ou workflows GitHub Actions**. Nenhuma economia percentual pode ser afirmada sem medições.

## Skills instaladas

| Skill | Propósito |
| --- | --- |
| `context-window-hygiene` | Evitar crescimento de contexto, decidir entre `/compact`, `/clear`, `/rewind` |
| `session-handoff-notes` | Guardar checkpoint mínimo ao mudar de sessão |
| `memory-file-architect` | Manter `CLAUDE.md` enxuto e sem imports extensos |
| `subagent-design` | Restringir contexto/ferramentas de agentes para buscas ruidosas |
| `usage-cost-tracking` | Comparar consumo real antes e depois |
| `skill-authoring` | Escrever skills pequenas, carregadas quando necessárias |
| `skill-description-tuning` | Evitar ativação desnecessária e conflitos de skills |
| `statusline-scripts` | Exibir opcionalmente modelo, contexto e custo (monitoramento apenas) |

São **adaptações em Markdown**, não cópias completas dos projetos originais. Não executam shell, hooks, instaladores, pip, npm, scripts de terceiros nem chamadas pagas. As próprias descrições carregadas pelo Claude têm custo fixo: não adicione skills redundantes.

## Medir corretamente

A partir de uma cópia confiável do repositório no seu computador, usando Claude Code autenticado:

```powershell
New-Item -ItemType Directory -Force reports/claude-usage | Out-Null
claude -p "Leia scripts/systems/game_clock.gd e resuma a lógica em cinco linhas, sem editar." --output-format json > reports/claude-usage/antes.json
python tools/claude_token_usage.py reports/claude-usage/antes.json
```

Repita tarefa **equivalente** depois de aplicar a otimização, preservando versão do código, modelo, esforço e condições comparáveis, salvando `depois.json`:

```powershell
python tools/claude_token_usage.py --before reports/claude-usage/antes.json --after reports/claude-usage/depois.json
python -m unittest discover -s tests -p "test_claude_token_usage.py" -v
```

O parser analisa **somente** eventos `type=result`; extrai tokens de entrada, saída, cache lido, cache criado e custo USD, quando presentes. Para arquivos sem evento compatível, falha em vez de inventar números. Mede categorias de token separadas e as soma na comparação (cache tem preço diferente; compare custo também).

**Segurança:** o JSON bruto do Claude pode conter textos privados, prompts e código. Nunca o envie ao GitHub/Actions. `reports/claude-usage/` e `.claude/local-handoffs/` estão ignorados pelo Git. Não registre segredos, links de download PixelLab ou transcrições em handoffs. O script local não faz chamadas de rede e não imprime conteúdo textual do JSON.

O `/usage`, `/context`, `/compact`, `/clear` e `/rewind` são ferramentas nativas do Claude Code. Uma skill orienta quando usá-las, não as substitui. Subagentes podem **aumentar** o custo total. Não altere limites do proxy Astra ou remova PixelLab/GodotPrompter alegando otimização sem medição.

### Status line opcional

O script `tools/claude_statusline.py` lê JSON do stdin e mostra modelo, percentual do contexto e custo; **não é habilitado automaticamente** porque depende de Python no computador. Caso deseje, no arquivo local não versionado `.claude/settings.local.json` configure `statusLine.type=command` e `statusLine.command` apontando para `python C:/CAMINHO/Slimekeepers-Lost-Valley/tools/claude_statusline.py`. Teste em `/statusline`. O script não lê secrets nem gera tráfego.

## Referências

- https://claudeskills.page/skills/claude-code/context-window-hygiene/
- https://claudeskills.page/skills/claude-code/session-handoff-notes/
- https://claudeskills.page/skills/claude-code/subagent-design/
- https://claudeskills.page/skills/claude-code/memory-file-architect/
- https://claudeskills.page/skills/claude-code/usage-cost-tracking/
- https://claudeskills.page/skills/claude-code/skill-authoring/
- https://claudeskills.page/skills/claude-code/skill-description-tuning/
- https://claudeskills.page/skills/claude-code/statusline-scripts/
- Documentação oficial: https://code.claude.com/docs/en/skills , https://code.claude.com/docs/en/headless e https://code.claude.com/docs/en/statusline

A pesquisa de origem não conseguiu abrir diretamente `plado.pages.dev`; estas fontes públicas foram verificadas em 20/11/2026. Essas skills são novas no repositório, mas não foram executadas na máquina do desenvolvedor; a medição real depende dessa máquina.
