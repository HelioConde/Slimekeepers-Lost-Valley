# Multijogador P2P (2026-11-23)

Decisão do usuário: **P2P pela Steam**, dois jogadores. A partida começa na tela de escolha
de Aren e Moni (playtest ID 17, 2026-11-27).

## Como jogar

1. **Menu → Multijogador**.
2. **Hospedar pela Steam** ou **Hospedar na rede local** → escolha o espaço. A sala abre ao
   chegar na tela de escolha (Steam: sala só de amigos com 2 vagas e o convite abre; rede
   local: porta 24680).
3. O amigo aceita o convite na Steam com o jogo aberto (ou digita o IP / ID da sala e clica
   em **Entrar**) e vai para a mesma tela de escolha.
4. Cada um escolhe um protagonista diferente. Nas duas telas aparece **Jogador 1**
   (anfitrião) e **Jogador 2** acima do personagem de cada um; o do outro fica bloqueado
   (se os dois clicarem no mesmo ao mesmo tempo, vale o do anfitrião).
5. **Pronto** trava a escolha (**Cancelar pronto** destrava). Quando os dois estão prontos o
   anfitrião começa e os dois carregam a Floresta. O anfitrião passa pelo despertar; o
   convidado chega sem ele.
6. **Voltar** sai da sala. Se o convidado sai, o anfitrião segue esperando com a vaga livre;
   se o anfitrião sai, o convidado volta ao menu com o aviso "O Jogador 1 fechou a sala.".
7. Quem entra com a partida já em andamento fica com o outro protagonista e cai direto no
   mapa do anfitrião, no mesmo horário.

## Tutorial em dupla (playtest ID 18)

Cada jogo tem o próprio tutorial: o balão aparece na tela de cada um, sobre o próprio
personagem; o passo (`tutorial_step`) não é sincronizado, [Tab] pula só a dica de quem
apertou e as condições olham a mochila de quem joga. O convidado começa o tutorial ao
chegar (não tem despertar); o anfitrião, ao fim do despertar. Objetivo compartilhado:
a bancada é uma só (`placed_stations`), então planta, depósito e obra valem para os dois e
a dica avisa ("Em dupla a bancada é uma só..."). Em dupla a bancada paga não pula mais a
coleta (gravetos, pedrinhas, fibras, cordas) de quem não coletou. Reconectar começa o
tutorial de novo (a mochila do convidado também recomeça).

## Como funciona

- `scripts/net/net_session.gd` (autoload `NetSession`) cuida da conexão.
  - Steam: GodotSteam 4.24 GDExtension (`addons/godotsteam`, só Windows 64 e Linux 64), lobby de
    amigos e Steam Networking Messages.
  - Rede local: ENet.
  - O protocolo é o mesmo nos dois: dicionários com `var_to_bytes`, e `bytes_to_var` sem objetos.
- App ID de teste: **480** (Spacewar), em `steam_appid.txt` e `NetSession.STEAM_APP_ID`.
  Trocar pelo App ID do jogo quando existir.
- `scripts/net/net_presence.gd` (em cada região) envia posição, direção e animação 15 vezes por
  segundo e mostra o outro protagonista quando ele está no mesmo mapa.

## Verificado

`tools/test_multiplayer_lan.gd` abre **dois jogos** e conecta pela rede local: 17 verificações,
0 falhas.

- Quem entra fica com a Moni e cai no mapa do anfitrião.
- `tools/test_mp_lobby.gd` (+ `tools/net/mp_lobby_guest.gd`), dois jogos: sala na tela de
  escolha, Jogador 1/2 no personagem certo nas duas telas, bloqueio do já escolhido, Voltar
  e entrar de novo, início só com os dois prontos, tutorial de cada um independente.
- Cada um vê o outro protagonista com a arte certa.
- Os movimentos chegam dos dois lados.
- Steam num PC só (`tools/test_steam_smoke.gd`, cliente Steam aberto): o GodotSteam inicia
  com o App 480 e cria a sala só de amigos (2026-11-23). Falta o segundo jogador por outra conta.

## Ainda não sincronizado (próximas etapas)

- Itens soltos no chão: de propósito, vão para quem coletou (evita duplicar).
- Relógio: sincronizado (o anfitrião manda a hora a cada 5 s; o convidado só avança ou
  acerta a hora no mesmo dia, nunca volta o dia).
- Slimes e laços.
- Steam de verdade: a sala é criada pela Steam (teste num PC só). Falta entrar com uma
  segunda conta Steam em outro computador.
- O modo (cooperativo ou outro) está A DEFINIR.

## Mundo compartilhado (2026-11-23)

`scripts/net/net_world.gd` sincroniza a fazenda (`farm_cells`), a coleta (`forage_taken`),
as pedras quebradas (`rocks_broken`), as árvores cortadas (`chopped_trees`), as bancadas
(`placed_stations`), o baú (`chest_items`) e a casa (`player_house`). Cada lado
confere essas chaves a cada 0,5 s e envia a chave inteira que mudou; quem recebe grava e
redesenha a região. Quem entra na sala recebe o estado atual do anfitrião.

Limites: a última escrita vence em cada chave; itens soltos no chão ainda não sincronizam. Teste: `tools/test_multiplayer_lan.gd` (covas aradas nos dois sentidos).

