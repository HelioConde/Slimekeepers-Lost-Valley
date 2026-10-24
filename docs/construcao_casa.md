# Construcao automatica — Slimekeepers: Lost Valley

## Referencia

Adaptacao do gerador automatico de contorno/entrada/cobertura de
[Slime-Harvest](https://github.com/HelioConde/Slime-Harvest),
em especial `scripts/building/house_builder.gd` (metodos `_wall_ring` e `_rebuild`).

A antiga versao desta Clareira exigia quatro pinceis. Agora existe **um unico pincel: piso**.
O arquivo de save v1 (camadas manuais) continua legivel. Depois de carregar,
paredes, telhados, portas e janelas sao recalculados a partir do piso.

## Jogar

Abrir `scenes/enchanted_clearing_demo.tscn` e executar com F6.

| Controle | Funcao |
|---|---|
| B | Entrar/sair da construcao |
| Clique esquerdo / arrastar | Pintar piso de madeira na grade 32x32 |
| Clique direito / arrastar | Remover piso (devolve uma madeira) |
| Ctrl+Z | Desfazer piso e transacoes de materiais |
| Ctrl+S | Salvar casa e inventario |
| Ctrl+L | Carregar casa e inventario |
| R | Esconder/exibir cobertura |
| Esc | Sair do modo construcao |

**Nao existem botoes para paredes, janelas, telhados nem porta.**
Enquanto constroi, o jogador fica parado, a barra de ferramentas e ocultada e
os cliques pintam unicamente o piso. Fora da construcao, as ferramentas
anteriores 1–4 continuam funcionando.

## Como a casa e gerada

1. O jogador posiciona **somente os pisos**. Cada piso custa 1 madeira.
2. Os pisos precisam formar um conjunto conectado pelos lados.
3. Um anel externo de oito vizinhos ao redor do piso vira **parede**.
4. A entrada e escolhida automaticamente na borda sul da casa,
   proximamente ao centro do conjunto de pisos.
5. **Janelas** sao distribuidas automaticamente nos trechos retos de parede,
   evitando vizinhos imediatos e a entrada.
6. O **telhado** cobre o conjunto de pisos e o contorno externo;
   a fachada frontal (com porta e janelas) e desenhada acima da cobertura
   para permanecer visivel.
7. O telhado some quando o personagem entra na area de piso; durante a
   construcao ele fica semitransparente.
8. Paredes possuem colisao. A porta abre um vao transitavel.

A primeira celula permanece como **ancora permanente**, impedindo mover a casa.
Nao e permitido colocar piso nem gerar paredes muito perto do jogador, fora de
25 tiles do spawn original, fora do mapa, sobre as trilhas, lagoa, encosta ou
grandes objetos.

## TileSet / Terrain

O terreno ainda vem de `resources/grass_dirt_v3.tres`; a nova casa
usa um TileSet em memoria com 5 fontes de atlas, uma por material:

- `house_floor_wood_seamless`
- `house_wall_wood_detailed`
- `house_roof_red_tiles`
- `house_door_wood_detailed`
- `house_window_wood_detailed`

Os 5 PNGs PixelLab sao convertidos temporariamente de 48x48 para 32x32
com filtro **nearest**, sem alteracao do arquivo original. Essas texturas
atualmente representam **pecas modulares individuais** e nao um atlas
completo de 9-slice/terrain. A regra de montagem e automatica, mas os
cantos e bordas poderao receber acabamento com futuros tilesets.

## Salvar / desfazer

`Ctrl+S` cria `user://slv_house_clearing_v1.json`, salvando somente
os pisos, a ancora e os materiais, versao 2. `Ctrl+L` restaura o arquivo.
Saves v1 tambem sao aceitos (as antigas camadas pintadas manualmente
sao ignoradas e reconstruidas a partir dos pisos). `Ctrl+Z` reverte
a ultima modificacao e seu custo.

A implementacao foi revisada em codigo, mas **nao executada em um binario
do Godot neste ambiente**. Verificar a composicao e colisoes no editor.
