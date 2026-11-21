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

## Estado em 2026-11-21 (após 6526093 … 07bb5b0)

| # | Lacuna | Estado |
|---|---|---|
| 1 | Sombras longas ao entardecer | Feito: faixas diagonais com comprimento por tronco + feixes dourados no chão (1cca9b7) |
| 2 | Névoa noturna | Feito, mínima de propósito (e991933) |
| 3 | Halo de chão de cogumelos e slimes | Feito (e991933, 6526093) |
| 4 | Copas douradas | Feito (eac7f42, 1cca9b7) |
| 5 | Cogumelos vermelhos quentes | Feito (e991933) |
| 6 | Água noturna, lua, vitórias-régias | Feito (59ce2ee … c71e123) |
| 7 | Faíscas mágicas | Feito (eac7f42) |
| 8 | Slimes luminosos | Aura nos existentes (6526093); grupos novos dependem da Bíblia |
| 9 | Barrancos e escadas de pedra | Margens do rio feitas (b3d5f21); escadaria do mirante não existe no mapa |
| 10 | Noite azul-petróleo mais clara | Feito: cor média igual à das referências (07bb5b0) |

Ainda diferente: as referências são ilustrações com mais densidade de flores e brilho (bloom) do que o jogo usa; mantemos pixel art nítida. Acampamento com fogueira na Clareira e ponte com lanternas não existem no mapa (decisão de design pendente). `MAP_DEPTH` mantém 1 falha antiga (cogumelo do Vale), anterior a esta etapa.

## Fechamento (2026-11-21, até 9ea5b20)

- Entardecer 18h: média 81/88/29 contra 92/83/34 na ref_4; contraste (desvio de luminância) 46.3 contra 45.3. Feixes dourados, sombras longas, lago com borda dourada.
- Noite: média 26/63/76 contra 29/63/79 na ref_6 e 23/63/78 contra 24/65/75 na ref_2. Luar em feixes, poças ciano, flores mágicas, vagalumes.
- Rio à noite: 22/53/89 contra 33/67/86 na ref_7. Lua, vitórias-régias rosa, juncos ciano, cachoeira branco-ciano e **plantas-lanterna** nos quatro cantos das pontes. Faz o papel das lanternas sem presença humana.
- Fogueira: existe no acampamento/estação de cozinha do Vale; não foi criado acampamento novo na Clareira (o mundo não tem humanos e a Clareira fica aberta).
- Diferenças mantidas de propósito: sem bloom borrado (pixel art nítida, pedido do usuário); centro da Clareira aberto (pedido da V8), com flores na borda das copas e na margem do lago.
