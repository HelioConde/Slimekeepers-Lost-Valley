# Polimento de água — 27/10/2026

O Vale das Nascentes recebeu um leito mineral separado da superfície, com cascalho e profundidade calculada a partir das margens. O filme de água tem alfa de 20–36%, mais claro perto da margem e mais profundo no centro. O resultado é transparência sobre um fundo realmente desenhado, sem revelar a grama por baixo do rio.

`water_life.gd` desenha 190 conjuntos de plantas submersas e 38 pequenos cardumes (114 peixes). A animação usa pixels de 2 px e oito atualizações por segundo. Vitórias-régias existentes permanecem sobre a água. Os peixes ficam dentro do contorno aquático; não são entidades de pesca/coleta.

As três cascatas usam o sprite existente `waterfall_medium.png`, rochas laterais reutilizadas do atlas, filamentos descendentes e `waterfall_life.gd` para gotas, espuma fragmentada e arcos que se expandem sobre a água. A antiga elipse sólida de espuma foi retirada. Os efeitos respeitam a opção de movimento reduzido.

Arquivos principais: `tools/build_valley.gd`, `scripts/world/valley_region.gd`, `valley_water.gdshader`, `valley_bed.gdshader`, `valley_banks.gdshader`, `valley_cascade.gdshader`, `water_life.gd`, `waterfall_life.gd` e cena `scenes/regions/ValeDasNascentes.tscn`.

Nenhum sprite original modificado, nenhuma chamada paga. Plantas e peixes simples são primitivas pixeladas nativas do Godot. Colisões das bacias, escadas e cinco pontes foram preservadas; a atualização é visual.

Validação: `tools/test_valley.gd`, `tools/test_valley_water.gd` e `tools/test_region_travel.gd`. Evidências nativas em `vale_springs.png`, `vale_bridge.png` e `vale_overview.png`. Os resultados finais estão também no relatório da floresta v2.
