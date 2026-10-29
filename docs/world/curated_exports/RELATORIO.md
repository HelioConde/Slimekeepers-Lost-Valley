# Mapas enriquecidos com sprites do acervo

> Registro da primeira integração. Veja a [continuação do polimento](../composition_polish/RELATORIO.md) para o estágio intermediário. A [revisão narrativa atual](../wilderness_polish/RELATORIO.md) remove bancos e postes (46 elementos adicionais).

Aplicado em `C:/Slimekeepers_Lost_Valley_v0_1`, em 29/10/2026.

## Composição

14 recursos selecionados do acervo organizado em `C:/Slimekeepers Lost Valley/sprites/objects/pixellab_exports`: dois arbustos, dois conjuntos de flores claras, dois grupos de cogumelos, tronco, duas pedras musgosas, duas ruínas, banco, cristal e poste de madeira. PNGs e metadados foram copiados sem editar os originais; o manifesto contém origem, ID e SHA-256.

- Floresta: 125 substituições de decoração e 26 novos elementos em sete grupos, valorizando a clareira, o bosque dos cogumelos, o Círculo Musgoso, o mirante e o caminho das nascentes.
- Vale: 163 substituições e 21 elementos novos em sete grupos, com vegetação de margem, pedras, um banco e postes nas aproximações das pontes.
- A seleção é determinística. Somente parte dos objetos repetidos foi substituída, preservando a variedade anterior.
- Árvores e objetos existentes com colisão conservam sua aparência e seus corpos físicos. Os oito novos objetos sólidos têm colisões pequenas e alinhadas à base, fora das trilhas.
- Plantas e adornos respeitam água, paredes, pontes e espaço dos caminhos. Os sprites são ancorados no último pixel visível, usam filtro nearest e participam do Y-sort. Arbustos e flores recebem o vento já existente.
- Cenas pintadas, missões, saídas e sprites originais permanecem preservados. A integração ocorre em uma camada independente `MapArt`.

## Validação

| Verificação | Resultado |
|---|---|
| Integridade dos PNGs importados | 14 de 14 iguais às fontes, byte a byte |
| Regressão existente | 6.076 verificações, zero falhas |
| GdUnit | 7 casos, zero erros ou falhas |
| Integração do acervo | 4.565 verificações, zero falhas |
| Profundidade no Godot nativo | 111 comparações, zero falhas |
| Natação | 32 verificações nos seis habitats, zero falhas |
| Pontes | 5 travessias com o controlador real, zero falhas |

A profundidade foi testada mantendo a hierarquia dos mapas: base inferior com planta na frente, parte superior com personagem atrás e passagem para a frente. Os testes incluem plantas, banco, poste e ruínas recém-inseridos. A natação usa passos físicos fixos; as capturas são renderizações reais do Godot 4.7.2 em 1280 × 720.

## Capturas finais

- [Clareira](FlorestaDoDespertarV2_clareira.png)
- [Bosque dos Cogumelos](FlorestaDoDespertarV2_cogumelos.png)
- [Círculo Musgoso](FlorestaDoDespertarV2_musgo.png)
- [Caminho das nascentes](FlorestaDoDespertarV2_poste.png)
- [Lagoas](ValeDasNascentes_lagoas.png)
- [Margem leste](ValeDasNascentes_margem_leste.png)
- [Aproximação da ponte](ValeDasNascentes_poste.png)

Comparações antes/depois dos mesmos pontos ficam em `comparacao/`. Logs e contagens estão nesta pasta. A camada fica pronta após o primeiro passo de física; os testes aguardam sua instalação.

Nenhum download, geração ou crédito PixelLab foi necessário. Reinicie a execução atual no Godot para carregar os novos recursos.
