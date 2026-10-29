# Mundo Vivo v3 — ambiente

> Registro intermediário da implementação. Os limites antigos de fauna, fixtures e pendências abaixo foram substituídos pelo [relatório final](RELATORIO_FINAL.md). Configuração final: um animal por região, 180 px de afastamento, reposição 22–38 s; esquilo escala 0,75 e pássaro 0,70, pivô pelo limite opaco. Testes finais usam os sprites reais.

## APIs e integração

`forest_life.gd` mantém `configure`, `configure_leaf_sources`, `open_area_test`, `shared_wind_material`, `set_reduced_motion` e `debug_snapshot`. A simulação continua centralizada a 8 Hz, com cache espacial de 256 px e consulta local à câmera. `living_region.gd` (integração dos mapas) utiliza as APIs adicionais:

- `get_wind_material("oak" | "pine" | "plant")`: três materiais compartilhados. Copas e plantas possuem ritmos/flexibilidade distintos; troncos, contatos com solo e colisões ficam imóveis. Proximidade dos atores é calculada nos vértices e não repetida por pixel.
- `register_reactor(Node2D)`: inclui slimes nas reações botânicas e na fuga das criaturas. Jogador é incluído automaticamente, máximo oito reatores locais. Movimento cria um impulso que relaxa em cerca de 0,6 s. Entradas duplicadas/instâncias removidas são filtradas.
- `configure_wildlife(Array[Vector2], Callable)`: âncoras globais e teste de chão seguro. Consulta física começa no primeiro tick, após `_ready`. O helper usa círculo de 7 px, máscara2 e limites do mapa; água do Vale tem colisão nessa camada.
- `configure_wildlife_frames("squirrel" | "bird", SpriteFrames)`: ativação apenas com recursos disponíveis. Animações `idle`, `walk`, `fly`, com fallback `default`. Sprites têm escala1 e alinhamento inferior consistente. Limite de dois indivíduos de cada espécie. Renderização por Sprite2D irmão do gerenciador para Y-sort; gerenciamento e descarte continuam centralizados.
- `set_environment_state(RefCounted)`: disponível em life/audio. `environment_state.gd` fornece `set_conditions(period, rain, wind, fog)` e `snapshot()`. Períodos aceitos: `morning`, `afternoon`, `night`; desconhecido vira morning. Chuva/neblina limitadas0–1, vento0–1,5. Não há calendário ou mudança autônoma de clima.

## Comportamentos

Borboletas têm quatro cores, duas larguras de asas, fases independentes, descanso em flores, voos orgânicos e fuga com cooldown6s. Depois da fuga retornam a flores antes de pousar. Folhas permanecem limitadas a8; frequência acompanha vento. A sombra de ave permanece limitada a1, intervalos25–60s e áreas abertas. Uma sombra de nuvem sutil percorre parte da câmera, com intervalos45–90s e supressão de novos eventos à noite.

Esquilos alternam descanso, busca local e fuga; pássaros descansam, saltitam e voam para fora quando assustados. Movimento terrestre é subdividido em passos de no máximo3px e testa chão antes de avançar. Criaturas distantes são removidas; retorno à região permite repovoamento respeitando cooldown8s. Nenhum script ou processamento por criatura.

Reduzir movimento congela o tempo decorativo e os animais, zera vento/impulsos e remove folhas e sombras em movimento. Culling local continua ativo.

Áudio preserva três players e geração PCM em lotes de2048 amostras. Sete clips cacheados: vento, água, três aves, insetos noturnos e folhas. Aves/insetos/folhas compartilham uma única voz eventual. Vento acompanha intensidade climática e abrigo; água responde à proximidade e discretamente à chuva. Volume/mute existentes preservados. Neblina é interface preparada, sem efeito visual adicional nesta implementação.

## Testes e evidências

- `test_environment_v3.gd`: 19 checks,0falhas; clamps, materiais, reatores, fuga das duas espécies, resting nas flores, limites em120s simulados, chão seguro, movimento reduzido, culling/retorno e descarte.
- `test_forest_life.gd`:16checks headless;22nativos OpenGL,0falhas. Imagens de teste confirmam copa pixelada em movimento, tronco/cor preservados, impulso vegetal com vento calmo e retorno ao repouso.
- `test_forest_audio.gd`:22checks nativos,0falhas/avisos. PCM, níveis, distância, mute e condições noturnas. Headless mantém aviso histórico de dois objetos de playback ao sair; não observado no teste nativo.
- `test_environment_regions.gd`:8checks e3352amostras físicas na primeira rodada limpa, usando os dois mapas reais e fixture de imagem enquanto assets wildlife aguardam entrega. Rodada posterior coincidiu com atualização de frames.tres Bolhinha antes de importação dos novos PNGs: engine reportou erros apesar das asserções locais passarem. Repetir após import antes de considerar a rodada final válida.

Logs: `environment_contract.log`, `environment_native.log`, `audio_native.log`, `environment_regions.log`. Testes de fixtures não constituem validação visual dos futuros sprites PixelLab; repetir o teste de regiões e captura depois da entrega dos assets.

Nenhum gasto PixelLab neste escopo. Sem alterações em cenas, layout, habitats ou scripts de slime. Performance final comparável fica a cargo do benchmark integrado; não se afirma ganho de FPS com base nestes testes isolados.
