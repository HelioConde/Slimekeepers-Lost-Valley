---
name: context-window-hygiene
description: "Gerenciar contexto quando sessão Claude Code fica longa, repetitiva ou consome tokens demais."
---

# Context Window Hygiene — Slimekeepers
Use só quando houver sinais de contexto excessivo ou mudança de assunto; não rode limpezas a cada resposta.
1. Verifique `/context` e determine se o maior consumo é de mensagens, memória, skills ou MCP.
2. Procure símbolos/caminhos com Glob/Grep e leia intervalos relevantes, em vez de arquivos Godot, JSON de sprites ou logs inteiros.
3. Ao continuar a mesma tarefa, registre objetivo, branch, decisões e próximo teste via `session-handoff-notes` antes de usar `/compact`.
4. Para tema novo use `/clear` só depois do handoff; `/rewind` pode corrigir desvios recentes.
5. Use subagentes para buscas volumosas somente se a economia provável justificar o custo total adicional.
6. Não remova o GodotPrompter ou PixelLab MCP silenciosamente. Compare custos e peça aprovação.
**Critério de sucesso:** recuperar o trabalho com apenas o checkpoint, sem reabrir o repositório inteiro.
Adaptação de https://claudeskills.page/skills/claude-code/context-window-hygiene/ (MIT), sem scripts externos.
