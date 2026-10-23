# Slimekeepers: Lost Valley — movimentação do protagonista no Godot 4

Este pacote adiciona um **protótipo jogável** ao repositório existente. Não substitui ou modifica nenhum sprite PixelLab.

## Como instalar

1. Mantenha os sprites exportados no repositório, em `C:\Slimekeepers Lost Valley\sprites\Idle\...`.
2. Extraia o conteúdo deste ZIP diretamente para `C:\Slimekeepers Lost Valley\`, **mesclando as pastas**. O arquivo `project.godot` deve ficar na raiz, ao lado de `sprites/`.
3. No Godot **4.3+**, selecione **Importar** e abra `C:\Slimekeepers Lost Valley\project.godot`.
4. Espere o Godot importar os PNGs e pressione **F6** (cena atual) ou **F5** (projeto).

O protótipo utiliza a pasta `sprites/Idle` tal como está no commit `Add Sprites` do GitHub.

## Controles

| Comando | Teclado | Controle |
|---|---|---|
| Movimento, incluindo diagonais | WASD / setas | Analógico esquerdo |
| Corrida | Segurar Shift | RB / R1 |
| Dash curto | Espaço | A / Cruz (botão inferior) |

## Animações aproveitadas

- `idle`: `sprites/Idle/animations/The_adventurer_maintains_a_relaxed_idle_stance_whi/` — 8 direções, 9 arquivos por direção.
- `walk`: `sprites/Idle/animations/Walk/` — 8 direções, 6 arquivos por direção. Para South é usada a variante `south-f96d7729` (fallback para `south-2b9cc8e0`).
- `run`: `sprites/Idle/animations/Running/` — 8 direções, 8 arquivos por direção.
- `dash`: usa temporariamente os quadros de `run`, porque a biblioteca ainda não possui animação de dash aprovada.

`frame_000.png` é incluído em cada sequência, conforme o ZIP exportado. Isso significa que alguns ciclos gerados contêm 1 quadro inicial + demais quadros; ajuste os FPS conforme o resultado visual.

## Estrutura

```
C:\Slimekeepers Lost Valley\
├── project.godot
├── scenes\
│   ├── main.tscn
│   └── player.tscn
├── scripts\
│   ├── player_controller.gd
│   ├── movement_animation_library.gd
│   ├── input_bindings.gd
│   ├── demo_world.gd
│   └── main.gd
├── tools\
│   └── validate_player_assets.py
└── sprites\  (já existe no seu repositório)
    └── Idle\
        ├── rotations\
        └── animations\
```

## Funcionalidades implementadas

- CharacterBody2D com movimento 8-direcional e velocidade diagonal normalizada.
- Direção persiste depois de soltar o controle.
- Idle, Walk e Running carregados automaticamente dos frames PNG originais.
- Aceleração e frenagem suaves, velocidade de corrida e dash com duração/cooldown ajustáveis no Inspector.
- Colisão circular nos pés (sem usar o retângulo de 128×128 como hitbox).
- Câmera que acompanha o personagem; terreno e pedras com colisão para testar.
- Entradas são configuradas automaticamente se não existirem no Input Map.
- `set_movement_locked(true/false)` para futuras ações de ferramenta, diálogos etc.
- Ordem das direções: E, SE, S, SW, W, NW, N, NE.

## Verificação local opcional

Execute do diretório do repositório:

```powershell
python .\tools\validate_player_assets.py
```

O script informa se há PNGs ausentes, e quais conjuntos serão utilizados.

## Observações

- O projeto não contém novos PNGs: ele depende dos arquivos **já existentes no seu GitHub**.
- Sprites são carregados em runtime (ao iniciar); no futuro podemos gerar um `.tres` dedicado para produção.
- Ainda não há animações finais de dash, nado ou movimentação carregando slime. Não são simuladas como se já existissem.
- As animações devem ser revisadas em execução, principalmente o loop, os pés e a consistência entre direções.
- O protótipo foi preparado e validado estaticamente, **não testado no executável do Godot** neste ambiente.

## Correção aplicada — conflito de nome do Godot

No script `scripts/player_controller.gd`, a constante antes chamada `AnimationLibrary` foi renomeada para `PlayerSpriteFrames`, pois `AnimationLibrary` é uma classe nativa do Godot 4. Esta correção mantém a API e as animações do projeto.


## Correção: `make_sprite_frames()` e classe nativa

Na versão 3, a fábrica de animações é instanciada antes do uso, evitando a
chamada estática que pode ser interpretada pelo Godot como membro de uma classe nativa.
O script `movement_animation_library.gd` implementa agora `func make_sprite_frames()`
(em vez de `static func`). No `player_controller.gd`, em `_ready()`:

```gdscript
var frame_builder = MovementFramesBuilder.new()
sprite.sprite_frames = frame_builder.make_sprite_frames()
```

Substitua os **dois scripts juntos** (`player_controller.gd` e
`movement_animation_library.gd`), porque as assinaturas foram alteradas.

O ZIP não inclui os sprites PNG do seu repositório; para jogar, a pasta
`sprites/Idle/` do repositório deve estar presente no mesmo projeto.

Não foi possível testar a execução no editor Godot aqui; abra o projeto
e verifique a aba **Debugger > Errors** se surgir outro erro.


## V4: tipagem explicita no carregador de sprites

Corrigida a inferencia da variavel `fallback` na linha 37 do
`scripts/movement_animation_library.gd`, e adicionados tipos a variaveis
que combinam constantes, arrays e caminhos de arquivo. `SpriteFrames`
continua sendo instanciado como na V3.

Se surgirem outros erros de compilacao, copie a primeira mensagem do
Godot (com arquivo e linha) antes de alterar outros arquivos.
