<!-- Transcrição do texto de Slimekeepers_Correcoes_Claude_v1.0.docx (2026-11-26). Imagens do .docx não incluídas (ficam com o usuário). -->

**RELATÓRIO DE PLAYTEST  /  VERSÃO 1.0**

# Correções de jogabilidade e experiência do jogador

**Slimekeepers: Lost Valley · Vale inicial · Moni · Godot 4**

Destinatário: Claude Code. Base: relatos de playtest e 70 capturas de tela. Objetivo: transformar as observações em tarefas verificáveis, preservando a direção visual, a progressão e a utilidade dos slimes.

## Escopo e prioridades do backlog

P0 — Estabilidade 12, 20, 22, 24, 35, 39: rede, coleta, pausa, construção cooperativa e recuperação de energia.

P1 — Progressão 01, 06, 07: recursos iniciais, acesso a pedras e mineração; 05: investigar árvores fantasmas.

P1 — Interface e fluxo 03, 04: fechar painéis com X e impedir fabricação involuntária.

P1 — Ações e animações 02, 08, 09, 10: estados de Moni, foice, corte em área e aragem sincronizada.

P2 — Agricultura 11: plantar com animação e duração, mantendo o valor dos slimes plantadores.

Ordem de execução (v0.9): solo, cooperativo com o usuário, comparação com Stardew Valley, correções e reteste (62–64). Regras mais recentes prevalecem.

## Instruções ao Claude Code

Para investigar e corrigir, após registrar a sessão inicial, leia AGENTS.md, documentação, cenas e scripts existentes. Localize a implementação real de geração de recursos, inventário, receitas, UI, animações, coleta e agricultura. Reproduza os problemas em uma partida nova e, quando aplicável, em um save existente.

Corrija por causa raiz; não substitua sistemas inteiros sem necessidade. Preserve sprites e arte existentes, controles já documentados, custos de receitas e progressão planejada, salvo ajuste justificado. Centralize parâmetros de balanceamento e sincronize efeitos com o momento da ação. Não introduza duplicação de itens, gastos indevidos ou bloqueios de input.

P0 = crítica; P1 = alta; P2 = média. Prioridades e ordem sugeridas. As imagens estáticas não comprovam causas de bugs: confirme em execução. Tempos, alcance, quantidades e densidade devem ser calibrados no jogo.

**01 / MUNDO E PROGRESSÃO**

## Recursos básicos e acesso a pedras

### 01  Recursos próximos à estrada  |  P1

Relato: Faltam recursos básicos nas áreas abertas próximas à estrada, dificultando a coleta do tutorial.

Implementar: Ajustar a distribuição de gravetos, pedrinhas e fibras vegetais, priorizando clareiras e bordas acessíveis de caminhos, sem bloquear a passagem nem sobrecarregar o cenário. Garantir recursos suficientes para as receitas iniciais, conforme custos reais do jogo.

Aceite: Em partida nova, um iniciante consegue completar a coleta inicial e encontrar os recursos de forma intuitiva, sem depender de ferramentas ainda bloqueadas.

### 06  Escassez de pedras no início  |  P1

Relato: O jogador procura pedras para fabricar itens iniciais, mas encontra poucos recursos acessíveis; algumas pedras exigem uma picareta melhor.

Implementar: Revisar a cadeia de receitas e níveis de mineração, garantir pedrinhas coletáveis e depósitos iniciais compatíveis com a ferramenta disponível. Eliminar dependências circulares de progressão e calibrar a reposição conforme a lógica existente.

Aceite: Em diferentes partidas ou rotas iniciais, é possível alcançar a primeira picareta e evoluir para os próximos itens sem precisar de uma ferramenta que ainda não pode fabricar.

_Fig. 01 • Clareira e tutorial de coleta._

_Fig. 06 • Bancada e requisitos de ferramenta._

_Fig. 07 • Trecho aberto percorrido._

_Fig. 08 • Trecho de floresta percorrido._

**02 / MUNDO E INTERAÇÕES**

## Árvores e mineração

### 05  Possíveis árvores fantasmas  |  P1

Relato: Suspeita de árvores fantasmas: o print mostra marcadores circulares de interação em pontos do cenário. A natureza exata do erro ainda precisa ser reproduzida.

Implementar: Investigar objetos de árvore com sprite, colisão, área de interação ou marcador desalinhados ou persistentes após corte. Conferir ciclo de criação, corte, toco, remoção e carregamento do save. Não remover árvores legítimas nem marcadores úteis sem confirmar a causa.

Aceite: Não existem alvos invisíveis ou marcadores órfãos indevidos; árvores válidas respondem corretamente ao corte e o estado permanece consistente após salvar e carregar.

_Fig. 05 • Marcadores na etapa de corte de árvores._

### 07  Quebrar pedras e melhorar rendimento  |  P1

Relato: As pedras indicadas devem ser quebráveis com picareta; o rendimento dos montes de pedra é insuficiente.

Implementar: Identificar o tipo de rocha mostrado e permitir mineração com o nível apropriado (inicial quando for recurso básico). Aumentar a quantidade de pedras geradas por um monte minerável. Manter distinção visual e mecânica entre depósitos comuns e avançados.

Aceite: Golpes válidos quebram o depósito e geram os drops esperados uma única vez; o rendimento aumenta em relação ao atual, sem permitir duplicação nem quebrar depósitos avançados indevidamente.

_Fig. 09 • Rocha próxima de Moni com picareta selecionada._

**03 / EXPERIÊNCIA DO JOGADOR**

## Interface e fabricação

### 03  Botão X para fechar painéis  |  P1

Relato: Durante o playtest, uma pessoa procurava repetidamente o X para fechar caixas de ações.

Implementar: Adicionar botão X visível no canto superior direito de todos os painéis de ação fecháveis, incluindo mochila, fabricação manual, bancada e demais janelas equivalentes. Usar padrão visual consistente com a UI; preservar Esc e os atalhos existentes. Evitar propagação do clique para ações no mundo.

Aceite: É possível fechar todos os painéis relevantes com mouse ou atalhos; fechar não fabrica, não usa ferramentas e não altera itens. O X permanece acessível e não cobre conteúdo em diferentes resoluções.

_Fig. 03 • Mochila sem botão X visível._

### 04  Selecionar receita sem fabricar  |  P1

Relato: Ao selecionar um item na tela de fabricação, o jogo fabrica instantaneamente, embora exista o botão Fabricar. O fluxo confunde iniciantes.

Implementar: Separar a seleção da receita da execução. Clicar na receita apenas mostra descrição, materiais, disponibilidade e botão. A fabricação ocorre somente ao acionar Fabricar ou um atalho explícito de confirmação, se mantido e documentado. Validar requisitos novamente no momento da execução.

Aceite: Selecionar, trocar ou inspecionar receitas não modifica inventário. Fabricar consome os materiais e concede o item uma única vez. Sem materiais ou requisitos, o botão fica desabilitado e não há consumo. Testar fabricação manual e bancada.

_Fig. 04 • Fabricação manual: seleção e botão Fabricar._

**04 / PERSONAGEM**

## Animações de Moni

### 02  Transição prematura para idle  |  P1

Relato: Moni retorna à pose idle muito rápido; as demais animações quase não aparecem.

Implementar: Revisar máquina de estados, prioridades, duração de clipes, FPS de sprites e transições. Impedir que ausência de movimento force idle enquanto uma ação não cancelada estiver em execução. Respeitar o fim do clipe ou janela de cancelamento definida. Refinar tempos, poses e transições sem deixar o controle pesado.

Aceite: Ao usar ferramentas e executar ações, o ciclo visual fica legível, sem cortes prematuros, poses travadas ou repetição involuntária. Idle volta quando a ação realmente termina; testar direções, movimento, ação parada e entradas repetidas.

_Fig. 02 • Pose idle indicada no relato._

### 08  Animação da foice  |  P1

Relato: A animação da foice continua com problema visual, conforme o recorte de Moni com a ferramenta.

Implementar: Revisar frames, alinhamento da foice com as mãos, pivô, origem, orientação e ordem de desenho. Verificar animação em todas as direções suportadas, especialmente o arco do golpe; sincronizar o frame de impacto com a coleta.

Aceite: A foice permanece alinhada ao personagem, com golpe contínuo e sem deslocamento indevido, frames quebrados ou troca prematura para idle. O efeito de corte acompanha o contato visual.

_Fig. 10 • Moni com a foice; referência do bug._

Validação complementar: gravar pequenos vídeos das ações antes e depois. Uma captura isolada não permite avaliar duração, continuidade, cancelamento ou o frame exato de impacto.

**05 / FERRAMENTAS E AGRICULTURA**

## Ações em área e tempo de plantio

### 09  Foice corta em área ao pressionar F  |  P1

Relato: A foice coleta um mato por vez, mas deveria atingir todos os matos e gramados coletáveis na área do golpe.

Implementar: Com a foice selecionada, F executa um golpe em área, na orientação e alcance coerentes com a animação. Detectar todos os alvos válidos no instante de impacto, processar cada um uma única vez e gerar seus drops. Não atingir vegetação meramente decorativa nem outros recursos indevidos. Aplicar custos por golpe conforme balanceamento.

Aceite: Posicionar vários matos dentro e fora da área: todos os válidos dentro são cortados por uma ação; os externos permanecem. Sem drops duplicados ao manter F pressionado ou sobrepor colisões.

### 10  Aragem sincronizada  |  P1

Relato: O chão arado aparece antes de a animação de arar acontecer.

Implementar: Validar o alvo ao iniciar; alterar o tile somente no frame de impacto da ferramenta (evento de animação ou lógica equivalente). Aplicar consumo e resultado juntos; cancelar antes do impacto sem deixar solo arado indevido.

Aceite: O solo permanece inalterado até o contato visual; cada ação válida ara uma única célula conforme as regras existentes. Testar cancelamento e alvo inválido.

### 11  Animação e duração do plantio  |  P2

Relato: O plantio precisa de animação própria e tempo de execução para tornar vantajoso delegar a tarefa aos slimes.

Implementar: Criar ou refinar uma animação de plantar, com duração configurável e momento de colocação da semente. Validar solo e semente; efetivar plantio e consumo no momento definido, sem duplicações. Calibrar uma duração perceptível, sem tornar o início frustrante. Preservar ou integrar a função dos slimes plantadores, conforme a implementação existente.

Aceite: O plantio manual tem início, execução e conclusão visíveis; uma semente por plantio válido. Interrupções e tentativas repetidas não perdem nem duplicam recursos. A automação por slimes poupa tempo quando disponível.

_Fig. 11 • Alvo de corte._

_Fig. 12 • Golpe de foice._

_Fig. 13 • Aragem._

_Fig. 14 • Solo / plantio._

Entrega do Claude: relacionar os IDs 01–41 com arquivos alterados, testes executados, resultados, parâmetros ajustados e pendências. Testar regressões e não declarar correções não verificadas como concluídas.

**06 / MULTIPLAYER E INTERFACE**

## Estabilidade do multiplayer

### 12  Travamento no menu e troca de modo  |  P0

Relato: Ao pressionar alguns botões no menu multiplayer ou tentar trocar de P2P para Local dentro do jogo, o jogo buga e deixa de funcionar. Os botões exatos e a causa ainda não foram isolados; reproduzir antes de corrigir.

Implementar: Mapear todos os controles do menu multiplayer e seus estados. Revisar sinais, bloqueios de input, sobreposição de painéis, ciclo de vida das conexões e transições de sessão. Encerrar a sessão anterior de forma segura antes de iniciar outra, quando aplicável; preservar o save e liberar os controles. Se uma troca não for suportada durante uma sessão, oferecer confirmação e fluxo de saída/reentrada claro, sem travar.

### Bateria de testes obrigatória

Inventário de controles: Listar e testar cada botão, seletor, aba, campo, X, voltar e atalho existente em todos os menus do jogo, com foco no multiplayer. Registrar tela, estado inicial, ação, resultado esperado, resultado observado e aprovado/reprovado.

Matriz multiplayer: Testar P2P → Local e Local → P2P, no menu e dentro de uma partida; iniciar, entrar, sair, cancelar, voltar, fechar, reconectar e repetir a troca várias vezes. Cobrir anfitrião e cliente, quando disponíveis, conexão inválida, desconexão inesperada, cliques rápidos e tentativas enquanto carrega.

Regressão: Verificar se o personagem continua respondendo, se os menus reabrem, se o modo selecionado corresponde à sessão ativa e se nenhuma conexão ou callback antigo interfere. Conferir erros no console, estado do save e sincronização entre jogadores quando aplicável.

Aceite: Nenhum botão deixa o jogo inutilizável. Toda ação válida produz resposta previsível; ações inválidas informam o motivo e permitem voltar. Executar testes automatizados de estados e sinais e testes interativos com instâncias reais quando possível. Não considerar multiplayer aprovado se apenas o teste offline passou.

Evidência de entrega: Matriz completa de botões e cenários, logs, passos de reprodução, versão/commit testado e capturas ou vídeo do fluxo antes/depois. Marcar explicitamente o que não foi possível executar.

**07 / PLAYTEST ORIENTADO À EXPERIÊNCIA**

## Testar como um jogador de verdade

### 13  Agente de playtest sem conhecimento privilegiado  |  P1

Objetivo: O Claude deve jogar ou implementar um agente que jogue a versão real do jogo como um iniciante. Demonstrar as ações, decisões observáveis e dificuldades de navegação, não apenas verificar se o código permite completar tarefas.

Método: Começar com save novo. Usar a tela renderizada, textos do tutorial e controles normais (teclado/mouse). Não usar coordenadas ocultas de recursos, mapa interno, teleporte, inventário injetado, comandos de debug ou conhecimento das receitas não exibidas. Separar testes técnicos com acesso interno dos playtests de experiência. Se não houver acesso interativo, instrumentar um executor de inputs e capturas; não inventar uma sessão.

Exemplo crítico: Encontrar gravetos e pedrinhas no interior da floresta pode ser tecnicamente possível, mas um iniciante não sabe que estão ali: copas e vegetação ocultam os recursos, e a floresta densa dificulta a passagem. Priorizar a observação de caminhos, clareiras e bordas visíveis; registrar quando o tutorial não oferece pistas suficientes. Não premiar rotas que dependem de conhecimento oculto.

Cenário mínimo: Iniciar o tutorial, procurar fibras, gravetos e pedras, abrir e fechar mochila, inspecionar e fabricar receitas, cortar árvore, minerar, usar foice, arar e plantar. Testar menus e multiplayer separadamente. Repetir após ajustes e, se houver geração variável, em diferentes seeds.

Diário de decisões: Para cada etapa, registrar horário/tempo decorrido, objetivo mostrado na tela, elementos visíveis, ação escolhida e justificativa breve, resultado observado, obstáculo e sugestão. Anexar screenshots ou vídeo com timestamps. Medir tempo de busca, tentativas frustradas, recursos visíveis/acessíveis, desvios e bloqueios; comparar antes/depois.

Aceite: O relatório distingue o que é tecnicamente possível do que é fácil de descobrir e executar. O iniciante simulado deve progredir sem informação privilegiada; se falhar, documentar onde e por quê. Validar achados com jogadores reais quando possível: o agente complementa, não substitui, testes humanos.

Entrega sugerida: Criar um modo ou script de QA reproduzível, fora do gameplay de produção, e salvar relatório, evidências e matriz de testes em diretório de QA do repositório, respeitando AGENTS.md e a organização existente. Corrigir causas confirmadas e repetir a sessão antes de encerrar.

**08 / MENU E CONFIGURAÇÕES**

## Clareza e acessibilidade dos menus

### 14  Simplificar nome do botão  |  P2

Relato: O menu mostra “Multijogador (MP)”.

Implementar: Usar apenas “Multijogador” no botão e manter os demais elementos visuais. Atualizar a chave de tradução correspondente.

Aceite: O botão exibe o texto completo, sem sigla nem corte, e continua abrindo o fluxo correto.

### 15  Idioma e controles de áudio  |  P1

Relato: Configurações ainda não apresentam seleção de idioma nem controle separado da música.

Implementar: Adicionar seletor de idioma com os idiomas realmente suportados e aplicar a tradução em menus, HUD e tutorial. Separar volume de ambiente e música em controles independentes; manter as opções atuais e persistir preferências.

Aceite: Alterar idioma atualiza textos; os volumes são independentes, funcionam durante o jogo e são restaurados ao reiniciar.

### 16  Tutorial explicativo no menu  |  P1

Relato: O menu principal precisa oferecer um tutorial mais explicativo.

Implementar: Adicionar acesso visível a um guia de primeiros passos, explicando controles, coleta, fabricação, ferramentas, slimes e como jogar em multiplayer. Não depender apenas de dicas durante o jogo.

Aceite: Um iniciante localiza e abre o guia, entende os controles e consegue voltar ao menu sem travar.

_Fig. 15 • Nome atual do botão._

_Fig. 17 • Menu principal._

_Fig. 16 • Configurações atuais._

**09 / MULTIPLAYER • ENTRADA**

## Seleção de personagens e tutorial

### 17  Iniciar multiplayer na seleção de protagonista  |  P1

Relato: O multiplayer deve começar na tela de escolha de Aren e Moni, identificando os jogadores.

Implementar: Integrar o fluxo de criação/entrada de sessão à seleção. Exibir “Jogador 1” e “Jogador 2” acima dos personagens escolhidos, atualizar a seleção nas duas telas e indicar prontidão antes de iniciar. Respeitar as regras existentes de escolha e não iniciar enquanto a sessão não estiver pronta.

Aceite: Em Local e P2P, ambos veem a associação correta entre jogador e protagonista; confirmar, voltar e desconectar não deixam o menu travado.

_Fig. 18 • Tela de seleção de protagonista, referência para o novo fluxo._

### 18  Tutorial disponível para os dois jogadores  |  P1

Relato: Ao iniciar o multiplayer, o tutorial aparece somente para um jogador.

Implementar: Apresentar as instruções para cada participante em sua própria interface. Manter progresso do tutorial e ações individuais coerentes; não avançar ou dispensar a dica do outro indevidamente. Se houver objetivos compartilhados, explicitar isso.

Aceite: Jogador 1 e Jogador 2 veem as dicas, conseguem avançar e pular de forma previsível, inclusive ao entrar ou reconectar quando suportado.

_Fig. 19 • Tela de Moni com tutorial._

_Fig. 20 • Tela de Aren sem tutorial._

**10 / MULTIPLAYER • INVENTÁRIO**

## Coleta, drops e troca entre jogadores

### 19  Pedra inicial aparentemente não coletável  |  P1

Relato: A pedra pequena mostrada na área inicial parece não poder ser coletada.

Implementar: Reproduzir no ponto indicado com Aren e Moni, em solo e MP. Verificar se o recurso é decorativo ou coletável, alcance, colisão, alvo, estado e autoridade. Se for decorativo, distinguir visualmente; se for recurso inicial, corrigir a coleta.

Aceite: Pedras iniciais válidas são coletáveis pelos dois jogadores, concedendo o item correto uma vez. Sem marcador enganoso em decoração.

_Fig. 21 • Pedra no início._

_Fig. 22 • Tentativa de coleta._

### 20  Coleta e drops visíveis para todos  |  P0

Relato: Quando um jogador coleta, o item não aparece dropando na tela do outro.

Implementar: Sincronizar criação, movimento/animação, remoção e estado de recursos e itens no chão entre os participantes. Validar a coleta na autoridade adequada, replicar eventos/estado e tratar disputa pelo mesmo item, atraso e reconexão.

Aceite: Ambos observam o mesmo recurso e o mesmo drop; apenas o coletor recebe o item. Não há objetos fantasmas, duplicação nem desaparecimento incorreto.

### 21  Soltar itens para outro jogador  |  P1

Relato: Não é possível jogar um item no chão para compartilhar com outro jogador.

Implementar: Adicionar ação clara de soltar item pela mochila/barra; permitir escolher quantidade quando empilhável. Validar espaço e inventário antes de criar o drop, respeitar itens não descartáveis e permitir que o outro jogador o recolha.

Aceite: Soltar reduz a quantidade correta; ambos veem o drop; o outro pode coletá-lo. Inventários e chão permanecem consistentes em tentativas simultâneas e falhas de conexão.

_Fig. 23 • Barra rápida com gravetos._

_Fig. 24 • Ação de coleta._

**11 / MULTIPLAYER • PAUSA E SINCRONIZAÇÃO**

## Menus locais sem congelar a sessão

### 22  B/Esc não devem pausar o mundo em MP  |  P0

Relato: Ao pressionar B ou Esc, a coleta para e aparece “Jogo pausado”. O outro jogador mudou de posição, mas a atualização não apareceu na tela de quem abriu o menu.

Implementar: Em MP, não usar pausa global da árvore de cenas para abrir mochila, menu ou sobreposição local. Manter rede, física e simulação compartilhada ativas; bloquear somente controles locais necessários ao painel. B deve abrir/fechar a mochila conforme o mapeamento; Esc fecha o painel ou abre menu local. Definir cancelamento/continuação de coleta sem perdas ou duplicações. Preservar pausa real no modo solo.

Aceite: Em duas instâncias, cada jogador abre B/Esc alternadamente: o outro continua andando, coletando e interagindo; posição e drops continuam atualizando na tela com o painel aberto. Ao fechar, o controle local retorna. Sem congelamento, dessincronização ou consumo duplo.

_Fig. 25 • Aviso de pausa em MP._

_Fig. 27 • Outra ocorrência de pausa._

_Fig. 26 • Dois jogadores no cenário com tutorial de coleta._

### Regressão obrigatória com duas instâncias

Executar: Local e P2P, como anfitrião e cliente: selecionar personagens, iniciar, validar tutorial, coletar a mesma pedra, observar drops, soltar e recolher pilhas, abrir/fechar B, Esc e X enquanto o parceiro se move, sair e reconectar. Repetir com cliques rápidos e, quando viável, latência simulada.

Entrega: Registrar commit, modo, papel, ações, resultado em cada tela, logs e vídeo/capturas sincronizadas. Acrescentar os cenários à matriz dos IDs 12 e 13; marcar testes não executados. Priorizar 22 e 20 antes dos refinamentos de UI. As causas ainda são hipóteses, não diagnósticos confirmados.

**12 / MULTIPLAYER • CONSTRUÇÃO**

## Planejamento e construção cooperativa

### 23  Blueprint visível para os dois jogadores  |  P1

Relato: O jogador parceiro não vê a prévia da construção; ambos precisam escolher o melhor local para a base.

Implementar: Replicar a prévia temporária da blueprint, incluindo posição, orientação, validade e jogador responsável. Ambos veem a mesma proposta enquanto o responsável a move; cancelar remove a prévia nas duas telas. Distinguir prévia de obra confirmada, sem consumo antecipado.

Aceite: Em Local e P2P, ambos observam o posicionamento em tempo real e podem discutir a escolha; confirmar ou cancelar resulta no mesmo estado em ambas as instâncias.

### 24  Construir a mesma blueprint em equipe  |  P0

Relato: Ao tentar ajudar o parceiro a construir, a animação foi cancelada. A contribuição simultânea deve acelerar a obra.

Implementar: Permitir múltiplos construtores válidos na mesma obra. Controlar animação e cancelamento por jogador; acumular progresso das contribuições com autoridade única, sem reiniciar o trabalho do parceiro. Aplicar o novo fluxo de depósito de materiais do ID 40, evitando dupla cobrança.

Aceite: Comparar construção individual e dupla: a dupla termina mais rápido. Ambos mantêm a animação enquanto contribuem; afastar um não cancela o outro. A obra conclui uma vez e permanece sincronizada.

_Fig. 28 • Prévia da bancada._

_Fig. 29 • Outra tela sem a mesma prévia._

_Fig. 30 • Tentativa de construção conjunta._

Regressão: Testar anfitrião e cliente iniciando, ajudando, cancelando, afastando-se, disputando confirmação e desconectando. Registrar tempo solo/dupla, estado e vídeo das duas telas.

**13 / MUNDO • ILUMINAÇÃO E INTERAÇÃO**

## Ambiente e alcance de interação

### 25  Corrigir iluminação estourada dos cogumelos  |  P1

Relato: Em certas áreas, cogumelos próximos produzem brilho excessivo e ocultam detalhes do cenário.

Implementar: Revisar intensidade, raio, sobreposição das luzes, emissão e bloom/glow. Manter o aspecto mágico sem saturação branca excessiva; ajustar individualmente ou limitar acúmulo conforme a causa identificada.

Aceite: Testar cogumelos isolados e agrupados durante o dia e a noite: sprites e solo permanecem legíveis, sem manchas superexpostas que dificultem a navegação.

### 26  Reduzir distância de interação com slimes  |  P1

Relato: O menu de interação com o slime pode ser ativado de longe demais.

Implementar: Ajustar o alcance configurável ao espaço próximo do personagem; medir a partir de pontos de referência coerentes no mundo. Selecionar o alvo válido mais próximo e não permitir ações fora do alcance.

Aceite: O menu abre somente quando Moni ou Aren estão próximos o suficiente; ao se afastar, o alvo deixa de estar disponível. Verificar vários slimes juntos e em multiplayer.

### 27  Transição gradual do amanhecer  |  P1

Relato: Ao amanhecer, o cenário ficou claro de forma instantânea, sem transição.

Implementar: Interpolar iluminação ambiental, cores, sombras e intensidade de luzes ao longo do horário do jogo. Evitar mudanças abruptas de preset; sincronizar o relógio e o estado visual no MP. Preservar a direção artística.

Aceite: Gravar a passagem noite–amanhecer–dia e, como regressão, dia–anoitecer: brilho e cores mudam de modo contínuo, sem saltos. Ambos os jogadores veem a mesma fase.

_Fig. 31 • Excesso de brilho noturno._

_Fig. 32 • Menu de interação com slime._

_Fig. 33 • Iluminação ao amanhecer._

**14 / FLORESTA • CORTE E FÍSICA**

## Árvores com colisão e queda direcional

### 28  Restaurar física de contato das árvores  |  P1

Relato: As árvores perderam a física de contato relatada durante o corte.

Implementar: Reproduzir e identificar se o defeito está na colisão do tronco, resposta de contato ou ambos. Restaurar a física prevista sem transformar a copa inteira em obstáculo. Atualizar colisores corretamente ao derrubar, virar tronco/toco e remover.

Aceite: Testar aproximação pelos quatro lados, corte e passagem após queda; colisão e resposta visual correspondem à fase real da árvore, sem bloqueios invisíveis. Em MP, ambos veem o mesmo estado.

### 29  Animar a queda da árvore conforme o lado do corte  |  P1

Relato: As árvores caem sempre para o mesmo lado e precisam de uma animação de queda.

Implementar: Usar a posição do jogador que aplica o golpe final, relativa ao tronco. Corte pela esquerda: queda à direita; pela direita: queda à esquerda. Corte por cima ou por baixo: escolher aleatoriamente esquerda/direita. Definir o lado uma vez na autoridade do MP e replicá-lo. Animar a queda em torno da base; criar o tronco no destino ao fim da queda.

Aceite: Testar as quatro direções com Moni e Aren; comprovar o lado oposto para esquerda/direita e ambos os resultados possíveis para cima/baixo. A queda é legível e não teletransporta o tronco; sem drops ou troncos duplicados.

_Fig. 34 • Corte próximo ao tronco._

_Fig. 35 • Toco após o corte._

_Fig. 36 • Tronco caído._

Validação técnica: Testar corte concorrente pelos dois jogadores, impacto final, salvamento/carregamento e remoção de colisões. Verificar também a investigação de árvores fantasmas (05).

**15 / FERRAMENTAS • ANIMAÇÕES**

## Pá, foice de Aren e impacto do machado

### 30  Adicionar pá para remover tocos  |  P1

Relato: A lista de ferramentas precisa de uma pá para retirar os restos das árvores após o corte.

Implementar: Adicionar pá à categoria Ferramentas da bancada, com ícone, receita e animação coerentes com a progressão. Permitir selecionar e usar a pá para remover tocos; validar alcance, alvo e ferramenta. Definir custo, duração e eventual drop em conformidade com o balanceamento existente.

Aceite: Fabricar, equipar e usar a pá para retirar um toco; o terreno fica livre e sem colisão residual. Testar ferramenta incorreta, interrupção, repetição, save e MP.

### 31  Corrigir animação da foice de Aren  |  P1

Relato: A animação de foice de Aren também está incorreta, conforme o recorte enviado.

Implementar: Revisar sprites, pivô, alinhamento às mãos, orientação, continuidade e duração do golpe. Aplicar a mesma regra de golpe em área e impacto sincronizado dos IDs 08 e 09, respeitando os sprites próprios de Aren.

Aceite: Gravar golpes em todas as direções suportadas: ferramenta acompanha o corpo, sem frames deslocados, cortes prematuros ou drops antes do contato.

### 32  Sincronizar tremor e impacto de machado  |  P1

Relato: A árvore e o tronco tremem antes de o machado acertar visualmente.

Implementar: Disparar tremor, dano, som e partículas no frame de contato do machado, usando evento de animação ou mecanismo equivalente. Não produzir impacto se a ação for cancelada antes do contato. Aplicar à árvore em pé e ao tronco caído; sincronizar eventos em MP.

Aceite: Vídeo quadro a quadro mostra contato antes ou no mesmo instante da reação. Golpe válido gera um único impacto; golpe cancelado não gera tremor nem dano. Testar Aren e Moni.

_Fig. 37 • Lista atual de ferramentas._

_Fig. 38 • Toco e pose de Aren._

_Fig. 39 • Foice de Aren._

Entrega: Acrescentar IDs 23–41 à matriz de testes e ao playtest do ID 13. Documentar ajustes, evidências, limitações e testes não executados. Não marcar bugs como corrigidos sem reprodução e validação.

**16 / INTERFACE • LEGIBILIDADE**

## Fontes, inventário e atalhos

### 33  Melhorar legibilidade dos números  |  P1

Relato: O número no requisito de pedra pequena é difícil de distinguir: parece 2, 8 ou 5.

Implementar: Revisar a fonte pixelada, escala inteira, contraste, espaçamento e glifos dos algarismos em receitas, pilhas e contadores. Manter o estilo visual e os valores reais das receitas.

Aceite: Os dígitos de 0 a 9, em especial 2, 5 e 8, são distinguíveis nas resoluções suportadas, inclusive quando o requisito está em vermelho.

### 37  Corrigir barra rápida ao entrar em construção  |  P1

Relato: Ao iniciar a construção de uma casa, a barra de inventário aumenta de largura e o texto fica cortado.

Implementar: Separar a dica de construção do contêiner dos slots; impedir expansão pelo texto, quebrar linhas quando necessário e preservar escala, âncoras e largura da barra.

Aceite: Abrir, redimensionar, cancelar e confirmar o modo de construção sem deformar a barra, sobrepor texto ou perder acesso aos slots.

### 38  Corrigir numeração da barra rápida  |  P1

Relato: O teclado usa 1 a 9 e 0, mas a décima posição aparece como 10.

Implementar: Exibir 1, 2, 3, 4, 5, 6, 7, 8, 9 e 0. Conferir mapeamento de entrada, seleção e dicas do tutorial.

Aceite: A tecla 0 seleciona o décimo slot; todos os demais atalhos funcionam em solo e MP.

_Fig. 40 • Requisito com algarismos difíceis de ler._

_Fig. 49 • Mochila: revisar contadores e legibilidade._

_Fig. 45 • Barra rápida alargada durante construção._

**17 / MUNDO • RECURSOS E REPLICAÇÃO**

## Reposição natural e efeitos compartilhados

### 34  Balancear respawn diário por tipo de recurso  |  P1

Relato: Ponto positivo: os itens estão reaparecendo na virada do dia. Porém nem todos devem retornar automaticamente, sobretudo pedras, que não deveriam surgir em grande quantidade do nada.

Implementar: Preservar a reposição funcional, mas definir regras por tipo, taxa, limite e intervalo. Pedrinhas podem reaparecer ocasionalmente em locais plausíveis, sem repor tudo a cada dia. Priorizar disponibilidade inicial (01, 06, 07) sem inundar o mapa. Não gerar sobre construções, jogadores ou recursos existentes; sincronizar com a autoridade do mundo.

Aceite: Comparar vários dias: recursos renováveis retornam conforme a regra; pedras reaparecem de forma limitada e natural. Não há duplicação em MP ou após carregar o save, nem bloqueio de progressão.

### 36  Replicar tremor da árvore no jogador 2  |  P1

Relato: Ao cortar uma árvore, o efeito de tremor não é exibido na tela do segundo jogador.

Implementar: Complementar o ID 32: replicar o evento de impacto válido para os dois clientes, associado ao objeto e ao golpe. Não antecipar reação nem duplicá-la em quem executou o golpe.

Aceite: Em duas instâncias, Aren e Moni alternam o corte como anfitrião e cliente. Ambos veem tremor da mesma árvore no impacto, inclusive do tronco quando aplicável.

### 41  Remover o item visual bugado  |  P1

Relato: Há um objeto com aparência incorreta no cenário, mostrado no recorte.

Implementar: Identificar a entidade pelo sprite, posição e cena de origem; remover a ocorrência indevida e impedir sua geração novamente. Não excluir recursos legítimos ou alterar inventários sem confirmar a identidade.

Aceite: O objeto indicado não reaparece em partida nova nem em save migrado; sem colisões invisíveis, marcadores órfãos ou perda de recursos válidos.

_Fig. 41 • Recursos reaparecendo na clareira._

_Fig. 44 • Corte de árvore em MP._

_Fig. 48 • Objeto bugado a identificar e remover._

**18 / SOBREVIVÊNCIA • ENERGIA**

## Exaustão, sono e recuperação

### 35  Eliminar bloqueio crítico por energia zerada  |  P0

Relato: Moni ficou sem energia e não conseguiu executar mais ações. O aviso manda dormir, mas o jogador ficou sem uma saída prática.

Implementar: Adotar a lógica de exaustão solicitada, inspirada em Stardew Valley: ao zerar energia, entrar em estado cansado, avisar o jogador e permitir ações de recuperação. Se insistir em ações que gastam energia, iniciar sono por exaustão no local atual. Não exigir energia para dormir. Em solo, avançar ao dia seguinte após intervalo configurável e despertar com 50% da energia máxima por ter dormido em local inadequado. Em MP, manter o personagem dormindo no local e o mundo ativo para o parceiro; avançar o dia quando o outro jogador também dormir, sem pausar a sessão. Sincronizar estados e tratar desconexões para não criar outro bloqueio.

Aceite: Zerar energia, forçar ação e observar sono no local; em solo, despertar no próximo dia com metade da energia. Em MP, o outro continua jogando e ambos avançam quando dormem; o exausto recupera 50%. Testar Moni/Aren, host/cliente, Local/P2P e saves.

### 39  Impedir recuperação automática na virada do dia  |  P0

Relato: Ao passar o dia, os personagens recuperaram energia sem dormir.

Implementar: Separar relógio de recuperação: a simples mudança de data não deve restaurar energia. Aplicar recuperação por eventos explícitos de sono ou outras mecânicas legítimas já previstas, sem conceder bônus indevido. Sono normal segue o balanceamento aprovado; sono forçado fora da cama recupera somente 50%.

Aceite: Atravessar a meia-noite acordado não aumenta energia. Dormir normalmente ou por exaustão aplica somente a recuperação correspondente, uma vez por jogador. Os HUDs e o relógio ficam sincronizados.

_Fig. 42 • Energia de Moni praticamente zerada._

_Fig. 43 • Aviso de cansaço bloqueando a ação._

_Fig. 46 • Dia seguinte: energia recuperada sem dormir, segundo o relato._

Parâmetros a validar: Horário/intervalo X de despertar, tolerância de esforço após energia zero e recuperação do sono normal. Definir no playtest; a recuperação de 50% no sono forçado é requisito.

**19 / CONSTRUÇÃO • NOVO FLUXO**

## Blueprint, depósito de materiais e obra

### 40  Padronizar construção em etapas para todas as estruturas  |  P0

Relato: O jogador deve escolher o tamanho da casa e posicionar a blueprint imediatamente, sem precisar ter todos os recursos. Depois deve coletar e depositar materiais no local; quando completar, a blueprint muda de cor e permite construir. Aplicar inclusive à bancada de trabalho.

Implementar: Substituir exigência de materiais para posicionar por uma máquina de estados comum: prévia, blueprint confirmada aguardando materiais, pronta para construir, em construção e concluída. Casa com dimensões livres dentro da área válida do mapa, custo calculado conforme tamanho e regras de construção. Mostrar junto à obra o que falta (item, quantidade depositada/necessária), atualizar ao receber materiais e distinguir o estado pronto por cor e indicação textual. Não consumir materiais ao posicionar; depositar a partir do inventário de forma parcial, sem cobrar duas vezes.

Aceite: Posicionar casa pequena ou grande e bancada sem materiais; sair, coletar, retornar e depositar aos poucos. A obra não inicia antes de receber todos os recursos; ao completar, muda de cor, permite construir e finaliza só uma vez. Testar cancelamento, sobreposição, área inválida, salvar/carregar e contribuição de ambos os jogadores.

Fluxo obrigatório: 1. Escolher tamanho e local → 2. Confirmar blueprint sem custo imediato → 3. Depositar recursos → 4. Indicar materiais completos e mudar cor → 5. Construir, sozinho ou em dupla → 6. Estrutura concluída.

Integração com IDs 23 e 24: Prévia, dimensões, requisitos e materiais depositados são compartilhados; qualquer jogador autorizado pode contribuir. Após completar materiais, ambos podem construir simultaneamente e acelerar a obra. Validar depósitos e progresso na autoridade; não duplicar itens, não cancelar a animação do parceiro e persistir obras incompletas.

_Fig. 47 • Seleção de área da casa: referência para posicionamento livre._

Entrega e regressão: Atualizar tutorial, receitas e agente de playtest (13) para explicar o novo fluxo desde a primeira bancada. Verificar a barra rápida (37–38), depósito cooperativo e falta de energia durante construção. Registrar evidências de solo e MP, commits, logs e resultados por ID 33–41. Regras de cancelamento/reembolso, limites técnicos e cores são decisões de implementação a validar; não impor tamanho fixo de casa.

## Atualização v0.6 — Inventário, Baú, Casa e Progressão

Esta versão acrescenta novas correções focadas em inventário, baú, escala dos objetos, ciclo de descanso e qualidade da construção da casa. As prioridades abaixo são sugestões, e os detalhes de interação devem ser calibrados em playtests reais, especialmente no multiplayer.

### Novas correções registradas:

ID

Correção

Prioridade

42

Corrigir seleção e reorganização de itens no inventário e na barra rápida

Alta

43

Implementar durabilidade e quebra de ferramentas

Alta

44

Corrigir escala do tronco em relação à árvore original

Alta

45

Reformular a interface e a usabilidade do baú

Alta

46

Sincronizar o conteúdo do baú em tempo real no multiplayer

Crítica

47

Adicionar cama à progressão da casa e ao ciclo de sono

Crítica

48

Adicionar diálogos contextuais para ferramentas insuficientes e cansaço

Alta

49

Definir tamanho mínimo válido para casas e blueprints

Alta

50

Permitir cortar tocos e troncos de cenário

Alta

51

Corrigir o bug visual da porta e do piso da casa

Alta

52

Ajustar a escala relativa entre personagem e casa

Alta

### 42. Inventário e barra rápida

- Quando o jogador clica em um item, ele pode ficar em estado bugado ou sem uma forma clara de reorganização.
- O Claude deve implementar arrastar e soltar no inventário e na barra rápida, incluindo troca de posições entre slots.
- Deve ser possível reorganizar tanto a mochila quanto a barra inferior sem comportamentos presos, fantasmas ou itens duplicados.
- Critérios de aceitação: clicar não deve quebrar o item; arrastar deve reposicionar; trocar slots deve atualizar instantaneamente a UI e os dados do inventário.
### 43. Durabilidade e quebra de ferramentas

- Todas as ferramentas devem ter resistência/durabilidade.
- Após um número X de usos, a ferramenta quebra e desaparece, ou entra em estado quebrado conforme a regra escolhida pelo Claude.
- O documento recomenda exibir a durabilidade de forma simples e legível, por exemplo por barra, número ou estados visuais.
- Critérios de aceitação: o uso reduz durabilidade; ao atingir zero a ferramenta não pode continuar sendo usada; o jogador recebe feedback visual e/ou textual.
### 44. Escala do tronco após derrubar árvore

- O tronco resultante está muito maior que a árvore original, gerando incoerência visual.
- O Claude deve ajustar a escala do tronco e dos restos de madeira para respeitar melhor o tamanho da árvore derrubada.
- Critérios de aceitação: o tronco não deve parecer maior que a árvore que o originou e deve combinar com a escala do personagem.
### 45. Interface e usabilidade do baú

- O baú ainda está muito cru visualmente e precisa seguir o padrão: inventário do jogador à esquerda e inventário do baú à direita.
- Deve suportar arrastar itens, além de atalhos para mover 1 item, metade da pilha e a pilha inteira.
- O Claude pode definir os atalhos exatos, mas deve documentá-los dentro do jogo.
- Critérios de aceitação: layout em duas colunas claras; mover itens com drag-and-drop; atalhos funcionais para quantidade unitária, metade e tudo.
### 46. Sincronização do baú no multiplayer

- Quando um jogador abre o baú e move itens, o outro jogador não vê a alteração em tempo real; só após fechar e abrir novamente.
- O conteúdo do baú deve sincronizar imediatamente para todos os jogadores conectados.
- Critérios de aceitação: qualquer item depositado, retirado ou movido por um jogador aparece para o outro sem precisar reabrir o baú.
### 47. Cama e progressão da casa

- Entre os itens de construção da casa precisa existir uma cama.
- Construir a casa sem a cama enfraquece a progressão porque a casa não resolve a necessidade de descanso.
- O Claude deve incluir a cama como estrutura ou mobília obrigatória/essencial do ciclo de descanso.
- Critérios de aceitação: o jogador consegue construir/adquirir uma cama; dormir na cama restaura energia conforme a regra do jogo; a casa passa a ter função prática real.
### 48. Diálogos contextuais dos personagens

- Os balões dos personagens devem ajudar o jogador quando ele tenta executar uma ação para a qual ainda não possui a ferramenta ou condição adequada.
- Exemplos pedidos: ao tentar quebrar árvore grande, exibir algo como “não consigo quebrar essa árvore grande, que tal uma mais pequena?”; para pedras maiores, feedback equivalente.
- Quando a energia estiver acabando: se o jogador não tiver cama, sugerir construir uma cama; se já tiver cama, sugerir ir dormir.
- Critérios de aceitação: feedback contextual aparece no momento certo, com texto curto, claro e coerente com o estado atual do jogador.
### 49. Tamanho mínimo da casa e da blueprint

- Se uma casa muito pequena não é válida, o jogo não deve permitir uma blueprint ou construção final minúscula.
- O Claude deve definir um tamanho mínimo de casa e impedir resultados desproporcionais.
- Critérios de aceitação: a menor casa possível ainda comporta os elementos básicos previstos pelo design; a escala visual é coerente.
### 50. Cortar tocos e troncos de cenário

- Alguns tocos/troncos de cenário ainda não podem ser cortados ou processados.
- Isso entra em conflito com a progressão de ferramentas e com a presença da futura pá para remover restos.
- Critérios de aceitação: tocos e troncos interativos seguem regras consistentes, com ferramenta correta, animação e feedback adequados.
### 51. Bug visual da porta e do piso da casa

- Na entrada da casa, a porta está mostrando o chão externo onde deveria aparecer o piso interno da casa.
- O Claude deve corrigir o tile/overlay/ordem de desenho na área da porta.
- Critérios de aceitação: ao olhar a entrada, o jogador vê continuidade visual do interior da casa, sem vazamentos do chão externo.
### 52. Escala relativa entre personagem e casa

- A casa está transmitindo a impressão de ser pequena demais, como se o personagem fosse grande demais em relação à construção.
- O Claude deve revisar a escala global entre personagem, paredes, porta e interior da casa.
- Critérios de aceitação: o personagem parece caber naturalmente no espaço; a casa parece habitável; porta, parede e piso ficam proporcionais.
### Diretriz complementar — cama e descanso

- A regra de sono forçado definida na versão 0.5 continua válida.
- Esta versão acrescenta a necessidade de a cama existir de forma clara na progressão da casa.
- O Claude deve decidir se a cama faz parte da casa básica, se é construída logo após a casa ou se ambas as abordagens coexistem; como não houve orientação explícita, deixei essa decisão aberta para validação.
### Evidências visuais anexadas nesta atualização

Evidência 1 — mochila com item e contadores pouco claros.

Evidência 2 — barra rápida e ordenação dos itens.

Evidência 3 — tronco processável com escala visual questionável.

Evidência 4 — referência do segundo jogador ajudando e cancelando a animação de construção.

Evidência 5 — interface atual do baú: layout e UX ainda crus.

Evidência 6 — estado do baú após mover itens.

Evidência 7 — conteúdo do baú e inventário em outro momento de uso.

Evidência 8 — construção da casa sem cama disponível na aba de construção.

Evidência 9 — tile/retângulo bugado no cenário.

Evidência 10 — tronco/toco de cenário ainda não cortável.

Evidência 11 — casa construída em escala reduzida.

Evidência 12 — detalhe do piso/porta com bug visual.

Evidência 13 — interior/escala da casa em relação ao personagem.

### Observações finais desta versão

- Mantive como evidência adicional o caso do segundo jogador cancelando a animação ao ajudar na construção do baú, mas tratei isso como reforço da correção cooperativa já registrada anteriormente.
- Não alterei a numeração anterior para evitar quebrar referências já usadas por você ou pelo Claude.
- Os atalhos exatos para “mover 1”, “metade” e “tudo” não foram definidos pelo usuário, então deixei essa decisão aberta para implementação e validação.
**ATUALIZAÇÃO 0.7  /  FERRAMENTAS**

## Mineração e corte: progressão por eficiência

Atenção: esta atualização complementa e, quando houver conflito, substitui as regras de bloqueio por tamanho ou nível das tarefas 06, 07, 43, 48 e 50. A ferramenta deve ser do tipo correto; seu nível define eficiência e desgaste, não uma proibição absoluta de cortar ou minerar recursos legítimos.

### 53  Coleta rápida de pedras pequenas  |  P1

Relato: Com a picareta equipada, o jogador ainda precisa de esforço excessivo para pegar pequenos montes de pedras.

Implementar: Permitir recolher ou quebrar cada pequeno monte com um único clique/acionamento da interação, quando estiver ao alcance e com a picareta equipada. Aplicar o resultado no impacto, mantendo a coleta manual sem ferramenta conforme o design existente.

Aceite: Um acionamento basta; quantidade correta entra no inventário ou gera drop coletável, sem duplicação. Verificar Aren e Moni em solo e MP.

### 54  Ferramentas sem bloqueio artificial por nível  |  P1

Relato: Algumas pedras de tamanho moderado não aceitam a picareta.

Implementar: Qualquer picareta funcional deve minerar pedras legítimas e qualquer machado funcional deve cortar madeira legítima, inclusive recursos grandes. Ferramentas rudimentares exigem mais golpes/tempo e sofrem maior desgaste conforme dureza do alvo; ferramentas melhores são mais eficientes. Diferenciar cenário puramente decorativo de recurso real de forma legível. Atualizar as falas da tarefa 48 para sugerir alvos menores ou ferramentas melhores por eficiência, não por impossibilidade de corte.

Aceite: Testar alvos pequenos, médios e grandes com cada nível de ferramenta; verificar tempo, desgaste, quebra da ferramenta e progressão sem dependências circulares.

### 55  Impacto da picareta sincronizado  |  P1

Relato: A pedra quebra antes de a animação da picareta atingir o alvo.

Implementar: Aplicar dano, tremor, som, partículas e quebra/drop no frame/evento de impacto da animação, não no início do comando. Reutilizar a lógica da tarefa 32 e replicar o resultado no MP.

Aceite: Capturar os frames antes, durante e depois do impacto; a pedra permanece intacta até o contato. Nenhum drop ou dano antecipado; ambos os jogadores veem o resultado correto.

_E63 — Monte pequeno com picareta equipada._

_E64 — Pedra de tamanho moderado._

_E65 — Mineração; ordem temporal a reproduzir._

**ATUALIZAÇÃO 0.7  /  PERSISTÊNCIA**

## Salvar, continuar e recuperar partidas

### 56  Corrigir carregamento de progresso antigo  |  P0

Relato: Após o jogo fechar, Continuar abriu um progresso anterior, perdendo o avanço da sessão.

Implementar: Investigar qual arquivo/slot Continuar carrega, quando o último save é efetivamente gravado e se o estado em memória está substituindo ou ignorando o save correto. Não apagar saves antigos durante correção ou migração.

Aceite: Com um save antigo e um novo, avançar, salvar, fechar/reabrir e confirmar que Continuar recupera o último save válido da partida pretendida, e não um estado de outra partida.

### 57  Autosave a cada amanhecer  |  P0

Relato: O progresso precisa ser salvo diariamente, independentemente de o jogador ter construído uma cama.

Implementar: Gravar automaticamente ao início de cada novo dia, após concluir a transição, respawn e atualização de estados. Persistir dia/hora, personagens, energia, inventários, durabilidade, mundo, construções/blueprints, baús, agricultura, slimes e tutorial conforme sistemas existentes. Em MP, usar o estado autorizado da sessão e salvar os dois jogadores de forma consistente. Recomenda-se escrita atômica e cópia de recuperação, sem marcar sucesso antes de concluir a gravação.

Aceite: Avançar vários dias, encerrar o processo após confirmação do autosave e reabrir; restaurar o estado completo do último amanhecer salvo. Não duplicar itens, restaurar energia indevidamente (39) ou repetir respawn. Simular interrupção durante a gravação e preservar último save válido. Mudanças após o último save podem ser perdidas se não houver salvamento adicional.

### 58  Slots independentes de salvamento  |  P0

Relato: O jogador precisa poder voltar a jogos antigos ou começar um novo sem sobrescrever outro.

Implementar: Adicionar tela de slots de salvamento ao fluxo Novo Jogo/Continuar, com identificação da partida, dia, personagem, modo e última gravação. Novo jogo deve usar slot livre ou exigir confirmação explícita antes de substituir um existente; manter saves anteriores acessíveis. A quantidade de slots e o comportamento do botão Continuar podem ser definidos pelo Claude, desde que a escolha da partida seja clara.

Aceite: Criar duas partidas diferentes, progredir em ambas, alternar slots e reiniciar o jogo. Confirmar isolamento de inventário, mapa, progresso e modo; autosave de uma partida não modifica a outra. Testar migração de saves existentes e retomada MP.

_E66 — Tela apresentada no relato de carregamento antigo; a causa precisa de reprodução e logs._

**ATUALIZAÇÃO 0.7  /  SLIMES**

## Alimentação, descoberta e menu de ações

### 59  Alimentação com ingredientes e comidas prontas  |  P1

Relato: A lista de alimentação mostra principalmente pratos prontos; o jogador quer descobrir os ingredientes preferidos de cada slime.

Implementar: Exibir todos os alimentos válidos presentes no inventário: ingredientes individuais (cenoura, batata, alface, etc.) e pratos preparados. Não incluir sementes ou itens não comestíveis sem regra explícita. Permitir oferecer uma unidade e mostrar a reação do slime (gostou, não gostou, favorito, conforme sistema). Definir preferências por ingrediente e considerar combinações nas receitas, preservando a descoberta pelo jogador. Não revelar previamente preferências desconhecidas de modo que elimine a experimentação. Exemplo do usuário: se o slime gosta de cenoura e batata, mas não de alface, combinar cenoura e batata deve poder resultar em prato mais atraente para ele.

Aceite: Com ingredientes e pratos na mochila, todos os alimentos elegíveis aparecem; selecionar alimento consome exatamente uma unidade e produz resposta coerente. Testar diferentes preferências, inventário vazio, atualização após consumo e sincronização MP. Validar receita combinada com ingredientes preferidos e rejeitados.

### 60  Ocultar ações indisponíveis no disco do slime  |  P1

Relato: O disco radial pode mostrar ações que ainda não estão disponíveis para aquele slime, confundindo o jogador.

Implementar: Montar as opções dinamicamente a partir do estado real do slime e do jogador: vínculo, permissões, tarefas e requisitos. Ocultar opções indisponíveis e reorganizar os segmentos para manter a navegação clara. Manter uma saída segura e verificar disponibilidade novamente na execução.

Aceite: Antes e depois de desbloquear uma ação, conferir que ela só aparece quando aplicável. Testar slimes diferentes e estados alterados em MP; nenhum segmento vazio ou ação sem efeito.

_E67 — Menu de alimentação atualmente exibido._

_E68 — Disco de ações do slime._

### Validação integrada e prioridades

Priorizar 56–58 antes de playtests prolongados, pois a perda de progresso invalida a experiência e os resultados. Depois, validar 53–55 em conjunto com durabilidade (43) e animações (32/36); validar 59–60 com um jogador iniciante, conforme tarefa 13. Registrar build, passos, resultado real, capturas ou vídeo, e testes solo/MP. Os tempos, desgaste, quantidade de slots e pesos de preferências ainda precisam de balanceamento; os exemplos de comida não são valores fixos. Não declarar correções concluídas sem teste.

**ATUALIZAÇÃO 0.8  /  INTERFACE E NAVEGAÇÃO**

## Menu de pausa e acesso às opções

### 61  Centralizar a navegação no menu da tecla Esc  |  P1

Relato: O botão Menu permanece visível no canto superior direito do HUD, enquanto a janela aberta por Esc oferece apenas Continuar. O jogador solicita remover o botão do HUD e concentrar as opções de navegação na janela de Esc.

Implementar: Retirar o botão Menu do HUD, preservando o relógio e os demais indicadores. Ao pressionar Esc durante a partida, abrir um menu com Continuar, Opções, Tutorial e Voltar ao menu principal. Reutilizar as configurações de idioma e áudio da tarefa 15 e o tutorial explicativo da tarefa 16. Ao fechar opções ou tutorial, retornar ao menu de Esc; não reiniciar o progresso do tutorial.

Single-player e MP: No modo individual, manter a pausa normal. No multiplayer, abrir somente uma sobreposição local: bloquear os comandos de jogabilidade daquele jogador, mas manter a simulação, o relógio, a rede e as ações do outro jogador ativos (tarefa 22). Usar um título adequado ao modo, sem afirmar que a partida MP está pausada.

Proteção do progresso: Ao escolher Voltar ao menu principal, confirmar a saída e indicar o estado do último salvamento; não sobrescrever outro slot nem abandonar a sessão silenciosamente. Respeitar as tarefas 56–58 e tratar a saída do anfitrião ou cliente de maneira explícita.

Aceite: Testar todos os botões, Esc para abrir/fechar, retorno de cada submenu, confirmação/cancelamento de saída, retomada do controle e ausência do botão antigo. Em duas instâncias MP, comprovar que o outro jogador continua se movimentando e interagindo enquanto o menu, as opções ou o tutorial estão abertos. Verificar que Esc fecha primeiro um painel ativo quando aplicável e não abre menus sobrepostos indevidamente.

### Evidências do playtest

_E69 — Botão Menu no HUD, a ser removido._

_E70 — Janela de Esc oferece apenas Continuar._

**ATUALIZAÇÃO 0.9  /  PROTOCOLO DE PLAYTEST**

## Ordem de execução obrigatória

Objetivo: Avaliar a experiência real, a cooperação e a satisfação percebida antes de escolher as próximas melhorias. Esta atualização amplia a tarefa 13 e define a ordem de trabalho; não elimina as 61 tarefas anteriores.

Etapa 1 — Solo: Claude/agente joga Slimekeepers como iniciante. Entregar diário de jogo e dificuldades reais.

Etapa 2 — Dupla: Usuário controla o J1; Claude/agente controla o J2. Entregar registro das duas perspectivas e cooperação.

Etapa 3 — Comparação: Claude/agente joga Stardew Valley e Slimekeepers em sessões equivalentes. Entregar matriz comparativa e propostas justificadas.

Etapa 4 — Evolução: Corrigir, repetir cenários e comparar com a linha de base. Entregar evidências antes/depois e regressões.

### 62  Playtest solo por observação visual  |  P1

Método: Iniciar partida nova isolada dos saves reais. Jogar na interface, com teclado/mouse ou executor equivalente. Antes da sessão, apenas configurar o ambiente; não consultar receitas ocultas, mapa interno, coordenadas de recursos ou soluções do código. Seguir a tarefa 13.

Diário: Registrar o que aparece na tela, objetivo percebido, ação escolhida e motivo breve, expectativa, resultado, dificuldade e satisfação estimada. Mostrar capturas ou vídeos com horário. Exemplo: procurar pedras nas margens da estrada por serem visíveis; registrar a dificuldade caso não encontre.

Aceite: Tentar honestamente o ciclo inicial de exploração, coleta, fabricação, construção, descanso, agricultura e interação com slimes. Não forçar sucesso com debug. Medir tempo real e registrar onde o progresso parou.

Bloqueios: Se houver perda de progresso, travamento ou outro bloqueio crítico, registrar a evidência inicial, proteger os saves e corrigir apenas o necessário para prosseguir. Retomar a mesma etapa; não declará-la concluída sem execução.

**ATUALIZAÇÃO 0.9  /  COOPERAÇÃO**

## Playtest humano + agente

### 63  Usuário no J1 e Claude no J2  |  P1

Objetivo: Criar sessão cooperativa em que o usuário joga de verdade e o Claude joga como parceiro, sem assumir os controles do Jogador 1. É um modo de teste/QA, não uma exigência de adicionar NPC ao jogo de produção.

Preparação: Usar duas instâncias ou controles independentes conforme a arquitetura Local/P2P existente. O usuário escolhe e controla o J1; o agente escolhe/controla o J2. Validar conexão, foco de janela, isolamento de comandos e capturas das duas telas. Usar save de teste separado.

Comportamento do J2: Explorar, decidir e executar tarefas com o que enxerga na própria tela e a comunicação normal com o J1. Dividir coleta, sugerir local da base, compartilhar materiais e cooperar na construção. Pedir ajuda quando necessário; não teletransportar, injetar recursos ou controlar o personagem do usuário.

Comunicação: Exibir diário legível ao lado da sessão ou em painel separado: objetivo atual, observação, ação escolhida, justificativa breve, resultado e próxima tentativa. Permitir que o usuário interrompa o agente imediatamente. Não sobrepor o HUD ou interferir nos controles.

Cenários: Seleção de personagens, tutorial dos dois, drops, compartilhamento, baú aberto simultaneamente, blueprint compartilhada, construção em dupla, corte/mineração, energia/sono, Esc sem pausar o outro e retomada de save. Testar anfitrião/cliente e Local/P2P quando disponíveis.

Avaliação humana: Ao fim de cada ciclo, pedir ao usuário uma nota de 1 a 5 e observação curta sobre clareza, diversão, cooperação e frustração. Separar o relato humano da avaliação simulada do agente.

Aceite: O J1 permanece sob controle exclusivo do usuário; o J2 executa tarefas reais e úteis. Entregar evidências das duas perspectivas, falhas reproduzíveis, tempos e momentos em que cooperar ajudou ou atrapalhou. Não marcar a etapa como aprovada sem sessão real com o usuário.

Dependência: A sessão exige participação do usuário e ambiente que permita controle simultâneo. Se não houver acesso ao segundo cliente, implementar e testar executor de inputs/capturas em ambiente autorizado; relatar a limitação em vez de simular resultados.

**ATUALIZAÇÃO 0.9  /  BENCHMARK**

## Comparação com Stardew Valley

### 64  Playtest comparativo de progressão e satisfação  |  P1

Primeiro jogo de referência: Stardew Valley. Usar instalação legítima e acessível, sem modificar o jogo externo. O agente deve jogar ambos os títulos, não apenas pesquisar guias ou ler o código de Slimekeepers.

Método: Começar com saves novos em cada jogo, sem guias ou informações privilegiadas. Alternar sessões com o mesmo orçamento de tempo real (sugestão: blocos de 30 minutos), registrar dia interno e progresso. Comparar objetivos equivalentes sem exigir mecânicas idênticas. Repetir em ordem inversa quando possível.

### Dimensões de avaliação

Clareza inicial: Tempo até entender o objetivo; dúvidas e pedidos de ajuda.

Progressão e recompensa: Tempo até o primeiro avanço útil; metas e sensação de conquista.

Exploração e coleta: Tempo de busca, recursos visíveis, ações repetitivas e tentativas frustradas.

Controles e interface: Erros de interação, menus, animações e feedback.

Ritmo e energia: Tempo útil do dia, descanso e bloqueios de progresso.

Satisfação e continuidade: Momentos recompensadores, irritantes, curiosidade e vontade estimada de jogar mais.

Escala: 1 = muito frustrante/confuso; 2 = abaixo do esperado; 3 = aceitável; 4 = agradável; 5 = muito satisfatório. Marcar N/A quando não comparável. A nota do agente é uma estimativa fundamentada em evidências, não uma emoção real ou nota humana.

Aceite: Entregar comparação com tempos, eventos, notas justificadas, pontos positivos de Slimekeepers e problemas prioritários. Recomendar melhorias que reforcem sua identidade e utilidade dos slimes; não copiar arte, código ou conteúdo de Stardew Valley.

Limitação: Se Stardew Valley não estiver instalado ou não puder ser controlado pelo agente, registrar o bloqueio e preparar o teste; não substituir a execução por comparação inventada.

**ATUALIZAÇÃO 0.9  /  RELATÓRIO E REGRESSÃO**

## Como medir e decidir melhorias

### Registro obrigatório por sessão

Identificação: Jogo, versão/build, modo, seed quando disponível, save de teste, data, duração real, dia/hora do jogo e participante (agente ou humano). Anexar captura ou vídeo associado a cada achado importante.

### Exemplo ilustrativo de diário (não executado)

Objetivo visível: Juntar gravetos e pedras para o tutorial.

Observação e decisão: Estrada aberta; procurar nas margens, sem entrar às cegas na floresta.

Resultado e dificuldade: Poucas pedras visíveis; anotar tempo de busca e tentativas.

Impacto percebido: Ritmo lento; nota estimada de clareza 2/5, a validar.

Hipótese de melhoria: Distribuir recursos básicos em clareiras e bordas de caminhos.

Validação posterior: Repetir em save novo e comparar tempo, erros e nota.

### Relatório comparativo e ciclo de melhoria

Comparação: Para cada dimensão, preencher resultados dos dois jogos, evidências, diferenças e oportunidade de melhoria. Incluir N/A quando não houver equivalência; não penalizar um título por não copiar o outro.

Decisão: Relacionar cada problema confirmado aos IDs 01–61 ou registrar novo achado. Priorizar bloqueios, perda de progresso e sincronização; depois reduzir atritos e reforçar recompensas. Separar fatos, hipóteses e preferências.

Regressão: Após cada lote de correções, repetir o cenário afetado sob as mesmas condições e comparar com a linha de base. Executar testes técnicos e de interface separados do playtest visual; verificar novos erros, inclusive no MP.

Entrega: Relatório com evidências, notas estimadas do agente e notas humanas quando coletadas, mudanças propostas, status aprovado/falhou/bloqueado e prioridades. Guardar scripts, logs e evidências no diretório de QA existente, conforme AGENTS.md.

Parâmetros sugeridos: Blocos de 30 minutos, escala de 1 a 5 e repetição em ordem inversa são propostas de método, não decisões finais de design. Ajustar o tempo se necessário e declarar qualquer mudança. Nenhum playtest é considerado executado por este documento.

**ATUALIZAÇÃO 1.0  /  AMBIENTE DO CLAUDE CODE**

## Skills e roteamento de modelos

Antes dos playtests (62–64): Inventariar plugins, skills, agentes e ferramentas MCP já instalados. Conferir a documentação oficial e compatibilidade com a versão atual do Claude Code. Instalar apenas o que faltar, preservando as configurações e evitando duplicidade ou conflito. Não alterar a ordem dos playtests já definida.

### Guided Model Router

Objetivo: Economizar tokens sem prejudicar a qualidade. Usar um único roteador, preferencialmente com perfil balanced e Sonnet como orquestrador. Delegar tarefas a subagentes adequados à dificuldade, em vez de pressupor que o plugin troca o modelo principal da sessão.

Haiku: Documentação, levantamentos e alterações simples de baixo risco.

Sonnet: Desenvolvimento cotidiano, implementação, testes e playtests.

Opus: Bugs difíceis, arquitetura, salvamentos, multiplayer, concorrência e regressões críticas.

Fable (se disponível e autorizado): Escalonamento excepcional para problemas que exigem capacidade adicional; não presumir acesso ao modelo.

Escalonamento: Se uma tarefa simples crescer em complexidade, apresentar falhas repetidas ou envolver risco de perda de dados, encaminhar ao modelo mais capaz disponível. Manter a mesma exigência de testes e evidências em todos os níveis. Não usar fallback por API nem chamadas pagas adicionais sem autorização explícita.

Instalação proposta (confirmar no repositório antes de executar): Executar no Claude Code somente se ainda não estiver instalado e os comandos forem compatíveis com a versão atual.

/plugin marketplace add nobodyohm-web/claude-code-model-router

/plugin install model-router

/router-stats

Referência: https://github.com/nobodyohm-web/claude-code-model-router

Aceite: Registrar versão instalada, modelos disponíveis, perfil escolhido e evidência de delegação de uma tarefa simples e uma complexa. Verificar ausência de segundo roteador e fallback pago. Se algum comando ou recurso não estiver disponível, documentar o bloqueio; não inventar um resultado.

**ATUALIZAÇÃO 1.0  /  QUALIDADE E RESTRIÇÕES**

## Skills de desenvolvimento e QA

Prioridade de instalação e aplicação: Após o roteador, priorizar Verification Before Completion, Test Driven Development, Systematic Debugging, Requesting Code Review e Balance Check. Usar conforme a natureza da tarefa, não executar todas as skills indiscriminadamente.

Superpowers: Test Driven Development (testes antes de correções), Verification Before Completion (validar antes de declarar conclusão), Requesting Code Review (revisão das alterações) e Systematic Debugging (investigação de causa raiz). Verificar disponibilidade no pacote https://github.com/obra/superpowers.

Game design e Godot: Balance Check (recursos, energia, ferramentas, progressão e satisfação); Godot Prompter, Godot Specialist e GDScript Specialist (arquitetura, cenas e scripts). Confirmar a origem e compatibilidade de cada skill antes de instalar; não adivinhar comandos.

Arte e mapas: Generate2DSprite, Generate2DMap e Asset Gen ficam como opções de inventário para uso futuro. Durante a suspensão do PixelLab, não acionar essas skills para chamar o serviço, direta ou indiretamente. Preservar e reaproveitar a arte existente.

Ferramentas complementares: Manter GdUnit4 e Godot MCP, se disponíveis, e aproveitar os testes existentes. Usar testes unitários e de integração, duas instâncias reais do multiplayer e o agente visual de playtest conforme as tarefas 62–64. Não confundir leitura de código com sessão jogada.

Entrega do preparo: Informar o que já existia, o que foi instalado, versões, origem, conflitos evitados, validação e pendências. Só declarar uma instalação ou teste concluído quando houver evidência. Não instalar dependências ou ativar serviços de custo adicional sem permissão.

### Instrução final obrigatória — suspensão do PixelLab

NÃO UTILIZAR O PIXELLAB ATÉ NOVA AUTORIZAÇÃO DO USUÁRIO. A suspensão é imediata e vale para todo o desenvolvimento do Slimekeepers: Lost Valley, inclusive subagentes, skills, automações, scripts, workflows e chamadas MCP/API. Não gerar, editar, animar ou solicitar sprites, mapas ou outros assets pelo PixelLab. Não reativar por conta própria, mesmo que uma tarefa visual fique bloqueada.

Durante a suspensão: Reutilizar os assets existentes; preservar a configuração e as credenciais sem expô-las ou apagá-las. Se a correção exigir arte nova indisponível, registrar a pendência e continuar com tarefas que não dependam do serviço. Não trocar por outro gerador pago sem autorização.

Retomada: Somente voltar a utilizar o PixelLab quando o usuário solicitar expressamente que o serviço seja retomado. Esta regra prevalece sobre qualquer instrução anterior que permita o uso do PixelLab.
