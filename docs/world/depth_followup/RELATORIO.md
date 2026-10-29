# Correções de profundidade, contato e natação

Validação concluída em 29/10/2026, Godot 4.7.2, renderizador Compatibility, capturas reais 1280 × 720.

## Resultado

- Vegetação pintada no TileMapLayer agora compartilha Y-sort com o personagem. Cada tile usa a base visível como referência; grama rasteira permanece abaixo dos pés. O TileSet é duplicado em memória: PNGs e recurso original preservados.
- Os testes anteriores isolavam objetos e não reproduziam a hierarquia do TileMap. O novo teste usa os pais, transformações e células dos mapas reais. Antes da correção, cinco casos falharam.
- Para cada amostra: personagem na base inferior (planta na frente), na metade superior (personagem atrás), e após cruzar para a frente (personagem na frente). 48 comparações de pixels passaram, incluindo flores, cultivo, três cogumelos, samambaia, arbustos e troncos nas duas regiões.
- Colisão do jogador concentrada nos pés: retângulo 18 × 12, deslocamento (0,-6). A aproximação física da árvore e da pedra caiu de 34 para aproximadamente 12 pixels de distância entre bases. Movimento, arte e velocidades preservados.
- Removida em memória vegetação que nasce ou atravessa faces verticais: 53 elementos na floresta e 129 no vale. Nenhum sprite original apagado.
- Esquilo: escala 0,75 → 1,0, aumento de 33%; altura visível de aproximadamente 59% do protagonista. Pássaro mantém escala 0,70. As capturas de comparação posicionam o animal real e o jogador numa clareira para tornar a escala legível.
- Bolhinhas escolhem destinos realmente submersos, contornam obstáculos com caminhos locais e entram/saem da água. Só os 26 corpos identificados como água são exceções de colisão para eles. Pedras e barrancos continuam sólidos; o jogador continua bloqueado pela água. Ondulações e parte inferior submersa distinguem a natação.
- A cena local tinha perdido os campos de peixes e plantas submersas; foram restaurados os dois campos da versão anterior, preservando os ajustes locais de cachoeiras e geometria.

## Evidências

| Verificação | Resultado |
|---|---|
| 14 scripts de regressão | 6.076 verificações, zero falhas |
| GdUnit | 7 casos, zero falhas |
| Profundidade real dos mapas | 48 comparações, zero falhas |
| Contato físico com árvore e pedra | 2 aproximações, zero falhas |
| Natação nos seis habitats | 32 verificações, zero falhas |
| Pontes com movimento real | 5 travessias, zero falhas |

A natação usa física real com passos fixos acelerados para validar ida e volta; não representa uma sessão manual cronometrada. Os testes de profundidade isolam a visibilidade dos objetos, mantendo sua hierarquia original. As imagens de cenário complementam essas comparações.

- [Base inferior](final_FlorestaDoDespertarV2_tile_6_lower_base.png)
- [Parte superior](final_FlorestaDoDespertarV2_tile_6_upper_half.png)
- [Após cruzar para a frente](final_FlorestaDoDespertarV2_tile_6_front.png)
- [Esquilo na nova escala](squirrel_after.png)
- [Barranco corrigido](cliff_plants_after.png)
- [Slime na água](swimming_V01.png)
- [Regressão](regression.log)
- [Dados de profundidade](final.json)

Nenhuma geração paga utilizada nesta correção. Reiniciar a execução aberta no editor para carregar os scripts atualizados.
