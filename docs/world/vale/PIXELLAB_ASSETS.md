# Assets PixelLab — Vale das Nascentes

Autorização: o usuário autorizou mais de quatro gerações para os barrancos, transições de altura e pedras de margem. Foram usadas exclusivamente ferramentas MCP para gerar; arquivos foram baixados somente após status completed.

Documentação consultada: https://api.pixellab.ai/mcp/docs

Saldo de gerações do plano antes: **4618,20**. Consumo desta etapa: **27 gerações** (um tileset Pro de 15 e doze operações padrão de 1). Saldo resultante: **4591,20**. Não houve compra de créditos. As duas tentativas de parâmetros recusados antes da geração do tileset não consumiram saldo.

| Recurso | ID da geração | Custo | Destino / uso |
| --- | --- | ---: | --- |
| Paredões altos, 25 tiles 32×32 | ce262ea7-8d66-4dd2-affe-824aede71f93 | 15 | cliffs_tall.png + JSON + TRES |
| Bordas baixas, 16 tiles 32×32 | 9fb8a10c-73fe-4fff-8d3c-3058c9c50b91 | 1 | cliffs_low.png + JSON + TRES |
| Margens água/grama, 16 tiles 32×32 | 42b1d3ee-f273-46df-bf69-81549078196f | 1 | water_banks.png + JSON + TRES |
| Cachoeira estreita 48×96 | 5ac0241d-f766-47c0-a949-e77a8debec16 | 1 | waterfall_narrow.png, disponível, não usada na montagem final |
| Cachoeira média 96×96 | 1616b850-f17e-4485-8785-6dd8bfdf8d89 | 1 | waterfall_medium.png, três quedas montadas no Godot |
| Escada inicial 64×96 | 25cac187-0671-4c4f-bc83-a101385c3b85 | 1 | estudo descartado: perspectiva incompatível |
| Rampa inicial 64×96 | 1e2cf357-d1b0-43b0-aa5a-93bbb6f4ac54 | 1 | estudo descartado: perspectiva incompatível |
| Juncos 32×48 | c654e55b-7349-492f-8dfd-8c0a1bec330d | 1 | reeds.png |
| Pedras úmidas 48×32 | 0e177087-3b3a-4a86-af48-707e7ee0f94c | 1 | river_stones.png |
| Vitórias-régias 32×32 | 497a18ac-7bb8-45ef-a3fe-9bdefe03ca80 | 1 | lily_pad.png |
| Escada plana inicial 64×64 | 28ef6ac8-a76d-48b6-bd83-c6b0f5fa9f9f | 1 | estudo substituído: aparência de madeira |
| Rampa plana 64×64 | 1610869e-3165-4e0e-b4ed-d6f49eb8d12a | 1 | grass_ramp_flat.png |
| Escada de pedra final 48×96 | ff8d87db-9738-4b2f-8afc-894d00bec061 | 1 | stone_steps.png, paleta derivada das pedras úmidas |

Arquivos finais em `assets/world/valley/`. Estudos preservados em `docs/world/vale/asset_studies/`, com .gdignore. Sprites isolados possuem transparência; tiles de terreno contêm as superfícies necessárias à conexão.

Os dois conjuntos padrão compartilham os IDs de terreno-base do atlas principal para manter os encaixes. A integração usa bounding_box e pattern_4x4 dos metadados, nunca nomes wang_N como coordenadas do atlas. Transições altas ocupam duas linhas; shaders de integração ajustam somente a apresentação no Godot, sem regravar os PNGs.
