# Validação final — ciclo de dia e noite

Engine: Godot 4.7.2. Capturas nativas: 1280 × 720.

- 19 scripts de regressão concluídos sem falhas ou erros de script; 98 verificações específicas do relógio.
- GdUnit: 7 casos, 0 falhas, 0 órfãos.
- Projeto primário: teste do relógio repetido, 98 verificações aprovadas.
- 12 imagens inspecionadas: manhã, dia, tarde, anoitecendo, noite e madrugada em cada região.
- Comparação automática dos pixels: HUD estável; trilhas e água escurecem; noite e madrugada distintas.

| Região | p50 quadro | p95 quadro | Luminância dia / noite / madrugada |
|---|---:|---:|---|
| FlorestaDoDespertarV2 | 6.93 ms | 9.39 ms | 0.398 / 0.247 / 0.201 |
| ValeDasNascentes | 5.62 ms | 12.82 ms | 0.459 / 0.286 / 0.232 |

Amostra de 60 quadros após aquecimento por mapa, na máquina local, com outros aplicativos abertos. Não substitui exploração prolongada ou benchmark em hardware mínimo.

Iluminação ambiente com reflexos solares e lunares estilizados sobre a água. Sombras direcionais e raios solares permanecem fora desta implementação.

## Capturas

### FlorestaDoDespertarV2
- [manha](FlorestaDoDespertarV2_manha.png)
- [dia](FlorestaDoDespertarV2_dia.png)
- [tarde](FlorestaDoDespertarV2_tarde.png)
- [anoitecendo](FlorestaDoDespertarV2_anoitecendo.png)
- [noite](FlorestaDoDespertarV2_noite.png)
- [madrugada](FlorestaDoDespertarV2_madrugada.png)

### ValeDasNascentes
- [manha](ValeDasNascentes_manha.png)
- [dia](ValeDasNascentes_dia.png)
- [tarde](ValeDasNascentes_tarde.png)
- [anoitecendo](ValeDasNascentes_anoitecendo.png)
- [noite](ValeDasNascentes_noite.png)
- [madrugada](ValeDasNascentes_madrugada.png)

## Complemento: reflexos na água

- 30 verificações dos reflexos aprovadas na branch e no projeto principal.
- 98 verificações do relógio e 20 de água/cachoeiras aprovadas após a integração.
- Capturas renovadas em seis horários; comparação ligada/desligada e animação aprovadas nos dois mapas.
- Projeto principal preservado com zoom local 0,8. A suíte geral desse diretório parou no teste antigo que exige 1,14; os arquivos de câmera/personagem não foram alterados nesta entrega.
- Regressão completa da branch com reflexos: 19 scripts e 7 testes GdUnit aprovados, sem erros de script. Logs em `reflection_regression/`.
