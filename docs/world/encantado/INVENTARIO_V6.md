# Evolução visual V6 — inventário comparativo

Comparação entre a captura real (Clareira/Floresta V2, 07h–22h) e as referências diurna e noturna.
Classes: **A** configuração de luz · **B** shader/animação · **C** melhorar sprite existente ·
**D** sprite novo · **E** reorganizar a cena.

| Categoria | Referência | Jogo (antes da V6) | Classe | Estado |
|---|---|---|---|---|
| Copas das árvores | tufos com topo dourado, verde médio, base teal profunda | verde escuro quase uniforme, pouca luz localizada | B + D | **Protótipo**: luz de folhagem no shader de vento + `oak_lush`/`pine_lush` na borda oeste da Clareira (8f2ddc9) |
| Troncos e raízes | raízes abertas, casca com lado iluminado | troncos corretos, raízes curtas | D | Nos sprites novos; antigos mantidos |
| Diferença entre espécies | carvalho, pinheiro e arbustos bem distintos | 4 sprites, 3 deles carvalhos parecidos | D + E | Parcial: `oak_young` foi mantido para dar variedade |
| Luz nas folhas por horário | dourado com sol baixo, luar frio à noite | só grade de cor global | B | Feito (`foliage_profile`) |
| Raios de sol | muitos feixes com origem na copa e poeira | não havia | B | Feito (e2da5f7); faltam poeira dentro do feixe e balanço com o vento |
| Manchas de luz no chão | irregulares, em toda a clareira | só sob as copas | B | Existentes; faltam no centro aberto |
| Sombras | contato e direcionais coerentes | sistema DayShadows completo | A/B | Mantido; falta o modo de depuração visual pedido |
| Chão da clareira | flores em grupos, folhas caídas, pedrinhas, terra | grande área de grama lisa | D + E | **Pendente**: próximo passo do protótipo |
| Flores e plantas rasteiras | grupos por terreno, úmidas perto da água | tufos de tilemap espalhados | C + E | Pendente |
| Pedras | topo claro, lateral escura, musgo, contato | `mossy_rock` bom; `stone.png` simples | C | Avaliar |
| Cogumelos mágicos | ciano com pontos, esporos, luz suave | halo ciano + esporos (f4489cf) | B | Feito; falta variedade (azul/verde) |
| Flores mágicas | poucas, com centro brilhante | não há | D | Pendente |
| Vagalumes e poeira | orgânicos, cores variadas | enxames + poeira + brilhos | B | Existentes; revisar a sincronia |
| Água e cachoeira | espuma, névoa, reflexos, brilho | Vale animado (V4/V5) | B + D | Revisar no Vale |
| Noite | sombras azul-escuras, fontes coloridas | grade noturna azul-teal + luar nas copas | A + B | Feito; falta a luz local refletir nas copas |
| Slimes luminosos | fogo laranja, luz azul/dourada | Brasinha e Gelito com luz real | B | Integrar nas regiões jogáveis (consultar a Bíblia) |
| Paleta geral | saturada, quente e luminosa | grade de cor por horário (7679ea3) | A | Feito |

## Regressões verificadas durante a V6
- `SHADOW_OVERLAP` falhava desde a grade de cor (7679ea3): a vinheta escurecia o pixel de referência do chão. Corrigido no teste, que agora mede a sombra sem o pós-processo de tela.
- `MAP_DEPTH`: 1 falha determinística (cogumelo do Vale em (2758, 104), cenário "front", 4 px). Continua com o halo e a luz de folhagem desligados, então **não é da V6**. Investigar à parte.
