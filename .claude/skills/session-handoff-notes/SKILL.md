---
name: session-handoff-notes
description: "Salvar handoff curto para retomar Slimekeepers sem reler toda a sessão Claude Code."
---

# Session Handoff Notes — Slimekeepers
Use antes de mudar/limpar sessão ou ao deixar tarefa longa incompleta.
1. Confirme branch, `git status`, commits/PRs e testes realmente executados; quando inacessíveis, marque não verificado.
2. Escreva uma nota em `.claude/local-handoffs/<topico>.md` (ignorada no Git) contendo: objetivo, branch, arquivos alterados, CONFIRMADO, PENDENTE, erro ou bloqueio, decisões e próximo comando exato.
3. Não copie transcrições, logs completos, segredos, URLs privadas PixelLab ou IDs privados.
4. Na retomada, valide a nota contra o estado atual do Git; não a trate como verdade imutável.
5. Crie uma nota por trabalho incompleto; não gere notas para cada interação.
Adaptação de https://claudeskills.page/skills/claude-code/session-handoff-notes/ (MIT).
