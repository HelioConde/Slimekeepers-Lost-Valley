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
