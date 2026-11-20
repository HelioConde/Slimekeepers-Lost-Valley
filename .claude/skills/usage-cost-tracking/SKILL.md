---
name: usage-cost-tracking
description: "Medir consumo e custo do Claude Code e comparar tarefas equivalentes antes e depois."
---

# Usage & Cost Tracking — Slimekeepers
Use ao investigar consumo ou validar otimização; esta skill não reduz tokens sozinha.
1. Leia `/usage` e `/context` se disponíveis. Anote modelo, esforço, versão, tarefa e uso de subagentes.
2. Para um teste controlado manual, use `claude -p "<tarefa somente leitura>" --output-format json > reports/claude-usage/antes.json` e repita tarefa equivalente após ajuste.
3. Analise `python tools/claude_token_usage.py <arquivo.json>`; compare com `--before A.json --after B.json`.
4. Some input, output e cache; compare também custo USD, qualidade e número total de subagentes.
5. Outputs originais podem conter conteúdo privado: mantenha-os apenas em `reports/claude-usage/`, que é ignorado. Não os envie para GitHub/Actions.
6. Não mude o proxy Astra/Codex ou quotas remotas sem estudo próprio. Limites CLI como `--max-turns` podem interromper tarefas.
Sem medidas comparáveis, registre SEM EVIDÊNCIA DE ECONOMIA.
Adaptação de https://claudeskills.page/skills/claude-code/usage-cost-tracking/ (MIT).
