# Ferramentas basicas e mini inventario — Clareira Encantada

A cena `scenes/enchanted_clearing_demo.tscn` agora possui mini HUD e ferramentas.
O `scenes/main.tscn` e os sprites PixelLab permanecem inalterados.

| Tecla | Acao |
|---|---|
| 1 | Equipar machado |
| 2 | Equipar picareta |
| 3 | Equipar enxada |
| 4 | Equipar regador |
| F ou clique esquerdo | Usar ferramenta equipada diante do personagem |
| E | Interagir, plantar, colher, recolher fibras/cogumelos |
| I | Abrir/fechar inventario |
| WASD ou setas | Andar |
| Shift | Correr |
| Espaco | Dash |
| Tab | Visao geral |
| F1, F2, F3, F4 | Teleporte de teste para inicio/horta/lago/saida leste |

## Teste completo

1. Abra `scenes/enchanted_clearing_demo.tscn` no Godot e pressione **F6**.
2. Aproxime-se de troncos ou tocos. Com **1**, use **F** algumas vezes para receber madeira.
3. Aproxime-se de uma pedra. Com **2**, use **F** para receber pedra.
4. Use **F2** para ir perto da horta, caminhe ate os quatro canteiros. Um esta na grama, um preparado, um plantado e um pronto.
5. Use **3** e **F** no canteiro de grama para preparar o solo.
6. Use **E** no solo preparado para semear (-1 semente).
7. Use **4** e **F** no plantio para regar; apos 9 segundos ele amadurece.
8. Use **E** na plantacao pronta para colher (+2 colheitas, +1 semente).
9. Confira os totais na mini HUD ou pressione **I** para a mochila.

## Detalhes

- A distancia maxima das interacoes e aproximadamente **74 pixels de mundo**; o player precisa olhar na direcao do objeto (ou estar bem perto).
- Recursos ficam na mochila durante a cena, com pilhas de ate 99; **nao ha salvamento em disco nesta versao**.
- Arvores pequenas antigas, troncos caidos e pedras especificas sao coletaveis. Arbustos pequenos e cogumelos podem ser recolhidos com **E**. Outros objetos decorativos continuam intactos.
- A coleta remove o objeto esgotado; ele reaparece quando a cena e reiniciada.
- O golpe da ferramenta tem um arco simples. Ainda nao foi integrado a um sprite de animacao de ferramenta do PixelLab.
- Os quatro canteiros usam um desenho procedural temporario. Colisoes, player 0.40 e banco de escalas permanecem os mesmos.
