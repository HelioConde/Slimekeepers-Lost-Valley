---
name: skill-authoring
description: "Criar skills Claude Code pequenas e sob demanda para rotinas comprovadamente repetidas."
---

# Skill Authoring — Slimekeepers
Use só quando um procedimento recorrente ainda não tiver skill local ou `godot-prompter:*` adequado.
1. Colete três pedidos reais, problemas observados e critério de sucesso.
2. Crie `.claude/skills/<nome>/SKILL.md` com nome curto e descrição precisa de quando carregar; evite termos genéricos.
3. Deixe o corpo pequeno, com passos e armadilhas; mova explicações extensas a referências lidas sob demanda.
4. Prefira Markdown. Não adicione hooks, Bash, `curl | sh`, pip/npx ou chamadas pagas sem revisão/consentimento.
5. Teste dois pedidos que ativam e dois que não ativam; se falhar, use `skill-description-tuning`.
6. Registre fontes/licenças e restrições Godot, PixelLab e segurança.
Cada nova descrição também ocupa contexto — evite duplicatas.
Adaptação de https://claudeskills.page/skills/claude-code/skill-authoring/ (MIT).
