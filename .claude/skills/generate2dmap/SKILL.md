---
name: generate2dmap
description: "Planejar e integrar mapas top-down editáveis com TileMapLayer, colisões, zonas e props no Godot 4.7 do Slimekeepers."
---

# Generate 2D Map — adaptação Godot

O Slimekeepers já tem mapas jogáveis. **Não gere um mapa novo nem substitua a Floresta v2 por padrão.** Trabalhe primeiro na cena existente e no pedido específico do usuário.

## Procedimento
1. Leia `CLAUDE.md`, `README.md`, `docs/world/forest_v2/RELATORIO_FINAL.md` e a cena/região em questão.
2. Defina objetivo, limites da região, conexões, habitats, escala (tiles de 32 px), pontos de interação, obstáculos e requisitos narrativos.
3. Para mapas editáveis, use `TileMapLayer`, TileSet/atlas, objetos separados, colisões e triggers; não entregue apenas uma imagem de fundo para um nível jogável.
4. Reutilize texturas e props de `assets/`. Se faltar arte, delegue a geração pontual à skill `pixellab`; nunca gere todo o cenário sem inventário prévio.
5. Documente spawn, saídas, colisão, áreas caminháveis, Y-sort, ordem das camadas e caminhos de cenas/recursos.
6. Preserve UIDs e caminhos existentes; não sobrescreva uma região aprovada. Teste a transição entre regiões e a interação `E`, quando aplicável.
7. Entregue diff de cenas, assets, evidências de teste e limites conhecidos; não confunda preview com mapa funcional.

Base conceitual: 0x0funky/agent-sprite-forge, `skills/generate2dmap`, commit `64fd0b57d3f2ae117ef0a95e4c2decc25b4c9dd2`, MIT. Adaptada ao projeto; os scripts externos de extração não são instalados nem executados.

