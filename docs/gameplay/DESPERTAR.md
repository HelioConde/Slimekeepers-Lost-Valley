# Seleção de protagonista e despertar

Decisão do criador (2026-11-22, registrada em `docs/narrativa/BIBLIA_NARRATIVA.md`, seção 3): dois protagonistas jogáveis, **Aren** e **Moni**. A tela de seleção é simbólica. No mundo, quem foi escolhido desperta sozinho.

## Fluxo

Menu → **Novo Jogo** → seleção (`scenes/protagonist_select.tscn`) → confirmar → tela de carregamento → Floresta → despertar → controle livre.

- **Seleção** (`scripts/menu/protagonist_select.gd`):
  - Os dois aparecem sentados de costas no gramado, com sombra e respiração.
  - Com o cursor em cima: o personagem é realçado, olha por cima do ombro (troca uma vez, sem repetir) e o outro esmaece.
  - O clique fixa a escolha e libera Confirmar. Voltar retorna ao menu.
  - No teclado ou controle: ←/→, Enter e Esc.
- **Carregamento:** a Floresta carrega em segundo plano, com a tela escurecida e a mensagem "<Nome> está despertando…". A transição dura pelo menos 1,2 s.
- **Despertar** (`scripts/world/intro_wake.gd`):
  - É uma máquina de estados: sentado → olha para a esquerda → olha para a direita → confusão → levanta → observa → controle.
  - A câmera fica mais próxima (1,6) e volta à distância normal. A interface volta aos poucos e a floresta clareia a partir do escuro.
  - Movimento e interações ficam bloqueados durante a cena. Não há como travar o jogador: o despertar termina sozinho em no máximo 25 s, e Esc, Enter ou E pulam a cena.
- **Estado** (`scripts/systems/protagonist.gd`):
  - `protagonist` guarda quem foi escolhido; `intro_pending` só é ligado ao confirmar e é desligado no fim do despertar. As duas chaves ficam no save.
  - Continuar uma partida nunca repete o despertar. Saves antigos carregam como Aren.
- **Sprites:**
  - `player.gd` carrega a arte do protagonista escolhido. O Aren usa `assets/player` (a arte original) e a Moni usa `assets/player_moni`.
  - As poses do despertar ficam em `<arte>/wake/<pose>/south/`. Cada pose vai e volta, para terminar na posição sentada de onde a próxima começa.
  - "Levantar" é a animação de sentar de trás para frente.
- **Menu:** não mostra mais o protagonista. Ganhou janelas com luz de lareira, fumaça na chaminé e pólen dourado, tudo respeitando a opção "reduzir movimento".

## Arte (PixelLab)

| Item | Origem |
|---|---|
| Aren | personagem já existente (`16659178`); novas: 5 poses do despertar (sul) |
| Moni | personagem nova (`0728e65e`, pro, estilo do Aren, cabelo solto): rotações, andar, correr, enxada, regador, despertar |
| Seleção | fundo 640×360 (floresta à noite), poses sentadas de lado (neutra e olhando por cima do ombro) para os dois |

Os quadros do despertar são alinhados ao sprite parado por `tools/pixellab/align_wake.py` (o encaixe deu diferença 0 nos dois personagens).

## Verificação

- `tools/test_protagonist_intro.gd -- OUT aren|moni` cobre o fluxo real nos dois casos, com 22 verificações e 0 falhas: hover, clique, voltar, confirmar, mapa certo, começa sentado, ordem dos estados, sem andar antes do fim, movimento liberado, save e Continuar sem repetir.
- O gdUnit tem 252 casos, todos passando. As regressões de menu, coleta, dia e noite, jardim e fabricação passam pela seleção com `tools/new_game_helper.gd`.
- Capturas em `docs/gameplay/despertar/`.

## Pendente

- A tela de seleção não tem piscar de olhos: falta quadro de piscar.
- Não há sons próprios da cena; ela usa o ambiente que já existe.
- Moni e Aren ainda não têm animação própria de machado (o golpe usa a da enxada).
