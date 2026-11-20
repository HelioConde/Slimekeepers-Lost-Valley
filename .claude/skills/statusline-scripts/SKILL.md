---
name: statusline-scripts
description: "Exibir opcionalmente modelo, porcentagem do contexto e custo da sessão Claude Code."
---

# Status Line Scripts — Slimekeepers
Monitoramento opcional, não economia automática.
1. `tools/claude_statusline.py` recebe JSON via stdin e lê só modelo, % de contexto e custo da sessão.
2. Script não usa rede, não lê tokens, não abre arquivos e não grava logs.
3. Ative se o usuário quiser, em `.claude/settings.local.json` (nunca no settings compartilhado), com `statusLine.type=command` apontando para Python e caminho absoluto do script.
4. Teste com JSON fictício; confirme na interface `/statusline`. Não alegue custo zero se o campo não vier.
5. Não ative hooks ou instaladores externos para esta função.
Adaptação de https://claudeskills.page/skills/claude-code/statusline-scripts/ (MIT).
