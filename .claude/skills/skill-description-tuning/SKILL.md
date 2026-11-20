---
name: skill-description-tuning
description: "Corrigir skills que ativam incorretamente, deixam de ativar ou competem entre si."
---

# Skill Description Tuning — Slimekeepers
Use quando roteamento falhar, como `generate2dmap` em animação ou `asset-gen` em toda conversa.
1. Selecione a skill e vizinhas que podem competir.
2. Monte 5 pedidos positivos, 5 negativos e 2 ambíguos baseados no uso real.
3. Ajuste só o frontmatter `description`; o corpo não influencia a descoberta inicial.
4. Valide em sessões novas quando possível. Não rode dezenas de sessões pagas sem verificar custo e autorização.
5. Registre falsos positivos, erros e regressões; restaure se a mudança piorar o conjunto.
6. Não altere configurações PixelLab/GodotPrompter apenas para mudar um gatilho.
Adaptação de https://claudeskills.page/skills/claude-code/skill-description-tuning/ (MIT).
