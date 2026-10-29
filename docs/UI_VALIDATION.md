# Menu do vale — implementação e revisão visual

Evidência mais recente: `SPRITE_POLISH.md`, de26/10/2026, com solo texturizado, caminho curvo, objetos novos, Y-sort e nova placa do título.

**Atualização com o ZIP fornecido:** a validação mais recente passou em42 verificações. A paisagem distante ilustrada e os novos objetos estão documentados em `PROVIDED_PACK_INTEGRATION.md`, com capturas `menu_pack_final_*`. O relatório abaixo preserva a comparação da primeira etapa, anterior ao pacote.

Destino: `C:\Slimekeepers_Lost_Valley_v0_1`. Data: 25/10/2026. Referência atual: `docs/references/menu_quality_target.png`, a fazenda com casa à esquerda, vale ao fundo, logo superior e quatro ações à direita. Esta cópia não possui Git. Nenhum commit ou push foi realizado.

## Escopo confirmado na base

A cena principal anterior era `scenes/world.tscn`, sem menu. A janela era 1280×720 sobre canvas lógico 960×540; terreno de32px; personagem em canvas128px com escala0,65 e câmera1,14. A base contém somente movimento, corrida, interação e amizade com Gelito, Brotinho e Brasinha. Não contém inventário, coleta, ferramentas ou saves. Esses sistemas não foram inventados nem copiados da outra pasta.

O gameplay mantém seu canvas, escala, missão, sprites e animações. A HUD recebeu painéis responsivos e um botão para retornar ao menu. Uma variável de nome de animação recebeu tipo String explícito para corrigir o erro de compilação no jogador. A configuração e os dois scripts preexistentes alterados estão respaldados em `docs/backups/`; o LEIA-ME também foi atualizado com instruções e resultados atuais.

## Cena implementada

- `scenes/start_menu.tscn`: nova abertura e cena principal.
- `scripts/menu/start_menu.gd`: logo, ações, navegação, opções e layout responsivo.
- `scripts/menu/menu_theme.gd`: tema reutilizável com marfim, madeira, ameixa e menta; estados normal, hover, foco, pressionado e desabilitado.
- `scripts/menu/board_details.gd`: contornos, parafusos e folhas separados dos textos.
- `scripts/menu/valley_sky.gd`: céu, montanhas, bosques, escarpas, rio, nuvens e quedas d'água em camadas.
- `scripts/menu/farm_foreground.gd`: casa, canteiros, cercas, protagonista, vegetação e slimes com sombras e pequenos pulos.

Nenhuma imagem de menu completo foi utilizada. Os textos usam Pixelify Sans no Godot. Sprites do primeiro plano recebem escala uniforme inteira na composição1280×720; vegetação distante usa amostragem Nearest reduzida e transparência atmosférica. A apresentação amplia proporcionalmente em janelas maiores, mantendo a UI separada. O menu usa coordenadas físicas e restaura o canvas960×540 ao entrar no mundo.

Continuar está desabilitado e seu tooltip explica a ausência de salvamento. Opções oferece redução de movimento persistida em `user://presentation.cfg`, tela cheia e retorno. Esc fecha o painel. O foco fica dentro da janela de opções e retorna ao botão ao fechar. Sair chama o encerramento do SceneTree. Os controles WASD/Shift/E ficam apenas na HUD de gameplay.

## Capturas e ciclo de correção

Capturas são do viewport real do Godot4.7.2, renderer OpenGL Compatibility, RadeonRX580; não são montagens nem saídas de IA.

| Evidência | O que mostra |
|---|---|
| `ui/captures/menu_first_1280x720.png` | Primeira montagem: camada de água sobre os botões, vale simples e canteiros excessivos. Não é um menu anterior do projeto, pois ele não existia nesta cópia. |
| `ui/captures/menu_final_1280x720.png` | Resultado após corrigir ordem das camadas, horta, vegetação, título, flores e espaçamento. |
| `ui/captures/menu_final_960x540.png` | Revisão menor: botões mais estreitos e compactos, três slimes visíveis, título e rodapé sem corte. A casa e as bordas do ambiente são reenquadradas. |
| `ui/captures/menu_large_1920x1080.png` | Composição e UI ampliadas, sem faixas vazias no fundo. |
| `ui/captures/options_review_960x540.png` | Opções legíveis em janela pequena, foco destacado e escurecimento do fundo. |
| `ui/captures/gameplay_final_1280x720.png` | HUD consistente, missão real e controles no lugar apropriado. O mundo original foi preservado. |

Correções após a primeira captura: água atrás da UI; cristas montanhosas menos geométricas; agrupamentos de árvores; substituição da repetição de caixas por fileiras de plantio; ajuste da escala do título; botão principal creme; largura menor de botões para não cobrir Brasinha em960×540; enquadramento e escala em1920×1080. Também foi corrigida a reativação das animações quando a redução de movimento já estava salva.

## Testes reproduzíveis

```powershell
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Slimekeepers_Lost_Valley_v0_1' --script res://tools/test_menu.gd
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'C:\Slimekeepers_Lost_Valley_v0_1' --rendering-method gl_compatibility --script res://tools/capture_ui.gd -- menu final 1280 720
```

O teste de integração executou **40 verificações, zero falhas**. Cobertura: quatro ações e estado desabilitado; foco inicial; setas e ciclo de navegação; eventos D-pad simulados; Enter; Tab restrito ao modal; Esc e restauração de foco; clique de mouse em Opções e Novo Jogo; transição para o mundo; restauração do canvas; amizade por E com os três slimes; contador sem duplicação; mensagem de missão concluída; retorno pela HUD. Preferências já existentes não são alteradas pelo teste. Log em `ui/menu_integration.log`.

O controle foi validado com eventos Godot simulados, sem teste em dispositivo físico. A captura em1920×1080 verifica tamanho de janela, não todos os monitores/modos exclusivos de tela cheia. As animações foram executadas no runtime; screenshots não demonstram sua qualidade temporal. Não houve teste de distribuição/exportação.

## Comparação artística com a referência

Notas editoriais para esta entrega, não métricas automáticas de aprovação:

| Critério | Meta | Avaliação | Evidência / limite |
|---|---:|---:|---|
| Pixel Art | 9 | 8 | Casa, protagonista e slimes nítidos; paisagem desenhada tem menos detalhe. |
| Coerência de estilo | 9 | 7 | Paleta compartilhada; densidade de detalhe ainda varia entre montanhas, casa e vegetação. |
| Cenário e composição | 9 | 7 | Casa, horta, vale e ações seguem a nova hierarquia; menos exuberância que a referência. |
| UI e legibilidade | 9 | 8 | Texto real, foco claro e três resoluções conferidas; logo é mais simples que o ilustrado. |
| Profundidade e iluminação | 8 | 7 | Planos atmosféricos, rio e sombras de contato; falta iluminação volumétrica e riqueza material da referência. |
| Animações | 8 | 7 | Idle original, pulos, nuvens e água; protagonista decorativa usa pose original estática. |
| Integração dos slimes | 9 | 8 | Três espécies originais, proporções mantidas, sombras e vegetação próxima. |
| Qualidade técnica | 9 | 9 |40checks sem falhas, componentes separados e gameplay preservado; controle físico/exportação pendentes. |

**A implementação não supera o acabamento da referência.** A etapa de menu funcional e composição está concluída; refinamento artístico adicional do vale, logo e iluminação permanece como oportunidade concreta. Nenhuma afirmação de acabamento comercial integral é feita. Não foram criados hotbar ou inventário porque eles não existem nesta base.

Gerações PixelLab e consumo estão documentados em `ASSET_MANIFEST.md`. A casa foi a terceira chamada da rodada; não houve novas gerações após ela.
