# Slimekeepers: Lost Valley — TileMapLayer e redução de tremedeira

Esta atualização se baseia no repositório público `HelioConde/Slimekeepers-Lost-Valley`, commit `90f66ecdca02daa951814ce9a5cf60b85a096608` (23/10/2026).

## Pré-requisito

O **PNG do terreno deve continuar no seu projeto**, exatamente em:

`res://sprites/tarrain/pixellab-tileset-lush-natural-spring-meadow-grass-for-a-cozy-warm-earthy-brow-godot-b9cd416a.png`

**A pasta se chama `tarrain` no repositório**, não `terrain`. Mantive esse nome para não quebrar o caminho. Os sprites do player em `res://sprites/Idle/...` também precisam continuar no projeto. **O ZIP não copia nem substitui os PNGs.**

## Aplicação

1. **Faça um commit ou uma cópia de segurança** das suas mudanças locais antes de instalar, especialmente `scenes/main.tscn` (que está sendo substituída).
2. Extraia o pacote na raiz `C:\Slimekeepers Lost Valley\`, mesclando `scenes`, `scripts` e `resources`, e permita substituir apenas os quatro arquivos existentes incluídos no pacote.
3. Abra `project.godot` com Godot 4.3+; abra `scenes/main.tscn`.
4. A cena contém `DemoWorld/TileMapLayer` associado a `resources/terrain_grass_dirt.tres`. O script `@tool` preenche automaticamente a grade **48 × 16** de tiles **32 × 32** quando ainda não há células; salve a cena com **Ctrl+S** para registrar as células no editor.
5. Pressione **F5** para testar o player em cima do terreno. A câmera acompanha o player sem smoothing, o terreno tem limites físicos apenas nas bordas, e as teclas continuam WASD/setas, Shift e Espaço.

## Arquivos incluídos

- `resources/terrain_grass_dirt.tres`: TileSet com atlas 1536 × 512 da PixelLab configurado em células de 32 × 32. Inclui 768 entradas editáveis no editor.
- `scripts/terrain_layer.gd`: constrói **somente se o TileMapLayer estiver vazio** a composição exata exportada, sem emendas internas, e acrescenta colisões no perímetro ao rodar o jogo. Mudanças pintadas manualmente não são sobrescritas se a camada tiver células.
- `scenes/main.tscn`: substitui a configuração antiga (3.000+ linhas de atlas padrão 16px, nenhuma célula pintada) pela camada pronta. Mantém nós `DemoWorld`, `Player`, `HUD` e script `scripts/main.gd`.
- `scenes/player.tscn`: mantém colisão e velocidades atuais (130/200), desliga `position_smoothing_enabled`, coloca `process_callback = 0` (física) e limita a câmera à primeira região.
- `project.godot`: mantém Godot 4.7, nearest e habilita `rendering/2d/snap/snap_2d_transforms_to_pixel`.
- `scripts/movement_animation_library.gd`: mantém idle/walk/run em oito direções, mas pode reduzir pequenos deslocamentos indesejados entre quadros de walk/run. Carrega, centraliza discretamente e cria texturas novas **em memória**; os PNGs permanecem idênticos.

## Sobre a tremedeira

Encontramos duas causas possíveis no código anterior:

1. **Smoothing da Camera2D** (`position_smoothing_enabled=true`) com zoom de pixel art 2×, que pode produzir rolagem fracionária/subpixel.
2. **Oscilação interna dos desenhos gerados** (posições diferentes da cabeça e da linha inferior dos pés entre PNGs de 128 × 128).

A camada do terreno nunca se movimenta, então ajuda a verificar se a tremedeira é da câmera (cenário inteiro treme) ou só dos sprites (o cenário fica estável, o corpo oscila).

O alinhamento em `scripts/movement_animation_library.gd` é opcional:

```gdscript
const STABILIZE_WALK_RUN: bool = true   # false para comparar sprites originais
const MAX_SHIFT_X: int = 4
const MAX_SHIFT_Y: int = 2
```

É um ajuste **limitado** para não eliminar toda a oscilação natural dos passos. Não é garantia de consertar arte inconsistente; se uma sequência tiver desenho ou fase de passada ruim, será necessária revisão manual dos frames. Para comparar o efeito, alterne `STABILIZE_WALK_RUN` e execute novamente.

## Atenção: limite do tileset gerado

O arquivo PixelLab `1536×512` é uma **composição visual pronta** com partes de grama e terra. Ela foi cortada em um atlas de 48 × 16 tiles. Ao reconstruir as posições originais, a imagem permanece contínua. **Reorganizar as células livremente no Godot pode produzir emendas**, porque não há, neste arquivo, metadados de bits de terreno/autotiling Wang para conectividade automática.

Para pintar caminhos novos com o pincel de **Terrain Set / Autotile** do editor precisaremos mapear as transições para um `TileSet` com terrenos e `peering_bits`, usando uma exportação específica de tileset conectável. Esta versão entrega o **primeiro mapa jogável editável por células**, e não promete autotiling inteligente.

Também mantive a grafia `sprites/tarrain` exatamente como está no repositório. Você poderá renomear no futuro atualizando todas as referências.

## Validação e reversão

O pacote foi conferido por geração estática, mas **Godot não está instalado no ambiente usado para criá-lo**, portanto ainda depende de teste no seu editor. Se houver erro, envie a primeira linha completa do painel do Godot (arquivo + número da linha).

Para voltar à versão anterior, restaure pelo histórico do Git. Exemplo (descarta modificações locais somente destes arquivos — use após salvar seu trabalho):

```powershell
git restore project.godot scenes/main.tscn scenes/player.tscn scripts/movement_animation_library.gd
```

Remova `resources/terrain_grass_dirt.tres` e `scripts/terrain_layer.gd` se não desejar manter a implementação.
