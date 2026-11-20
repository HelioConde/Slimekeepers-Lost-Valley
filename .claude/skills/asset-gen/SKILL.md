---
name: asset-gen
description: "Planejar assets de jogo (arte, áudio, FX) para Slimekeepers com proveniência, orçamento e integração Godot; sem instalar geradores externos."
---

# Asset Generator — modo seguro para Slimekeepers

Esta skill é complementar à `pixellab` e ao inventário de `assets/`. O upstream `htdt/godogen` usa GPU local, modelos e APIs pagas; **essas dependências não estão instaladas** por esta configuração. Não alegue que comandos `qwen-image`, `gen3d` ou `stable-audio` estão disponíveis sem verificar.

## Fluxo
1. Leia `CLAUDE.md`, `docs/ASSET_MANIFEST.md` e `docs/PIXELLAB_INTEGRACAO.md`.
2. Identifique a lacuna real: sprite, tile, efeito, interface, áudio ou modelo 3D. O jogo é 2D; não recomende modelos 3D sem necessidade.
3. Para pixel art, use `pixellab` quando o MCP estiver conectado. Para áudio/FX, descreva a ferramenta necessária e os custos antes de instalar qualquer gerador externo.
4. Defina dimensões, paleta, formato (PNG com alfa, OGG/WAV, etc.), licença, nome estável, origem, destino e integração no Godot.
5. Registre hashes, versões e revisão humana antes de trocar assets. Não exponha URLs privadas, tokens, prompts sensíveis ou ZIPs.
6. Se o backend não estiver configurado, entregue especificação e checklist; não execute downloads ou instalação automática.

Inspirada em `htdt/godogen/asset-gen`, commit `40542b6c8efbdc40112c2b004fbaa6d67141846d`, licença MIT. Esta skill local não inclui scripts ou dependências do upstream.

