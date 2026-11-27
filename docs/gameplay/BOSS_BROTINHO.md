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

## Protótipo (primeira versão jogável)

- **Arena:** o **Mirante Rochoso** (Floresta, centro 5110,1250), escolhido pelo usuário. O platô foi ampliado de 470×310 para 660×430 (`tools/combat/grow_lookout.gd`), com autorização para priorizar o combate. Arena em elipse de 300×190. Ao entrar com o boss liberado, um anel de raízes fecha a arena e a barra de vida do boss aparece no alto da tela.
- **Cristal de energia (regra do usuário, 2026-11-27):** o boss aparece pela magia acumulada no ambiente, definida pelos cristais de energia. Onde o boss surge há pelo menos 1 cristal, e o boss sai dele. O cristal escuro feito no PixelLab (`magic_crystal_detailed_64x96_ae2e88e2`) fica na ponta do platô, na borda de trás. A `BIBLIA_NARRATIVA.md` deste repositório ainda não fala dos cristais; vale incluir quando você autorizar.
- **Brotinho gigante:** cerca de 3× o tamanho normal, com 300 de vida. Golpes, todos avisados antes:
  1. **Raízes:** três círculos marcados sob o jogador em sequência; as raízes sobem depois do aviso.
  2. **Pancada:** pula até onde o jogador estava; a sombra no chão é o aviso; dano em área ao cair.
  3. **Chuva de sementes:** carrega e solta sementes em leque.
  - Com metade da vida: avisos mais curtos e combinações de golpes.
- **Jogador:** vida 100 (a barra do HUD que já existe).
  - Espada: golpe largo em arco de 140° à frente, com alcance de 110 px até a borda do alvo, como no Stardew. Dá para acertar de longe e correr (pedido do usuário, 2026-11-27). Um rastro branco mostra o arco.
  - Arco: flecha na direção em que o jogador olha; gasta 1 flecha.
  - Rolamento (Espaço): ~0,35 s sem tomar dano e tempo de recarga; rolar logo antes do impacto ("rolamento perfeito") abre o boss por ~2 s, com dano dobrado.
- **Gatilho provisório:** alimentar 3 slimes diferentes libera o boss. Também há um comando de depuração para testes. Trocar pela tarefa definitiva quando ela existir.

## Em aberto (decidir nas revisões)

- A tarefa definitiva que libera o boss (quantos slimes alimentar, ou o que derrotar).
- Valores finais de vida, dano, tempos de aviso e recarga (ajuste em playtest).
- Rota da comida: o que o boss aceita e como ela dá o orbe.
- Sincronização do boss no multijogador: o protótipo começa solo; em dupla, o anfitrião manda no boss.
- Quantos bosses existem e a função do orbe na máquina final (Bíblia: EM ABERTO).
