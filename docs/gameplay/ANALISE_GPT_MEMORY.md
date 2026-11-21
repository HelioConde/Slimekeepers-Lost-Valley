# Análise — Gpt-memory/projetos/Slimekeepers × estado atual (2026-11-21)

Fonte: `HelioConde/Gpt-memory/projetos/Slimekeepers` (README, narrativa-e-canon,
roadmap-e-pendencias, arte-assets-e-prototipos, estado-tecnico, fontes-e-snapshots,
snapshots/). A Bíblia do snapshot é **idêntica** a `docs/narrativa/BIBLIA_NARRATIVA.md`
(só muda o cabeçalho do snapshot).

## O que o projeto quer ser (resumo das fontes)
- Cozy de exploração, sobrevivência, agricultura e convivência com slimes, pixel art 2D 3/4,
  Godot 4.7.2. Mistério pós-catástrofe revelado aos poucos.
- Ciclo central da Bíblia (§4): **cultivar → cozinhar → oferecer comida → vínculo/confiança
  → domesticar → slimes ajudam (inclusive na agricultura) → explorar mais**.
- Espécie/elemento define a função (ex.: slime de água rega); variante (Comum, Raro,
  Arco-íris, Boss) define velocidade de trabalho e qualidade da colheita — números EM ABERTO.
- Início (§7): acordar perdido na floresta, **encontrar abrigo**, ingredientes e slimes,
  começar a cultivar e cozinhar. Nada de explicar a Ruptura no começo.
- Mundo selvagem: slimes com necessidades ecológicas (ex.: Bolhinha precisa de água).
- Protagonista humano, versões masculina e feminina; gênero não fixado.
- Primeira demo canônica: Gelito, Brotinho e Brasinha.
- `Slime-Harvest` (projeto irmão) já tinha hotbar 10, machado, picareta, enxada, regador,
  recursos com drops, passagem de dias e casa em camadas — referência, não código a copiar.

## Alinhado com o que foi feito
| Fonte | Estado atual |
|---|---|
| Cultivo como sobrevivência | Arar/plantar/regar/colher, crescimento por dia regado |
| Comida cria vínculo com slimes | [F] dá colheita/porção, 1×/dia, corações (sem venda) |
| Sem missões impostas; descoberta | Missões e tutorial de teclas removidos do HUD |
| Casa/abrigo | Casa construída pelo jogador, interior e mobília |
| Salvamento | Save em disco ao dormir + Continuar (antes: "não comprovado") |
| Hotbar 10 + ferramentas (Slime-Harvest) | Barra de 10 com enxada e regador animados |

## Conflitos / ajustes recomendados
1. **Casa inicial pronta × "encontrar abrigo"**: a Bíblia pede que o jogador, perdido,
   procure abrigo. Melhor começar sem casa (ou com um abrigo improvisado) e construir a
   primeira casa com materiais coletados. A placa "SUA FAZENDA" também presume posse.
2. **Kit inicial de sementes**: a Bíblia fala em procurar ingredientes; as sementes deveriam
   vir de coleta silvestre (já existe com o Brotinho) e de slimes, não de um kit.
3. **Alimentação sem preferências**: a Bíblia diz que comidas específicas podem importar por
   espécie; o Mundo Vivo já tem preferências (flores, sombra, água). Dá para mapear comida
   por preferência sem inventar números canônicos.
4. **Falta o passo "domesticar → ajudar"**: depois de corações, o slime deveria poder
   acompanhar/ajudar (Brotinho cuida das plantas, Bolhinha rega). Multiplicadores de
   variante ficam EM ABERTO.
5. **Gelito e Brasinha** ainda fora das regiões atuais (só no `world.tscn` obsoleto).
6. **Protagonista feminina/masculino**: só há um sprite; opção pedida no histórico.

## Prioridades sugeridas (alinhadas à Bíblia)
1. Materiais (madeira/pedra) com machado e picareta — assets `assets/Create_an_Axe_*` e
   `Create_a_Pickaxe_*` já existem — e construir a casa gastando materiais.
2. Começo canônico: acordar na floresta, sem casa; erguer o primeiro abrigo.
3. Sementes por coleta/slimes no lugar do kit.
4. Comida preferida por espécie + domesticação (slime amigo ajuda na fazenda).
5. Gelito e Brasinha nas regiões atuais.
6. Necessidades ecológicas (Bolhinha e água), sem morte até decisão do criador.

## Regras a respeitar (das fontes)
- Não preencher nada marcado EM ABERTO; não explicar a Ruptura no início.
- Não misturar `Slime-Harvest` nem a trilha 3D/Blender com o jogo Godot 2D.
- Validar no Godot (jogando), não só em testes headless.
- Preservar assets e fontes; não gerar lotes pagos sem necessidade.
