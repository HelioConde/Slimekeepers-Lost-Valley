---
name: subagent-design
description: "Projetar subagentes enxutos para isolar logs e buscas sem desperdiçar tokens totais."
---

# Subagent Design — Slimekeepers
Use para criar ou revisar agentes, não para toda tarefa simples. Subagentes têm seu próprio custo.
1. Prefira o Explore integrado ou os agentes locais `godot-specialist` / `godot-gdscript-specialist` se suficientes.
2. Se precisar de agente novo, descreva missão, arquivos, limite de turnos, modelo apropriado e ferramentas mínimas; para investigação, `Read, Glob, Grep` sem Bash, Edit ou PixelLab.
3. Entregue contexto autocontido (pergunta, caminhos e evidências) sem colar o repositório inteiro.
4. Limite a resposta a 12 linhas: CONFIRMADO com arquivo:linha, NÃO CONFIRMADO, risco e próximo passo; nunca logs completos.
5. Compare tokens totais, incluindo subagentes. Não automatize agente que não demonstre benefício.
6. Proíba mudanças de cenas, APIs pagas e publicação de assets em agentes apenas investigadores.
Adaptação de https://claudeskills.page/skills/claude-code/subagent-design/ (MIT).
