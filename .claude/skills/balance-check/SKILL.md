---
name: balance-check
description: "Auditar dados reais de progressão, coleta, cultivo, combate e economia do Slimekeepers sem inventar valores."
argument-hint: "[sistema ou caminho de arquivo]"
---

# Balance Check — Slimekeepers

Analise apenas dados observados no código, Resources, tabelas, testes e documentação vigente. O upstream possui uma expansão de shell para configuração de estúdio; **ela foi removida** nesta adaptação.

## Procedimento
1. Identifique o domínio solicitado: amizade, coleta, cultivo, inventário, economia, combate ou progressão.
2. Liste fontes reais encontradas/ausentes. Inspecione `scripts/`, `tests/`, `docs/gameplay/`, `PLANO_DE_DESENVOLVIMENTO.md` e a Bíblia Narrativa quando necessário.
3. Extraia constantes, fórmulas, tempos, limites e taxas dos arquivos atuais. Por exemplo, o README descreve um ciclo de cultivo de 120 minutos do jogo; confirme no código antes de tratá-lo como regra técnica.
4. Monte cenários de borda, tabelas e cálculos reproduzíveis. Procure estratégias dominantes, progressão impossível, exploits e estados sem saída.
5. Separe `CONFIRMADO`, `HIPÓTESE` e `NÃO AVALIADO — SEM DADOS`. Sem dados, não declare aprovação.
6. Sugira ajustes mínimos, com trade-offs e testes de regressão. Não altere a economia nem a narrativa sem autorização.

Base: Donchitos/Claude-Code-Game-Studios, `balance-check`, commit `05ad7c8a5b8aa2aa86bbd3439ae7cf7295cac41846d`, MIT. Adaptação sem hooks, execução de shell ou estrutura `design/registry` ausente no projeto.

