# Multijogador P2P (2026-11-23)

Decisão do usuário: **P2P pela Steam**, dois jogadores. Quem hospeda escolhe Aren ou Moni e
quem entra joga com o outro.

## Como jogar

1. **Menu → Multijogador (MP)**.
2. **Hospedar pela Steam**: escolha o protagonista. Uma sala só de amigos (2 vagas) é criada e
   o convite de amigos da Steam abre.
3. O amigo aceita o convite na Steam com o jogo aberto. Ele entra com o outro protagonista,
   no mapa do anfitrião e no mesmo horário, sem a introdução.
4. **Rede local** (sem Steam): "Hospedar na rede local" num computador; no outro, digite o IP
   e clique em **Entrar** (porta 24680).

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
- Cada um vê o outro protagonista com a arte certa.
- Os movimentos chegam dos dois lados.

## Ainda não sincronizado (próximas etapas)

- Mundo compartilhado: árvores cortadas, coleta, plantio, casa, baú e itens no chão.
  Hoje cada jogo tem o seu.
- Relógio: o convidado recebe o horário ao entrar; depois cada um avança sozinho.
- Slimes e laços.
- Steam de verdade: o código usa a API real do GodotSteam (nomes conferidos no Godot 4.7).
  Falta testar com duas contas Steam em dois computadores.
- O modo (cooperativo ou outro) está A DEFINIR.

## Mundo compartilhado (2026-11-23)

`scripts/net/net_world.gd` sincroniza a fazenda (`farm_cells`), a coleta (`forage_taken`),
as pedras quebradas (`rocks_broken`) e as árvores cortadas (`chopped_trees`). Cada lado
confere essas chaves a cada 0,5 s e envia a chave inteira que mudou; quem recebe grava e
redesenha a região. Quem entra na sala recebe o estado atual do anfitrião.

Limites: a última escrita vence em cada chave; bancadas colocadas e baús ainda não
sincronizam. Teste: `tools/test_multiplayer_lan.gd` (covas aradas nos dois sentidos).

