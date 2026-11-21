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
