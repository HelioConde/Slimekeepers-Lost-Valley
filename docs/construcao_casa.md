# Casa em camadas — Slimekeepers: Lost Valley

Implementação baseada na arquitetura de `Slime-Harvest/scripts/building/house_builder.gd` e em `docs/house_building.md` do projeto Slime-Harvest.

## Uso
Abra `scenes/enchanted_clearing_demo.tscn` e execute com F6. **B** ativa/desativa a construção e trava/libera o Player.

Dentro do modo construção:

| Tecla ou mouse | Função |
|---|---|
| 1 | Piso de madeira (custa 1 madeira por bloco) |
| 2 | Parede (gratuita neste protótipo) |
| 3 | Telhado (gratuito neste protótipo) |
| 4 | Porta (gratuita neste protótipo) |
| Botão esquerdo | Pinta o bloco na grade de 32x32 |
| Botão direito | Remove somente da camada selecionada |
| R | Exibir/ocultar telhado |
| Ctrl+Z | Desfazer última ação e restaurar materiais |
| Ctrl+S | Salvar casa e materiais |
| Ctrl+L | Carregar casa e materiais |
| B ou Esc | Sair da construção |

Os quatro primeiros blocos funcionam como **pincéis**, não são as ferramentas do HUD, enquanto B estiver ativo. Fora dele, 1–4 continuam equipando ferramentas. Os atalhos de navegação da clareira são F1–F4.

## Regras de construção

- O primeiro piso fixa a âncora da **casa inicial**; ela não pode ser demolida.
- Para expandir a casa, os pisos devem tocar outra célula por um dos quatro lados. Cortes que partem a casa em duas partes são recusados.
- O primeiro piso deve ser colocado a até 25 tiles do **spawn original**, não da posição atual do jogador. O raio pode ser alterado no Inspector.
- O construtor bloqueia construção no bloco do jogador e nos oito blocos ao redor, sobre a lagoa, trilhas, encosta e objetos maiores próximos.
- Só é possível pintar paredes nas bordas dos pisos, telhados sobre pisos e uma porta onde já exista parede na borda sul.
- A parede possui colisão; o piso e a passagem da porta não bloqueiam o Player. O telhado some ao entrar na área de piso fora da construção. Em construção, aparece semitransparente somente ao selecionar Telhado.
- Não há preenchimento automático das outras camadas, seguindo o modo manual do Slime-Harvest.
- A cena começa com **25 madeiras de teste**; pode coletar mais madeira usando machado. Cada piso consome 1 madeira e apagá-lo reembolsa 1 madeira (limitado a 99 itens por pilha).

## TileSet, Terrain e escala

O cenário continua usando `resources/grass_dirt_v3.tres` como **TileSet do solo** e seu `TileMapLayer` `Ground`. O construtor cria um **TileSet de construção próprio durante a execução**, com quatro `TileSetAtlasSource` (piso, parede, telhado e porta). Esses quatro módulos vêm das PNGs em `sprites/objects/pixellab_exports/`:

- `house_floor_wood_seamless_*`
- `house_wall_wood_detailed_*`
- `house_roof_red_tiles_*`
- `house_door_wood_detailed_*`

Os PNGs foram exportados em 48×48; cada módulo é redimensionado *em memória* com `Image.INTERPOLATE_NEAREST` para **32×32**, alinhando-se ao terreno sem alterar os assets originais. Se alguma textura faltar, aparece uma cor substituta de teste e um aviso no Output.

Esta é a **primeira conversão jogável do sistema de construção do Slime-Harvest**, ainda não um tileset artístico definitivo: sprites individuais podem precisar de acabamento para emendar bordas entre paredes e telhados. Quando finalizarmos as peças de canto/parede/telhado, podemos substituí-las por um atlas 32×32 no Godot sem reescrever a lógica dos pisos.

## Salvamento
Os dados da casa e as quantidades do mini inventário são gravados em `user://slv_house_clearing_v1.json`, por Ctrl+S, e carregados automaticamente quando o cenário inicia. Essa versão não modifica o save do Slime-Harvest nem as outras cenas de Slimekeepers.

O Godot não foi executado neste ambiente; os arquivos precisam passar por teste visual e funcional no editor.
