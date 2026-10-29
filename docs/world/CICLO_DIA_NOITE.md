# Relógio e ciclo de iluminação — Slimekeepers: Lost Valley

## Sistema inicial (implementado)

O mundo possui **seis períodos**, com transições contínuas de cor na tela, sem carregar novas cenas ou alterar os sprites originais.

| Período | Horário dentro do jogo |
| --- | --- |
| **Madrugada** | 00:00–04:59 |
| **Manhã** | 05:00–08:59 |
| **Dia** | 09:00–14:59 |
| **Tarde** | 15:00–17:59 |
| **Anoitecendo** | 18:00–19:59 |
| **Noite** | 20:00–23:59 |

- Cada partida nova começa **no dia 1, às 07:00 (manhã)**.
- A velocidade padrão é **24 minutos reais por dia completo de jogo**, configurável em `project.godot`, seção `[game]`, `time/seconds_per_day=1440.0`. Em execução, use `GameClock.seconds_per_game_day = 720.0` para um dia de 12 minutos. Valores não finitos ou não positivos retornam ao padrão de 1440 segundos.
- A progressão do tempo acontece **somente durante o gameplay**, para no menu, respeita o pause do SceneTree e **continua entre regiões** sem reiniciar o relógio.
- O relógio aparece na parte superior direita da interface, abaixo do botão Menu, mostrando dia, hora e período.
- A iluminação utiliza **CanvasModulate** e interpola uma paleta com manhã quente, luz clara de dia, tarde dourada, pôr do sol rosado e noite/madrugada azuladas. A noite permanece suficientemente clara para permitir exploração.
- O HUD fica em um `CanvasLayer` independente, não sendo escurecido pelo ciclo de luz.
- Os shaders de terreno, trilhas, água, margens e cachoeiras passam a respeitar CanvasModulate: a declaração `unshaded` impedia seu escurecimento. As animações, texturas, colisões e Y-sort foram preservados.
- Os três perfis ambientais existentes recebem um adaptador: manhã/dia → morning; tarde/anoitecendo → afternoon; noite/madrugada → night. Chuva, vento e neblina são preservados na viagem. Não existe outro relógio.

## Arquitetura

- `scripts/systems/game_clock.gd`: **autoload `GameClock`** com horário, calendário de dias, período e sinais.
- `scripts/world/day_night_lighting.gd`: componente de iluminação baseado em `CanvasModulate` instalado pelo controlador compartilhado.
- `scripts/ui/day_clock.gd` + `scenes/ui/day_clock.tscn`: visual reutilizável do relógio.
- `scripts/world.gd`: incorpora o componente às regiões que compartilham HUD.
- `scripts/menu/start_menu.gd`: interrompe o relógio no menu e reinicia a sessão em Novo Jogo.

## Sinais e integração

```gdscript
GameClock.time_changed.connect(_on_time_changed) # dia, hora, minuto
GameClock.period_changed.connect(_on_period_changed) # &"manha", &"dia", ...
GameClock.day_changed.connect(_on_day_changed) # dia final
GameClock.time_advanced.connect(_on_time_advanced) # minutos decorridos, dias atravessados
```

Consultas possíveis:

```gdscript
GameClock.get_time_text() # "07:00"
GameClock.get_period() # &"manha"
GameClock.get_period_label() # "Manhã"
GameClock.day_number # 1
```

Para testes ou um sistema futuro de sono:

```gdscript
GameClock.set_time(19, 45) # anoitecendo
GameClock.advance_minutes(60.0) # 20:45, noite
```

Preparação para salvamento futuro, **sem implementar o sistema de save nesta entrega**:

```gdscript
var data := GameClock.get_save_data()
var accepted: bool = GameClock.load_save_data(data)
```

O formato versionado é `{ "version": 1, "day": 1, "minutes": 420.0 }`, preservando frações de minuto. O carregamento aceita o formato antigo sem versão e rejeita dados inválidos sem alterar o relógio. Em saltos de vários dias, `day_changed` informa uma única vez o dia final e `time_advanced` informa o intervalo completo; consumidores futuros devem processar esse intervalo. `set_time` ajusta o horário para depuração sem simular progresso de agricultura.

A pausa usa `SceneTree.paused`; esta entrega não cria outro menu de pausa.

## Validar no Godot

Abra o projeto Godot 4.7.x e jogue normalmente. O relógio deve iniciar às 07:00, avançar um minuto de jogo a cada segundo real, mudar lentamente a iluminação e permanecer correto após entrar no Vale das Nascentes e voltar à Clareira.

Para validar rapidamente os períodos sem esperar 24 minutos, use o **Remote Inspector** ou o console de testes chamando `GameClock.set_time()`. Também existe `tools/test_day_night.gd` para execução headless:

```powershell
godot --headless --path . --script res://tools/test_day_night.gd
```

**Pendências futuras:** transição de música por período, rotina de NPCs e slimes, sono, clima, estações e salvamento completo. Nenhum desses sistemas é declarado pronto nesta entrega.

## Evidências da entrega de 29/10/2026

- Godot 4.7.2, testes headless e capturas nativas em 1280 × 720.
- `tools/test_day_night.gd`: 98 verificações de limites dos seis períodos, meia-noite, pausa real, menu real, Novo Jogo, viagem, salvamento e HUD em três resoluções. Inclui as duas regiões legadas e as duas atuais.
- `tools/validate_forest.ps1 -EvidenceFolder docs/world/day_night/regression`: 19 scripts de regressão dos mapas, fauna, água, profundidade, relógio e reflexos.
- `tools/capture_day_night.gd`: seis horários na mesma posição de cada região. Imagens e métricas em `docs/world/day_night/`. As animações são congeladas após aquecimento para comparação das cores; as imagens são renderizadas pela engine, não geradas por IA.
- A amostra de desempenho registra 60 quadros por região, p50/p95. É uma observação local curta, não um benchmark prolongado nem garantia para outras máquinas.
- Revisão estática independente concluída sem achados importantes. A regressão identificou um callback diferido após remoção da cena; o controlador agora verifica se ainda está na árvore antes de atualizar o ambiente.

As referências orientam a paleta. A implementação combina iluminação ambiente contínua e reflexos estilizados de sol/lua na água. Não adiciona sombras solares direcionais, feixes de luz nem um disco de lua no céu. A água conserva seus shaders animados existentes. Integrações completas de sono, NPCs, agricultura, música por período e save de jogo continuam futuras.

## Reflexos solares e lunares

`water_reflections.gd` instala uma camada transparente em cada Polygon2D que usa os shaders `spring_water` ou `valley_water`. A geometria é copiada exatamente; as margens, colisões e a fauna permanecem intactas. O shader `water_reflections.gdshader` desenha reflexos em faixas quebradas de pixels. A faixa ampla depende da visão da câmera, enquanto as ondulações usam coordenadas do mundo para evitar saltos ao andar.

A paleta, intensidade e posição seguem o mesmo GameClock: dourado pela manhã, discreto ao meio-dia, cobre ao pôr do sol e prata azulada à noite. A intensidade chega a zero na troca entre sol e lua, evitando mudança abrupta. A camada de reflexo ignora o escurecimento ambiente, mas a água abaixo continua recebendo CanvasModulate. Não é simulação física de céu ou ray tracing.

As ondulações atualizam a 8 passos por segundo e respeitam a opção de movimento reduzido de `presentation.cfg`. A pausa congela a animação. Para ajustar direção/intensidade, altere `STOPS` no componente; a largura e a frequência dos brilhos estão no shader.

`tools/test_water_reflections.gd` cobre 30 verificações de instalação, geometria, mudança de horário, continuidade e movimento reduzido. As capturas adicionais `*_reflection_off.png` e `*_reflection_motion.png` comprovam o efeito e a animação na engine; `tools/verify_day_night_captures.py` compara os pixels mantendo HUD e personagem intactos.
