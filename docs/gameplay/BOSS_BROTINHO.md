# Primeiro Boss: Brotinho Gigante (Mapa 1, Floresta)

Decisões do usuário em 2026-11-27. Este é um documento vivo: o combate vai ser revisto várias vezes ("épico e polido"). A Bíblia Narrativa define que Boss Slimes são **anomalias** (slimes que absorveram magia demais), não vilões, e que combate e comida contam igual para o progresso.

## Decidido

| Tema | Decisão |
|---|---|
| Boss | Brotinho gigante, maior que o jogador. Há uma chance pequena de vir o **Musguinho gigante** no lugar. |
| Onde | Mirante Rochoso, com pelo menos 1 **cristal de energia** no local. Pela Bíblia (palavras do usuário), o boss aparece pela quantidade de magia no ambiente, e quem define essa energia são os cristais de energia. |
| Quando aparece | Ao completar uma tarefa que ainda vamos definir (alimentar X slimes, ou derrotar…). No protótipo, a regra é provisória e configurável (ver "Gatilho"). |
| Desvio | **Rolamento com Espaço.** O boss avisa o golpe (área marcada no chão + pose de carga); rolar na hora exata deixa o boss aberto para um golpe forte. |
| Rotas | Combate agora; a rota da comida (alimentar o boss) entra numa etapa seguinte, com o mesmo boss. |
| Armas | Espada e arco **fabricados na bancada**; o arco gasta flechas (graveto + pedrinha). |
| Derrota | Acorda em casa (ou no início) com metade da vida, **sem perder itens**; o boss volta com a vida cheia. |
| Arte | **Protótipo com a arte atual** (Brotinho ampliado, golpes simples). A arte nova entra quando o PixelLab for autorizado e a jogabilidade estiver aprovada; prévia em GIF antes de instalar. Slimes nunca têm braços nem pernas. |
| Vitória | A magia sai como **orbe de energia** (para a máquina do final) e os slimes da área ficam **mais pacíficos**. Em dupla, o boss tem mais vida e os dois ganham. |

## Liberar o boss, slimes agressivos e pet (decisões do usuário, 2026-11-27)

| Tema | Decisão |
|---|---|
| Regra provisória para o boss aparecer | Pontos dos slimes **definidos no mapa** (Floresta): matar vale 1 e domar vale 5; com **20 pontos** o boss aparece. Rotas de exemplo: matar 20, domar 4, ou matar 10 e domar 2. |
| Domar | É a amizade que já existe (dar comida até virar amigo). Amigos que o jogador já tem contam desde já. |
| Dificuldade | Sai da mistura: só domar = fácil, mistura = médio, só matar = difícil. Muda a **vida do boss** (fácil 70%, médio 100%, difícil 130%). |
| Matar slime | Espada e flecha acertam slimes normais. Morto, ele some, solta **gosma da espécie** e o spawn o traz de volta depois de **2 dias**. Slimes amigos são protegidos (golpes passam sem acertar). |
| Slimes agressivos | Antes de vencer o boss, slimes não amigos atacam quem chega perto (pulo avisado), mas **não perseguem** se o jogador corre. Com comida na mão eles não atacam, para dar para fazer amizade. O slime do tutorial perto da casa nunca ataca. A **Bolhinha** (água) não ataca: foge do jogador. Dano: **6** de vida na área inicial. Depois do boss vencido, a área fica pacífica. |
| Pet | No disco de um slime amigo, "Levar comigo": ele segue o jogador (um por vez); "Deixar aqui" devolve ao habitat. Na luta: **Brotinho** atira projéteis no boss, **Bolhinha** cura o jogador, **Musguinho** deixa o boss lento por alguns segundos. O pet toma dano dos golpes do boss, é mais resistente que o jogador e, se desmaiar, volta para casa até o dia seguinte. |

Implementação (2026-11-27): `scripts/combat/forest_threat.gd` (pontos, dificuldade, mortos, pet), `scripts/world/forest_slime.gd` (vida 30, ataque avisado de 0,45 s com pulo de até 40 px, recarga 1,6 s; Bolhinha foge a 120 px), `scripts/combat/slime_pet.gd` (pet: vida 150; Brotinho atira a cada 2,2 s com dano 4; Bolhinha cura 10 a cada 6 s; Musguinho deixa o boss lento por 3 s a cada 10 s; preso atrás de obstáculo por 1 s, reaparece ao lado). Hoje a Floresta só tem Brotinho e Musguinho nos habitats (sem Bolhinha). Gosmas com ícone provisório. Teste: `tools/test_forest_threat.gd`. Comando de admin `pet`: faz amizade com o slime mais perto e o leva junto.

## Protótipo (primeira versão jogável)

- **Arena:** o **Mirante Rochoso** (Floresta, centro 5110,1250), escolhido pelo usuário. O platô foi ampliado de 470×310 para 660×430 (`tools/combat/grow_lookout.gd`), com autorização para priorizar o combate. Arena em elipse de 300×190. Ao entrar com o boss liberado, um anel de raízes fecha a arena e a barra de vida do boss aparece no alto da tela.
- **Cristal de energia (regra do usuário, 2026-11-27):** o boss aparece pela magia acumulada no ambiente, definida pelos cristais de energia. Onde o boss surge há pelo menos 1 cristal, e o boss sai dele. O cristal escuro feito no PixelLab (`magic_crystal_detailed_64x96_ae2e88e2`) fica na ponta do platô, na borda de trás. A `BIBLIA_NARRATIVA.md` deste repositório ainda não fala dos cristais; vale incluir quando você autorizar.
- **Brotinho gigante:** cerca de 3× o tamanho normal, com 300 de vida. Golpes, todos avisados antes:
  1. **Raízes:** três círculos marcados sob o jogador em sequência. O boss lança uma semente em arco, que cai **depois que a zona some**; aí as raízes sobem e dão dano.
  2. **Pancada:** o boss salta alto até onde o jogador estava (ele mesmo é o projétil, com a zona marcando onde cai) e só dá dano ao pousar, depois que a zona some.
  - Regra (teste do usuário, 2026-11-27): ataque em área sempre tem um projétil visível e só acerta depois que a zona vermelha desaparece (0,15 s depois). Avisos: raízes 1,2 s (fase 2: 0,85 s); pancada 1,5 s (fase 2: 1,1 s).
  3. **Chuva de sementes:** carrega e solta sementes em leque.
  - Com metade da vida: avisos mais curtos e combinações de golpes.
- **Jogador:** vida 100 (a barra do HUD que já existe).
  - Espada: golpe largo em arco de 140° à frente, com alcance de 110 px até a borda do alvo, como no Stardew. Dá para acertar de longe e correr (pedido do usuário, 2026-11-27). Um rastro branco mostra o arco.
  - Arco: atira para onde o **mouse** aponta, com alcance de 380 px (a flecha cai no limite); gasta 1 flecha (teste do usuário, 2026-11-27).
  - Rolamento (Espaço): ~0,35 s sem tomar dano e tempo de recarga; rolar logo antes do impacto ("rolamento perfeito") abre o boss por ~2 s, com dano dobrado.
- **Ataques do jogador nunca falham (teste do usuário, 2026-11-27):**
  - Com espada ou arco na mão, o clique ataca em qualquer ponto da tela (antes só valia a até 96 px do jogador, alcance de coleta).
  - A espada corta para onde o mouse mirou; o arco atira para o mouse; [F] usa o mouse também.
  - A área de acerto do boss é o próprio desenho dele (folha e bordas contam), não só um círculo no centro.
  - Clique feito no meio de um golpe ou rolamento entra na fila e sai assim que der.
  - A barra de vida do boss não pega mais o clique (antes, clicar no boss perto do topo da tela não atacava).
  - Com arma na mão, [F]/clique não abre o disco do slime nem a bancada.
  - Cada acerto mostra o número de dano subindo (amarelo e maior quando o boss está zonzo).
- **Ordem de desenho:** o boss e o cristal são ordenados pela altura na tela junto com o jogador, com o pé como referência: abaixo do pé do boss o jogador fica na frente, acima fica atrás. Avisos no chão, impactos, sombras e o anel de raízes ficam numa camada de chão, sempre sob o jogador; projéteis no ar ficam por cima de tudo.
- **Testes:** `tools/test_boss.gd` (regras), `tools/test_boss_input.gd` (mouse e teclado de verdade: 8 lados × 5 partes do boss × espada e arco, [F], fila e 8 s com o boss atacando, vida infinita) e `tools/test_boss_zorder.gd` (captura da tela: frente, atrás, aviso sob o jogador, cristal).
- **Vida infinita para testar:** o atalho `tools/play_boss.gd` já liga; no jogo, o comando de admin `imortal` ([F1]) liga e desliga. Não vai para o save.
- **Gatilho provisório:** ver "Liberar o boss" acima (20 pontos). Também há um comando de depuração para testes.

## Arte instalada (PixelLab, aprovada em 2026-11-28)

Espada (varrida com rastro de luz), arco (puxa, segura, solta), esquiva rápida (no lugar do rolamento), Brotinho e Musguinho Gigantes (parado, carga, pouso, golpe recebido, zonzo), raízes e poeira da pancada (VFX Creator), flecha, semente do boss e os ícones de espada, arco, flecha, orbe e gosmas. Instaladores em `tools/pixellab/install_sword.py`, `install_bow_dash.py` e `install_boss.py`. Prévias em `docs/gameplay/previa_*`. A foice (itens 08 e 31 do relatório) continua com a arte de 23/11, esperando o playtest.

## Arte e animação futuras (lista original)

Hoje tudo usa arte provisória: sprites atuais ampliados ou formas desenhadas por código. Cada item precisa de prévia em GIF antes de instalar. Slimes nunca têm braços nem pernas.

| Item | O que existe hoje | O que precisa |
|---|---|---|
| Brotinho Gigante | Brotinho normal ampliado 3× | Sprite grande próprio, com idle, carga (achatar), salto, pouso, golpe recebido, zonzo e encolher na derrota |
| Musguinho Gigante | Musguinho normal ampliado | O mesmo conjunto do Brotinho Gigante |
| Golpe de espada do jogador | Animação do machado + meia-lua branca desenhada | Animação própria de espada nas 4 direções, no padrão de golpe aprovado (sobe, desce reto, impacto) e rastro do corte em pixel art |
| Tiro com arco do jogador | Sem animação | Animação de puxar e soltar o arco nas 4 direções |
| Rolamento do jogador | Sprite andando, só deslocado | Animação de rolar nas 4 direções |
| Flecha | Linha desenhada por código | Sprite da flecha voando e caída no chão |
| Semente das raízes (projétil) | Bolinha desenhada | Semente girando no ar e sombra |
| Raízes subindo | Círculo marrom que some | Raízes saindo do chão (efeito curto) |
| Chuva de sementes | Bolinhas desenhadas | Semente pequena em voo |
| Aviso no chão | Círculo vermelho desenhado | Marca de aviso em pixel art (opcional) |
| Impacto da pancada | Círculo e tremor da tela | Poeira e rachadura no chão |
| Cristal de energia | Arte do PixelLab já instalada (`ae2e88e2`) | Brilho pulsando ou animação de energia (opcional) |
| Anel de raízes da arena | Pontos desenhados | Cerca de raízes em volta da arena |
| Orbe de energia | Ícone provisório gerado por script | Ícone e orbe no mundo, flutuando |
| Ícones de espada, arco e flecha | Provisórios gerados por script | Ícones em pixel art no estilo do inventário |

## Em aberto (decidir nas revisões)

- A tarefa definitiva que libera o boss (quantos slimes alimentar, ou o que derrotar).
- Valores finais de vida, dano, tempos de aviso e recarga (ajuste em playtest).
- Rota da comida: o que o boss aceita e como ela dá o orbe.
- Sincronização do boss no multijogador: o protótipo começa solo; em dupla, o anfitrião manda no boss.
- Quantos bosses existem e a função do orbe na máquina final (Bíblia: EM ABERTO).
