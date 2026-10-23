# Ajustes da floresta — 23/10/2026

Estas modificacoes atualizam o mapa `forest_meadow_demo.tscn` e a escala do jogador de modo nao destrutivo.

## O que foi corrigido

1. O Player agora e filho de `WorldObjects`, que esta com `y_sort_enabled = true`. Ele e cada arvore participam da **mesma ordenacao por Y**. Antes, as arvores eram ordenadas apenas entre si.
2. O `player_controller.gd` disponibiliza `visual_scale` no Inspector. Padrao 0.80, sem redimensionar os PNGs. A colisao circular acompanha a escala e o rodape do sprite e ancorado no ponto fisico do Player.
3. Os limites de `Camera2D` sao ajustados ao mapa 40x26 para evitar visualizar o cinza fora do terreno.
4. O texto de controles tem fundo discreto semitransparente.
5. Sombras de contato leves sob objetos solidos e opcionais (`WorldObjects > Contact Shadows`).

## Teste

- Abra `scenes/forest_meadow_demo.tscn` e pressione F6.
- Ande na frente e atras de uma arvore grande. Ao passar atras, a copa deve cobrir o personagem; ao passar a frente, ele fica visivel.
- Caminhe ate as bordas e confirme que nao ha faixa cinza.
- Altere `WorldObjects/Player > Visual Scale` no Inspector: 0.75 ou 0.85, se quiser comparar.

## Importante

- `scenes/main.tscn` e as imagens originais nao foram alteradas.
- A escala do Player se aplica as demais cenas que instanciam o mesmo controlador.
- O Godot ainda deve ser executado localmente para confirmar comportamento final.
