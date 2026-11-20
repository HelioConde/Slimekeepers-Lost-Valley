---
name: pixellab
description: "Planejar e produzir pixel art para Slimekeepers pelo servidor oficial PixelLab MCP, com controle de custo, revisão visual e importação Godot."
---

# PixelLab MCP — Slimekeepers

Use esta skill para sprites, personagens, animações, props e tilesets quando o projeto realmente precisar de arte nova. A integração oficial é o servidor HTTP `pixellab` em `.mcp.json`. A existência do arquivo não comprova autenticação; confirme no `/mcp`.

## Preparação
1. Leia `CLAUDE.md`, `docs/PIXELLAB_INTEGRACAO.md`, `docs/ASSET_MANIFEST.md` e os assets existentes. Para personagens/história, consulte a Bíblia Narrativa.
2. Se as ferramentas MCP PixelLab não estiverem disponíveis, pare e informe como configurar `PIXELLAB_API_TOKEN` localmente. **Não substitua o MCP por curl ou chamadas REST sem autorização.**
3. Consulte inventário, jobs já iniciados e saldo/custo antes de uma geração. A autorização geral de produção visual consta da documentação, mas não autoriza desperdício ou reprocessamento duplicado.
4. Para arte de personagem, preserve identidade, escala, perspectiva `low top-down`, paleta e direções necessárias. Para slimes de corpo não humano, avalie `template_id=custom` e as limitações de animação documentadas no MCP.
5. Registre pedido, parâmetros não sigilosos, custo estimado, job, status, tamanho e arquivo de destino em relatório de assets; evite IDs privados e URLs de download em documentos públicos.

## Execução e revisão
- A criação é assíncrona: uma solicitação retorna um job. Use a ferramenta `get_*` correspondente até completar e inspecione o resultado.
- Se houver timeout, HTTP 429 ou resposta ambígua, **não repita um POST**: consulte primeiro o job/histórico.
- Verifique transparência, pixel grid, silhueta, 8 direções quando necessário, proporções, frames e consistência visual.
- Baixe para diretório local ignorado `output/pixellab/` quando o material não estiver aprovado; não publique ZIPs nem IDs privados no GitHub Actions.
- Integre sprites aprovados em `assets/` e cenas Godot somente em uma mudança separada, com testes/inspeção visual. Nunca substitua arte existente silenciosamente.
- Não imprima o token ou valores de variáveis de ambiente. Não inclua credenciais em arquivos ou logs.

Referência oficial: https://api.pixellab.ai/mcp/docs. Esta skill é uma integração local, não código do PixelLab.

