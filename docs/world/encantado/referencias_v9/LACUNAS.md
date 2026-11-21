# Referências V9 — lacunas em relação ao jogo (2026-11-21)

Referências: `ref_1` (rio à noite, ponte), `ref_2` (bosque de cogumelos à noite), `ref_3` (clareira com lago à noite), `ref_4` (clareira com lago às 18h), `ref_5` (mirante com escada de pedra às 17h30).
Comparadas com as capturas reais das etapas V8 (`09`–`13` nesta pasta).

| # | Lacuna | Onde aparece | Esforço |
|---|---|---|---|
| 1 | **Sombras longas** de troncos atravessando a grama ao entardecer, em faixas diagonais | ref_4 | código (DayShadows já tem direção e comprimento; falta alongar e opacidade) |
| 2 | **Névoa noturna** baixa, em faixas azuladas sobre a grama e a água | ref_1, ref_2, ref_3 | shader/partículas |
| 3 | **Halo de chão** dos cogumelos e slimes: círculo de luz ciano na grama em volta | ref_2, ref_3 | código (já há halo; falta luz no chão mais ampla) |
| 4 | **Copas mais saturadas e douradas** no topo de dia e ao entardecer (lima/amarelo forte) | ref_4, ref_5 | parâmetros (a V8 tinha reduzido; as novas referências pedem o oposto) |
| 5 | **Cogumelos vermelhos com brilho quente** próprio (pequeno halo laranja), também de tarde | ref_4, ref_5 | código |
| 6 | **Água noturna**: coluna de reflexo da lua, ondas claras, nenúfares com flor, margem com espuma | ref_1, ref_3 | shader + 1 sprite (nenúfar com flor) |
| 7 | **Faíscas/partículas mágicas** abundantes (pontos brancos e dourados) | todas | parâmetros de partículas |
| 8 | **Slimes luminosos** azuis em grupo | ref_1 | integração (Bíblia) |
| 9 | Margens elevadas com **barranco de terra** (rio) e **muros/escadas de pedra** (mirante) | ref_1, ref_5 | tileset novo |
| 10 | Grade noturna mais **azul-petróleo** e clara, sem esconder o chão | ref_2, ref_3 | parâmetros (WorldGrade) |
