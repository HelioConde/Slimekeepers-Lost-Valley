# Correcoes dos cenarios e ferramentas reais — Slimekeepers: Lost Valley

## Clareira Encantada
- Removidas as formas desenhadas manualmente da doca/ponte, lagoa, barranco e pedrinhas de estrada. A ponte usa o PNG real da PixelLab, id `wooden_bridge_96x64_pixel_ar_...`.
- Lagoa usa o sprite Sprout Lands **somente localmente** em `res://assets/local_sprout/Water.png`: extraia-o do seu `Sprout-Lands-Tilemap-0.2.0.zip` em `addons/sprout_lands_tilemap/assets/Tilesets/Water.png`. **Nao publique o PNG**, pois a licenca Free Basic Pack proibe redistribuicao e limita o uso a projetos nao comerciais. A montagem e feita com tiles reais 16x16.
- Os canteiros interativos usam variantes dos PNGs PixelLab `farm_plot_ground_v2_seamless`, `farm_plot_detailed` e `crop_growth_stages_set_of_si`. O cultivo muda conforme o estado, sem desenhar solo e folhas com retangulos.
- Modulos de casa ausentes nao geram mais retangulos ficticios: o editor informa erro e deixa o modulo invisivel para diagnostico.

## Personagem
- O controlador em `scripts/player_controller.gd` reproduz as animacoes da PixelLab para: **machado, picareta, enxada, regador, foice, pa, vara de pesca e interagir**, buscando as sequencias originais em `sprites/`.
- Ferramentas selecionadas com teclas 1-4 e usadas com **F** ou clique esquerdo, na `enchanted_clearing_demo.tscn`.
- **E** interage e toca o clip de interacao quando ha alvo.
- O efeito provisório de arco desenhado foi removido; as animacoes sao as reais do personagem.

## Observacoes
- Algumas animacoes exportadas pela PixelLab sao de segurando a ferramenta; elas sao reproduzidas como fornecidas e nao simulam golpes inexistentes.
- O addon Sprout Lands foi fornecido no projeto; consulte os arquivos originais de atribuicao/licenca do pacote para distribuicao.
- Cenas `scenes/main.tscn` e `scenes/forest_meadow_demo.tscn` nao sao alteradas.
- Atualize o GitHub local sem `push --force`; rode F6 em `scenes/enchanted_clearing_demo.tscn`. Godot nao foi executado neste ambiente; primeiro teste pode revelar ajustes finos de encaixe/camera.

## Licenca do Sprout Lands
O arquivo original `assets/read_me_art.txt` do pacote atribui a arte a Cup Nooble e proibe a redistribuicao, inclusive modificada. Este repositorio nao inclui a imagem: mantenha `assets/local_sprout/Water.png` apenas no computador. Para jogos comerciais, obtenha a licenca premium correspondente.
