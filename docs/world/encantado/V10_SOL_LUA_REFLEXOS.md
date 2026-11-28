# V10 — Sol, Lua e reflexos (2026-11-21)

## Causa do bug
Quatro "luas" independentes, duas presas à vista:
- `valley_region._update_moon_reflection` escolhia a âncora da Lua a partir de `player.global_position` (um ponto ~160 px à direita e 110 px acima do jogador): o reflexo andava com o personagem.
- `water_reflections.gdshader` usava `SCREEN_UV` para a faixa de reflexo: presa à tela/câmera.
- `spring_water.gdshader` e `pond_magic.gd` tinham um disco fixo no lago, independente do céu.
Todas foram removidas; existe agora um único sistema.

## Correção
- `scripts/systems/astronomy.gd`: céu calculado só de `GameClock` (dia + minuto). Determinístico, contínuo na meia-noite.
- `scripts/world/water_reflections.gd(.gdshader)`: cada corpo d'água é amostrado na instalação (pontos dentro do polígono, fora das pontes). Uma malha fixa do mundo (1000 px) dá pontos ideais deslocados pela posição do astro; cada um vira a água mais próxima. Âncoras a menos de 900 px descartadas (um reflexo por vista). Tudo em coordenadas de mundo.

## Ciclo solar
Arco de 5h30 (nascer) a 19h30 (fim do crepúsculo), coerente com DayShadows/AmbientLights. Altura = sen(π·u); azimute leste→oeste. Reflexo solar some abaixo do horizonte; cor dourada de manhã, laranja ao poente.

## Ciclo lunar e fases
- Fase p = 0,45 + t / 29,53 dias (t absoluto). Fração iluminada f = (1 − cos 2πp)/2; oito nomes.
- A Lua usa o mesmo arco do Sol atrasado por p dias: dia lunar ≈ 24h49, nasce ~49 min mais tarde a cada dia (teste). Lua nova nasce com o Sol; cheia ao pôr do sol.
- Luar = f × altura (rampa suave no horizonte). Lua visível de dia se acima do horizonte e f > 0,04; reflexo diurno ≤ 8% do noturno.
- O luar controla: força do reflexo, feixes de luar (direção pelo azimute), borda azulada das copas e exposição noturna (WorldGrade). Fontes mágicas (slimes, cogumelos, flores, plantas-lanterna, fogueira) não dependem dele.

## Testes
- A/B (`tools/test_reflection_world.gd`, ponte oeste vertical do Vale pedida pelo usuário): 6 enquadramentos (4 posições do jogador, zoom 0,64/0,8/1,0). Concordância dos pixels de reflexo no mundo ≥ 0,98 às 3h30 e 22h30.
- C/D/E: capturas `36_`, `37_`, `38_` nesta pasta e tabela `V10_tabela_ceu.txt`.
- F: save guarda dia e minuto (sem mudança de formato); céu restaurado idêntico (gdUnit).
- gdUnit `test_astronomy.gd`: determinismo, ciclo solar, continuidade minuto a minuto por 3 dias, atraso de 40–60 min/dia no nascer da Lua, posição diferente a cada dia, 8 fases, Lua nova sem luar e cheia máxima, Lua diurna, âncoras só de água e céu, pontes bloqueiam, espaçamento mínimo.

## Limitações
Modelo estilizado: arco simétrico, sem latitude, sem declinação; azimute em tela (leste = direita); disco refletido simplificado; corpos de água pequenos têm uma âncora.
