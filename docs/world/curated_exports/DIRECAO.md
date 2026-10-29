# Integração dos sprites exportados

## Direção
Usar o acervo já organizado para variar vegetação e contar pequenas histórias nos pontos existentes. Floresta: flores claras, grupos de cogumelos, pedras musgosas e vestígios antigos; vale: margem pedregosa, vegetação baixa e sinalização discreta nas aproximações das pontes. Sem novos edifícios, lavouras, missões ou geração paga.

## Implementação
14 recursos copiados com PNG e metadados intactos. Substituição parcial e determinística de decoração existente, conservando as bases e a ocupação visual. Pequenos conjuntos adicionais fora das rotas, da água e das paredes. Objetos sólidos novos recebem colisão localizada na base; plantas permanecem atravessáveis. Todo elemento participa da ordenação por Y e usa filtro nearest.

## Validação
Comparar capturas nativas antes/depois nos mesmos pontos. Conferir integridade dos PNGs, posições na terra, distâncias das trilhas, pivôs, colisões e travessias. Reexecutar a regressão de profundidade e natação. Preservar cenas e ajustes locais; integrar na mesma branch de revisão.
