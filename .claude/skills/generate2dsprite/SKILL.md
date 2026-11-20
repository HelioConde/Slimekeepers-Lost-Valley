---
name: generate2dsprite
description: "Planejar sprites, sheets e animações 2D do Slimekeepers com arte existente ou PixelLab MCP e exportação Godot SpriteFrames."
---

# Generate 2D Sprite — adaptação Godot + PixelLab

Objetivo: produzir um conjunto de sprites utilizável no Godot, não apenas uma imagem bonita. Esta versão **não** instala os scripts upstream, pois a versão pesquisada depende de outras skills (`generate2dmedia`/`video2dsprite`), modelos e APIs não configurados no repositório.

## Procedimento
1. Inspecione a cena e os sprites existentes. Consulte `CLAUDE.md`, `docs/ASSET_MANIFEST.md` e `docs/PIXELLAB_INTEGRACAO.md`.
2. Defina personagem/objeto, função no jogo, tamanho em pixels, orientação top-down, direções, animações e pivô. Para movimento de personagem, planeje 8 direções; para objetos estáticos, não invente animações.
3. Prefira reaproveitar PNGs aprovados. Para novos assets, use a skill `pixellab` e suas ferramentas MCP **somente se estiverem conectadas**.
4. Revise a imagem mestre antes de derivar direções/frames. Registre origem, tamanho, transparência, paleta, duração e ordenação dos quadros.
5. Entregue frames/spritesheets com metadados de tamanho e pivô, prontos para `SpriteFrames`/`AnimatedSprite2D`; preserve os originais e use filtro Nearest.
6. Faça revisão visual em escala real, verifique cortes e oscilação entre quadros. Integre em uma cena/teste sem sobrescrever assets aprovados.
7. Se faltar ferramenta de geração, entregue um plano/contrato de asset e indique a dependência. Nunca afirme que a arte foi gerada sem arquivo real.

Base conceitual: 0x0funky/agent-sprite-forge, `skills/generate2dsprite`, commit `5324342fdfab72430f4e9604f3fe427009f8596d`, MIT. Esta é uma adaptação local sem execução dos scripts originais.

