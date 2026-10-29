# Vale das Nascentes — Mapa 2

Projeto: `C:\Slimekeepers_Lost_Valley_v0_1`. Implementação em Godot 4.7.2, GDScript, 2D top-down.

## Como acessar

No jogo, siga pela trilha sul da Clareira do Despertar e pressione **E** próximo à saída. A entrada do vale fica ao norte. Pressione **E** nessa entrada para voltar. Também é possível abrir `scenes/regions/ValeDasNascentes.tscn` no Godot e executar a cena com F6.

As amizades da Clareira e os recantos descobertos no vale persistem durante as viagens na mesma sessão. Novo Jogo inicia uma sessão nova. Isto não implementa salvamento em disco nem habilita Continuar no menu.

## Composição e água

- Área de 3200 × 3200 pixels, com Ground em 100 × 100 tiles de 32 pixels.
- Seis lagoas principais, oito cursos de água e três pequenas poças de origem. Quatro poças profundas adicionais ficam no brejo, entre áreas rasas navegáveis.
- Três grupos de barrancos alimentam a água ao norte e no centro; a rede se conecta às lagoas e ao escoamento sudeste. As nascentes têm pedras reais em torno da origem e os rios superiores seguem até a borda das quedas.
- Três cachoeiras ligam os cursos superiores aos inferiores. Duas usam uma região do mesmo PNG da queda média, mantendo a densidade dos pixels e a perspectiva. O sprite original permanece intacto.
- Cinco pontes conectam as margens. A colisão da água é recortada sob os tabuleiros; os corrimãos têm colisão própria. Não é necessário desativar a colisão do personagem para atravessar.
- Água profunda bloqueia; o brejo tem áreas rasas livres. A água é desenhada por polígonos unidos, com shader de ondulação. As margens rochosas usam o tileset Wang gerado, escolhido pelas coordenadas e padrões do JSON oficial.
- 216 árvores com colisão na base, vegetação baixa sem bloqueio, pedras e troncos sólidos. A vegetação é distribuída junto às margens e nos bosques, reservando os percursos.
- Jardim úmido a oeste, brejo a sudoeste, lagoas dos habitats no centro/leste e saída futura ao sul. Cinco pontos de observação respondem à tecla E.

## Elevações e módulos

Os novos atlases usam tiles-base de 32 × 32. Os conjuntos de paredões são montados em TileMapLayer a 2×: cada módulo ocupa 64 pixels no mundo, um múltiplo inteiro da grade do projeto. As formações maiores ocupam várias células.

`ElevationLevel1` usa 25 tiles de transição alta; o paredão ocupa duas linhas. `ElevationLevel2` e `ElevationLevel3` usam 16 tiles de borda baixa para formar afloramentos sobrepostos. A seleção respeita `pattern_4x4`, inclusive os cantos de transição e as condições acima/abaixo; nenhum tile ficou sem correspondência na montagem final.

Os três platôs principais são acessíveis por duas escadas e uma rampa. As pequenas formações superiores de segundo/terceiro nível compõem o relevo e não têm uma rota dedicada até todos os cumes. A altura é uma representação 2D com paredes sólidas e aberturas de passagem; não existe física 3D, salto entre níveis ou caminhada por baixo do mesmo platô.

As escadas foram refeitas após a avaliação visual: as versões iniciais tinham aspecto isométrico ou de madeira. Estudos rejeitados estão em `asset_studies/`, fora da importação do Godot. Os PNGs do projeto anterior não foram modificados.

## Pontos reservados para slimes

A cena contém seis Marker2D em `SlimeSpawnPoints`, com metadados de habitat, espécie futura e raio reservado. As posições em pixels são:

| Marker | Posição | Área |
| --- | --- | --- |
| WaterSlimeHabitat01 | (1070, 1400) | margem noroeste da lagoa central |
| WaterSlimeHabitat02 | (2130, 1370) | margem nordeste |
| WaterSlimeHabitat03 | (1000, 1980) | margem sudoeste |
| WaterSlimeHabitat04 | (2220, 2040) | margem sudeste |
| WaterSlimeHabitat05 | (1910, 2770) | margem oeste da lagoa sul |
| WaterSlimeHabitat06 | (2750, 2850) | margem leste da lagoa sul |

Todos foram verificados com a cápsula real do jogador. Ainda não há novas espécies aquáticas, IA de natação ou spawns populados neste mapa. Os slimes originais da Clareira continuam intactos.

## Arquivos

Criados:

- `scenes/regions/ValeDasNascentes.tscn`: mapa editável já montado, com personagem e câmera.
- `scripts/world/valley_layout.gd`: posições, cursos de água, percursos e habitats.
- `scripts/world/valley_region.gd`: HUD, observação, animação ambiental e entradas/saídas.
- `scripts/world/region_travel.gd`: troca de cenas e estado durante a sessão.
- `scripts/world/valley_water.gdshader`, `valley_banks.gdshader`, `valley_cliffs.gdshader`, `valley_cascade.gdshader`: água, integração das margens/relevo e quedas.
- `tools/build_valley.gd`: construção determinística exclusiva do Mapa 2.
- `tools/test_valley.gd`, `tools/test_region_travel.gd`, `tools/capture_valley.gd`.
- `assets/world/valley/`: PNGs, metadados e TileSets reutilizáveis.
- Esta pasta: briefing, documentação, logs e capturas.

Modificados:

- `scripts/world/clearing_region.gd`: viagem pela saída sul e restauração das amizades/posição de retorno.
- `scripts/menu/start_menu.gd`: limpeza do estado de viagem ao iniciar Novo Jogo.

Reaproveitados: personagem e animações, fonte PixelifySans, HUD do projeto, terreno grass_dirt_v3, carvalhos, pinheiro nítido, árvore jovem, arbustos, grama, flores, samambaia, cogumelos, pedra nítida e tronco caído.

Os dois scripts modificados têm cópia anterior em `docs/backups/before_vale_das_nascentes_20261026/`. As cenas e os tiles editados manualmente na Clareira não foram reconstruídos. Não houve commit nem push.

## Validação

Godot 4.7.2, renderizador OpenGL Compatibility, Radeon RX 580. Capturas locais em 1280 × 720 e visão geral em 1280 × 1280.

- Vale: **41 verificações, zero falhas**, 2096 amostras de navegação/colisão, incluindo 17 percursos contínuos, escadas, rampa, pontes, habitats, lagoas, observação e saída futura.
- Viagem entre regiões: **9 verificações, zero falhas**, incluindo ida/volta por E e amizade preservada.
- Clareira: **59 verificações, zero falhas**, 1972 amostras.
- Menu: **43 verificações, zero falhas**.
- Total: **152 verificações aprovadas**. Logs nesta pasta.

Para verificar: execute os scripts `test_valley.gd`, `test_region_travel.gd`, `test_clearing.gd` e `test_menu.gd` com Godot `--headless --path . --script res://tools/NOME.gd`.

**Construir novamente é uma operação explícita:** `build_valley.gd` regrava a cena ValeDasNascentes e seus TileSets gerados. Preserve uma cópia antes de editar manualmente essa cena e depois executar o construtor. Ele não reconstrói a Clareira.

## Próximas expansões

Espécies aquáticas e animações, IA de habitat, coleta de água, sons ambientais, missões próprias, persistência em disco e destino da saída sul. Os afloramentos superiores podem receber acessos adicionais quando houver conteúdo de exploração nesses cumes.
