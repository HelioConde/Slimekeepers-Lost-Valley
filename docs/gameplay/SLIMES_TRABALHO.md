# Trabalho dos slimes: Colhita, Carreguim, energia e disco de ações (decisões de 2026-11-23)

Direção: Palworld + Stardew Valley (memória do projeto). Slimes sem braços nem pernas.

## Novas espécies (bestiário)

| Slime | Função | Aparência (só natureza, nada de objetos de gente) | Comida favorita |
|---|---|---|---|
| Colhita | colhe as plantas prontas | laranja-pêssego, com um botão de flor no topo que se abre ao colher | pratos cozidos |
| Carreguim | leva ao baú a colheita e tudo o que estiver no chão perto da fazenda | âmbar translúcido; o que carrega aparece flutuando dentro do corpo | pratos cozidos |

- Moram em outros mundos (2 slimes por mundo, combinando com o bioma). **Nenhum bioma novo
  agora**: primeiro as mecânicas básicas. Para testar: comando de admin ou um mundo de teste
  que será apagado depois.

## Baú

- Novo baú que se coloca no chão (receita na bancada; prévia seguindo o mouse, como a bancada).
- O Carreguim leva ao baú escolhido para ele; sem escolha, ao baú mais perto.

## Energia dos slimes (todos os ajudantes)

- Cada slime tem energia; trabalhar gasta. Trabalham enquanto houver energia (sai o limite de
  4 tarefas por dia). A energia enche dormindo à noite.

## Disco de ações

- F num slime amigo abre um **disco de ações** (o usuário vai mandar a imagem de referência):
  Carinho, Dar comida, Trabalho (no Carreguim: escolher o baú de destino; nos outros:
  ligar/desligar) e Seguir/ficar.

Estado: decidido; implementação começa pela arte (aprovação do usuário antes de instalar).

## Construlim, o slime construtor (2026-11-23)

Respostas do usuário:

| Pergunta | Decisão |
|---|---|
| Visual | Argila marrom-avermelhada com pedrinhas e um galhinho no topo; sem braços nem pernas |
| Trabalho | Constrói sozinho a planta (blueprint) mais perto, na região |
| Velocidade | Igual à do jogador: a bancada leva 10 s; os dois juntos levam 5 s |
| Onde vive | Em outro mundo, mais tarde. Por enquanto só chega pelo comando de admin `slimes` |
| Comida favorita | Raízes cruas: cenoura e beterraba |

Implementação:

- **Obra.** `farm_helpers._build_step` leva o Construlim até a planta e soma o tempo de obra com `station_placer.add_progress`. É a mesma função que o jogador usa, então o trabalho dos dois se soma.
- **Energia.** Gasta 15 a cada 5 s de obra, ou seja, 2 tarefas na bancada. Trabalha só de dia e respeita "Parar de trabalhar" e "Ficar em casa" do disco de ações.
- **Arte.** PixelLab, personagem "Construlim V3". As animações são idle, move, blink, happy, sleep, comer, receber_carinho e construir, revisadas quadro a quadro:
  - O move usa os quadros do idle: as versões geradas soltavam as pedrinhas.
  - O happy tirou os 2 quadros em que apareciam pezinhos.
  - O blink fecha e reabre com os mesmos olhos.
  - A instalação usa `tools/pixellab/install_construlim.py`.
- **Limitação.** A casa (modo de construção da casa) ainda não é uma planta, por isso o Construlim constrói só a bancada e o baú.
- **Teste.** `tools/test_construlim.gd`: a bancada fica pronta em cerca de 10 s, o estado é salvo e a energia gasta confere.
