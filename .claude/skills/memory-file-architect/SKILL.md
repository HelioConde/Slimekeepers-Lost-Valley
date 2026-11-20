---
name: memory-file-architect
description: "Auditar CLAUDE.md e manter instruções persistentes pequenas e corretas."
---

# CLAUDE.md Architect — Slimekeepers
Use quando a memória estiver longa, duplicada, errada ou consumindo contexto.
1. Conte linhas de `CLAUDE.md`, confira links/comandos contra o repositório real, identifique imports longos e regras redundantes.
2. Preserve só o que todo agente precisa: versão Godot, cenas, segurança, restrições narrativas e caminhos para testes.
3. Mova instruções extensas para skills/docs carregados sob demanda; evite `@import` de relatórios grandes.
4. Não elimine proteção de secrets, narrativa ou decisões aprovadas em nome de tokens.
5. Mostre diff e riscos; avalie o custo inicial com `/context` antes e depois em novas sessões equivalentes.
A redução de linhas não prova, sozinha, uma economia de tokens.
Adaptação de https://claudeskills.page/skills/claude-code/memory-file-architect/ (MIT).
