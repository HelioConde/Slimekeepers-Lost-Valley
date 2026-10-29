# Áudio ambiental original

`scripts/world/forest_audio.gd` sintetiza cinco clipes PCM mono de 22.050 Hz: vento filtrado (11,7 s), água (8,3 s) e três cantos curtos. Não foram baixadas gravações nem incorporadas obras de terceiros. A origem é o algoritmo do próprio projeto; nenhum crédito PixelLab foi consumido.

A geração é incremental, 2.048 amostras por frame, com cache reutilizado na sessão. Os leitos usam crossfade na junção do loop. Existem somente três players: vento global, água posicional e uma ave ocasional. Floresta densa/cogumelos atenuam o vento; água aumenta gradualmente ao aproximar-se das fontes. O mix usa ganhos baixos e eventos espaçados.

Opções do menu: volume ambiente de 0 a 100 e silenciar ambiente. Preferências em `user://presentation.cfg`, seção `audio`, chaves `ambient_volume` (0..1) e `muted` (bool). Nenhuma preferência do usuário foi alterada pelo teste automatizado.

Teste `tools/test_forest_audio.gd`: formato PCM, cinco clipes, amplitude não nula e abaixo de clipping, limite de volume, fade pela distância, mute e orçamento de três vozes. É validação técnica; qualidade subjetiva de áudio ainda precisa de escuta humana.
