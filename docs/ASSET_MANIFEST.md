# Manifesto de assets e geração — menu v0.1

Data: 25/10/2026 (America/Sao_Paulo). Destino desta integração: `C:\Slimekeepers_Lost_Valley_v0_1`.

Atualização posterior: o pacote enviado pelo usuário foi integrado sem novas gerações. A casa atual vem do ZIP; a casa PixelLab e os demais recursos anteriores foram preservados. Fontes, seleção, capturas e limites atuais estão em `PROVIDED_PACK_INTEGRATION.md`; as seções seguintes registram a etapa anterior e seu consumo.

Este é um projeto independente, sem diretório Git local. A base jogável contém movimento, interação e uma missão de amizade com três slimes. Não contém inventário, ferramentas ou salvamento; esses sistemas do projeto antigo não foram portados. A opção **Continuar** deve permanecer desabilitada enquanto não existir um jogo salvo real. Voltar ao menu encerra a partida atual.

## Origem e preservação

Os arquivos abaixo estão em `assets/menu/environment/`. Dez PNGs foram copiados do acervo existente de `C:\Slimekeepers Lost Valley\assets\sprites\objects\`, sem alteração dos bytes. A comparação SHA-256 com as fontes foi realizada em 25/10/2026. A renomeação do arquivo de destino facilita a integração e não modifica a arte original.

| Destino | Dimensões nativas | Fonte dentro de `assets/sprites/objects/` do projeto antigo |
|---|---:|---|
| `barrel.png` | 48×48 | `pixellab_exports/wooden_barrel_detailed_32x48_06d343fc/wooden_barrel_detailed_32x48.png` |
| `crops.png` | 48×48 | `pixellab_exports/crop_growth_stages_set_of_si_2540a148/crop_growth_stages_set_of_si.png` |
| `fence.png` | 48×48 | `pixellab_exports/wooden_fence_single_32x32_pi_01dc10e8/wooden_fence_single_32x32_pi.png` |
| `flowers.png` | 48×48 | `wildflowers_small_cluster_of/rotations/wildflowers_small_cluster_of.png` |
| `grass.png` | 48×48 | `tall_grass_small_clump_of_ta/rotations/tall_grass_small_clump_of_ta.png` |
| `oak.png` | 96×96 | `tree_oak_large_large_mature/rotations/tree_oak_large_large_mature.png` |
| `oak_medium.png` | 96×96 | `tree_oak_medium_medium_oak_t/rotations/tree_oak_medium_medium_oak_t.png` |
| `plot.png` | 48×48 | `pixellab_exports/farm_plot_detailed_64x64_pix_0819a7d6/farm_plot_detailed_64x64_pix.png` |
| `stone.png` | 48×48 | `rock_small_small_rounded_fie/rotations/rock_small_small_rounded_fie.png` |
| `stump.png` | 96×96 | `tree_stump_small_cut_oak_stu/rotations/tree_stump_small_cut_oak_stu.png` |

Os sprites de jogador e slimes já presentes em `assets/player/` e `assets/slimes/` permanecem os originais da base v0.1. Nenhuma imagem completa do menu foi usada como fundo ou componente de interface. `docs/references/menu_quality_target.png` é uma referência de direção artística, não uma textura do jogo.

## Novos objetos PixelLab

Foram feitas **3 chamadas pagas de geração**, dentro do limite inicial de 8 chamadas. As operações usaram o MCP PixelLab: `create_map_object`, seguido de `get_map_object`. O status de conclusão foi confirmado antes dos downloads. O caminho REST subjacente não foi utilizado nem inferido neste manifesto.

Parâmetros de direção artística: `low top-down`, `selective outline`, objetos individuais e sem texto. O serviço não retornou seed nem preço individual dos jobs; esses valores são **não disponíveis**, não zero.

| Asset | Dimensões solicitadas e verificadas | ID do objeto/job | Resultado | Destino |
|---|---:|---|---|---|
| Cachoeira | 128×160 | `11f0afcd-9c85-4022-89d6-0b8d306afe2a` | Concluído e baixado | `assets/menu/environment/waterfall.png` |
| Lanterna | 48×96 | `4ab6f1ca-6aa1-4197-86f7-7326200e7d32` | Concluído e baixado | `assets/menu/environment/lantern.png` |
| Casa | 192×192 | `cf3e0ec5-2c2d-4607-aa3d-96f45d6f4475` | Concluído e baixado | `assets/menu/environment/cottage.png` |

`waterfall.png` e `lantern.png` foram primeiro baixados em `C:\Slimekeepers Lost Valley\assets\environment\menu\` durante esta mesma tarefa e depois copiados para o novo destino. A igualdade SHA-256 dessas cópias foi confirmada. Não são reutilizações de gerações históricas adicionais.

### Prompts

Os textos abaixo foram transcritos exatamente do histórico das chamadas:

**Cachoeira — `11f0afcd-9c85-4022-89d6-0b8d306afe2a`**

```text
Small woodland waterfall over one moss covered gray stone ledge, turquoise water curtain and shallow splash pool at foot, isolated environmental prop, cozy fantasy RPG pixel art, crisp clusters, upper left sunlight, rich natural greens, no text, no background scenery
```

**Lanterna — `4ab6f1ca-6aa1-4197-86f7-7326200e7d32`**

```text
Single rustic oak wooden post with a hanging small golden glowing glass lantern, tiny ivy leaves at base, cozy woodland RPG pixel art environmental prop, crisp pixels, upper left light, isolated full object, no text, no scenery
```

**Casa — `cf3e0ec5-2c2d-4607-aa3d-96f45d6f4475`**

```text
Cozy woodland farmer cottage, a single complete rustic cream plaster and oak timber house with terracotta red tiled pitched roof, small stone chimney, arched wooden front door, warm window, tiny ivy and flower window box, charming storybook pixel art building, three quarter front view slightly from above, sunlight from upper left, transparent around entire house, no scenery no text
```

### Consumo observado

| Consulta do saldo | Franquia restante |
|---|---:|
| Antes das gerações desta tarefa | 4.731,50 |
| Após cachoeira e lanterna | 4.623,20 |
| Após a casa | 4.622,20 |

A variação total observada foi **109,30 unidades de franquia**. A conta é compartilhada e o serviço não informou custo individual por job; portanto, não é possível atribuir toda essa diferença às três chamadas desta tarefa. A última variação observada, entre a consulta anterior e a consulta após a casa, foi **1,00 unidade**, também um delta de saldo e não um recibo individual do job. Créditos monetários informados: **US$ 0,00**; plano informado: **tier 2**. Chamadas desta rodada: **3/8**. Nenhuma credencial foi gravada neste projeto.

### Integridade dos novos PNGs

| Arquivo | SHA-256 |
|---|---|
| `waterfall.png` | `E38AF24E73D49FAE29E784CDB5C8B8B3611B024F3C6829B52714990919C6A1A0` |
| `lantern.png` | `F0846E0E13EEDA6D1C05E9475E8A3ED0E7542C5D8C9C1AD131469ECCF0D76DE4` |
| `cottage.png` | `8B2A75D45045AD707D58C23ACF2682469DCD4F7C3B52E287931EF65A16C02A90` |

## Tipografia e licença

`assets/fonts/PixelifySans.ttf` é a fonte Pixelify Sans, de The Pixelify Sans Project Authors (copyright 2021). A licença **SIL Open Font License 1.1** está preservada integralmente em `assets/fonts/OFL-PixelifySans.txt`; mantenha esse arquivo junto da fonte na distribuição. Origem indicada pela própria licença: <https://github.com/eifetx/Pixelify-Sans>. Os títulos e rótulos são renderizados pelo Godot, sem letras geradas por IA.

## Integração e limites

A nova direção de fazenda substituiu a composição de clareira durante a tarefa. Casa e lanterna estão no menu atual; a cachoeira PNG permanece disponível, mas as quedas d'água distantes do panorama atual são geometria animada. `crops.png` e `stump.png` também ficaram preservados no acervo sem instância no menu final. Os canteiros, pequenas folhas e flores adicionais são desenho Godot reutilizável, não imagens geradas.

Os PNGs são peças individuais para composição em camadas; as molduras antigas rasuradas não fazem parte desse acervo. Os arquivos `.import` são metadados do Godot, não novas gerações. A nitidez, a transparência, a escala e a composição devem ser verificadas nas capturas de runtime da entrega; status de geração concluída, dimensões e hashes não equivalem a aprovação artística.

Backups da base anteriores às mudanças encontram-se em `docs/backups/`, incluindo `world.gd.txt`, `player.gd.txt` e `project_before_menu.godot.txt`. A alteração de `player.gd` restringe-se à tipagem explícita de uma variável de nome de animação necessária para a compilação no Godot 4.7.2.

## Ícones de itens (barra rápida) — 2026-11-21

PixelLab `create_map_object`, 32×32, fundo transparente, 1 geração cada (7 no total):
`assets/ui/items/` — `enxada`, `regador`, `semente_cenoura`, `semente_beterraba`,
`semente_repolho`, `sementes_silvestres`, `porcao_folhas`. Colheitas usam o último estágio das
culturas já exportadas (recortado em `item_catalog.gd`).


## Árvores V6 (protótipo) — 2026-11-21

Geradas no PixelLab (`create_map_object`, 96×96, high top-down, detailed shading, selective outline; 4 gerações da assinatura, 2 aprovadas). Pós-processo local: removido o tufo de grama na base, tronco alinhado à base dos sprites antigos (`oak.png`/`pine_crisp.png`) e realces amarelo-lima suavizados (−32% saturação, −12% valor). Desenhadas em escala 2, como as demais árvores. Em uso só na borda oeste da Clareira (FlorestaDoDespertarV2, 9 carvalhos e 6 pinheiros) até a validação.

| Arquivo | SHA-256 |
|---|---|
| `assets/world/forest/oak_lush.png` | `86FF4CF4AA7AECE8E69739AB8D45F7FA036829B5CF4036771EF6E3AF82D17BC5` |
| `assets/world/forest/pine_lush.png` | `FF1B9624C8EA7718492CA71FE37C87B280C3A9ADC9AE7558370D7CCDEC9523B1` |

## Detalhe de chão V6 (protótipo) — 2026-11-21

Gerados no PixelLab (`create_map_object`, 32×32, high top-down; 6 gerações). Pós-processo local: as folhas caídas foram recoloridas para paleta de outono, o capim perdeu o monte de terra e as pedrinhas foram clareadas para cinza quente. Usados por `scripts/world/ground_detail.gd` só na borda oeste da Clareira. O raminho (`clover_sprig`) saiu como broto, não como trevo, e é usado assim.

| Arquivo | SHA-256 |
|---|---|
| `assets/world/ground/wildflower_yellow.png` | `1B775FA4498B358F45A8B6E8BD0B95EAF84A7A0BA329E8AC532437996D075F50` |
| `assets/world/ground/wildflower_lilac.png` | `25D3B4EC45B1234980AFEB073E8511258C73A6A68319B9D4435E9F38849AE507` |
| `assets/world/ground/fallen_leaves.png` | `2DBD6E6C0DCD50A911CAE385CD8E714BC0DF14D79CC43F2E3B8C78DFE770B0FB` |
| `assets/world/ground/pebbles.png` | `034F43C2EB3C4F973987D138C20BC36603B30DBE215B726630E81F7F4BDE7887` |
| `assets/world/ground/clover_sprig.png` | `C51EC1E1AD1EA235C1515E171D5CE4DD191DFCDCBFF17610EEF10D0245C221D1` |
| `assets/world/ground/grass_tuft_sunlit.png` | `3B90736BB3AAED857342468CDAEABDA81ABBFE1EBF82071CAF3F15163F4139EF` |

## Árvores V6 — expansão na Floresta V2 — 2026-11-21

Novas variantes geradas no PixelLab (mesmos parâmetros das árvores do protótipo; 3 gerações, 2 aprovadas, arbusto rejeitado por parecer planta em vaso). Pós-processo reproduzível com `tools/tone_lush_sprite.py`. Os pinheiros passaram a usar `--tips 0.5` para suavizar as pontas lima.

| Sprite antigo (Floresta V2) | Sprite novo | SHA-256 |
|---|---|---|
| `oak.png` | `assets/world/forest/oak_lush.png` | `86FF4CF4AA7AECE8E69739AB8D45F7FA036829B5CF4036771EF6E3AF82D17BC5` |
| `oak_medium.png` | `assets/world/forest/oak_lush_open.png` | `27F54165D9AC3AFA11129176649C7C16DAC3245E9EFF16E8328EDB38D1F8FFD2` |
| `oak_young.png` | `assets/world/forest/oak_lush_tall.png` | `159ABF7F8F46A3BFBC4CC340AEC695D0B8EEEDDA7510FD46F9451056A27DAC53` |
| `pine_crisp.png` | `assets/world/forest/pine_lush.png` | `F1A45CF9A47E75DF134FCC5CFD547B3775640568BEAE859DEB40DE8E7F3389DA` |

O `wildflower_yellow.png` teve as pétalas clareadas (+25% de valor) para ler como flor ao sol.

## Harmonização V8 — 2026-11-21

Árvores V6 retonificadas com `tools/tone_lush_sprite.py` (`--soften 0.55`; pinheiro `--soften 0.5 --tips 0.7`) para tirar o amarelo-lima fluorescente. As versões V6 anteriores ficam no histórico (b230e32), e os sprites antigos (`oak.png`, `oak_medium.png`, `oak_young.png`, `pine_crisp.png`) continuam no repositório para comparação. Sem gerações novas.

| Arquivo | SHA-256 |
|---|---|
| `assets/world/forest/oak_lush.png` | `D8AE4AFE0B710AAE592212E1943A9D47F4881B67E8D7E654243C878E4B2662CF` |
| `assets/world/forest/oak_lush_open.png` | `6CED844989314B691C07404D67817DDFF40526119F85021B8C19874E6D760E54` |
| `assets/world/forest/oak_lush_tall.png` | `7B9A7AF593A13CF5C8D04014F8667C0CE51904DA4D66C11717274BE7AC094A24` |
| `assets/world/forest/pine_lush.png` | `9A6FBDB87C8536290A10A1328D725EA5A6D0239143C58A0401734CA9C2B46D2F` |

## Chão V8 — 2026-11-21

Dois tilesets Wang pro do PixelLab (`create_topdown_tileset`, 32 px, high top-down, borda orgânica; 30 gerações): chão de mata musgoso ↔ grama de campo, e terra de trilha ↔ a mesma grama (encadeados pelo tile base da grama). Organizados no atlas canônico (índice = NW·8 + NE·4 + SW·2 + SE) e harmonizados com `tools/tone_ground_tiles.py`: grama com valor ×0,8 e saturação ×0,9, para casar com a luminância do chão antigo; mata com valor ×1,2; terra com valor ×1,18 e saturação ×0,75. O atlas antigo `grass_dirt_v3_32x32.png` continua intacto.

| Arquivo | SHA-256 |
|---|---|
| `assets/tilesets/v8/forest_grass_wang.png` | `70D39C80CEE071E927898448FDF6561361E6251D60D0D27F68A0167055FB8FC6` |
| `assets/tilesets/v8/dirt_tile.png` | `AB726435DB045C86FF500B0CC5C939CF427E526345DFC7A79EB3742F41F295BB` |

## Trilhas naturais V8 — 2026-11-21

`assets/tilesets/v8/dirt_grass_wang.png`: atlas canônico do tileset Wang terra ↔ grama (o mesmo da seção "Chão V8"), harmonizado com `tools/tone_ground_tiles.py`. Sem gerações novas. SHA-256 `689ABCF06460488E5C3FD4149B0E2674E243110F31BCFA8E2CEFA0A9CFCEC5C2`. As trilhas viram passagens de bicho (mundo sem gente): só manchas de terra gasta no miolo do traçado, com borda Wang.

## Plantas e arbustos V8 — 2026-11-21

- `assets/world/forest/bush_lush.png` e `bush_lush_round.png`: recortados das copas aprovadas (`oak_lush`, `oak_lush_tall`), sem tronco, com base arredondada e borda inferior sombreada, centralizados no canvas 96×96 do arbusto antigo (mesma base). O arbusto gerado pelo PixelLab saiu cônico e foi rejeitado.
- `assets/world/forest/plant_rosette.png`: roseta de folhas verdes (PixelLab, 48×48, 1 geração) no lugar de `crops.png`, que era uma planta azul-petróleo fora da paleta. A pedra gerada saiu em formato de ovo e foi rejeitada.
- Tingimentos fortes das flores (azul 0.65–0.7 / 1.3–1.4, magenta 1.2 / 0.82) suavizados na cena e nos tiles alternativos: pintavam as folhas inteiras.

| Arquivo | SHA-256 |
|---|---|
| `assets/world/forest/bush_lush.png` | `B0235FAE49E730E597B93484D48CAD550383BAA8D843ACC9B0653977B679C4C7` |
| `assets/world/forest/bush_lush_round.png` | `3D1CF48117265DA4AC4060B372B8FD39B4768CA76BB8FC9894CA13E6AF1A2AFD` |
| `assets/world/forest/plant_rosette.png` | `FCD50B7971BEA2F6C54C7CA95A864785FB60E30F3F2AA35A99ACEE2CF0954C3A` |

## Touceira de flores V8 — 2026-11-21

`assets/world/forest/wildflowers_cluster.png` (48×48): composição local de `wildflower_lilac` + `wildflower_yellow` com base alinhada à de `flowers.png`. Substitui `flowers.png` na Floresta V2 (sprites e tiles) e no Vale. Sem gerações novas. SHA-256 `80BEC0048DD400D4280F102E7CCE2E378917647F7671722F969C2EEC14386B03`.

## Nenúfar com flor V9 — 2026-11-21

`assets/world/valley/lily_pad_flower.png` (PixelLab, 32×32, 1 geração): nenúfares com flor rosa, no lugar de `lily_pad.png` no Vale (mesmo canvas e tamanho). SHA-256 `9A325FEF9C4543FD41E7507CDE9096BD5D37A85ECB7B6D418444BFCA4A4EFCC7`.

## Lago encantado V9 — 2026-11-21

PixelLab (`create_map_object`, 3 gerações): vitória-régia com flor luminosa lilás (32×32), juncos com pontas ciano luminosas (32×48; poça azul da base removida localmente) e folha de vitória-régia (32×32). Usados por `scripts/world/pond_magic.gd` no lago da Clareira.

| Arquivo | SHA-256 |
|---|---|
| `assets/world/pond/lily_glow.png` | `186D8479C84BEA11941471429F9A028C3A4F3FAE9D937BA364BCC3F3779A50EE` |
| `assets/world/pond/reeds_glow.png` | `D6458ADB606BCDDF2F9BAFEFD7A030123C1591C0FD455A8164A177101F5F3D49` |
| `assets/world/pond/lily_pad.png` | `1B1D6D91E48C8DDB59C30F8516AAE212853B8D102D0964FF11C30441C783AA77` |

## Margens do rio V9 — 2026-11-21

`assets/world/valley/water_banks_v9.png`: tileset Wang pro do PixelLab (água ↔ grama com barranco baixo de pedra musgosa, 32 px, transition 0.25; 15 gerações), encadeado na grama do chão V8 e remapeado por cantos no layout de `water_banks.png` (mesmas células do mapa). Grama com valor ×0,8 e saturação ×0,9. O antigo (borda de terra marrom-escura) continua no repositório. SHA-256 `0A2DB4A42D922270A4907FB7E9104912F9E2256CF2F7B0398DF1F73496D14493`.

## Plantas-lanterna V9 — 2026-11-21

`assets/world/valley/lantern_flower.png` (PixelLab, 32×48, 1 geração): planta com frutos-lanterna dourados (tipo physalis). Fica nas cabeceiras das pontes do Vale e acende à noite (`scripts/world/lantern_flowers.gd`). Faz o papel das lanternas da referência do rio sem presença humana. SHA-256 `9AF19C67167A0A96A61EF84281FFCD87B5BE36F3C6F075D92526E476BFEBA441`.

## Margens do rio V11 — 2026-11-21

`assets/world/valley/water_banks_v11.png`: tileset Wang pro do PixelLab (barranco baixo de terra escura com pedrinhas e linha de espuma; 15 gerações), encadeado na grama V8 e remapeado por cantos no layout de `water_banks.png`. A água do próprio tile ficou transparente para mostrar a água animada. SHA-256 `3C8657918DA418E799AEC239225E9AEC1424BF61B52F842A1BE84A9D15E5EF9A`.

### Carvalho grande das pontes (V11)

| Arquivo | Tamanho | SHA-256 |
|---|---|---|
| `assets/world/forest/oak_grand.png` | 128×128 | `070672afb8f7f6c68de940659603e9a7a9feb052c12e50be70a772e41cbf8986` |

Gerado no PixelLab (`create_map_object`, 128×128, high top-down, high detail, detailed shading, selective outline; 1 geração, aprovada). Pós-processo local: `tools/tone_lush_sprite.py --strip-ground 96 --soften 0.45`, remoção de pontinhos soltos (<6 px) abaixo da linha 90 e −20% de saturação nos verdes. Desenhado em escala 2; usado só nas árvores a até 260 px das pontes do Vale (`scripts/world/tree_glow.gd`), cuja colisão não muda.

### Pontes naturais do Vale (mundo sem humanos)

| Arquivo | Tamanho | SHA-256 |
|---|---|---|
| `assets/world/valley/natural_bridges/root_bridge.png` | 92×38 | `2244bdd95296cf760734ec51cfe1582c9abbd3365a2211ee6a9bff67ca627512` |
| `assets/world/valley/natural_bridges/root_bridge_v.png` | 32×112 | `3b23a97aa4930a0776a858fb3aae785e58a4e0685516321b028cdfe073a0afa6` |

Arco de raízes entrelaçadas gerado no PixelLab (`create_map_object`, 128×48, high top-down, high detail, detailed shading, selective outline), recortado à caixa visível. Único aprovado pelo usuário: troncos caídos, pedras, istmo e versões verticais de raízes foram rejeitados (13 gerações no total). Versão vertical (48×144, 3 variações, 1 aprovada) nas travessias oeste e leste. Desenhados por `scripts/world/natural_bridges.gd` em escala 2, espelhados em alternância.
