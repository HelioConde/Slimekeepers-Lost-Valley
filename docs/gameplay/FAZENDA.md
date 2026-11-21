# Fazenda e cultivo

Primeira etapa do jogo livre de fazenda (sem missões). Campo de 6×4 células no platô a leste
do riacho do Vale das Nascentes, ao lado da cachoeira (célula 24,12 → 768–960 × 384–512 px).

## Como jogar
- Fique de frente para uma célula do campo e aperte **[E]**: a ação depende do estado —
  **colher** (pronta) › **regar** (seca) › **plantar** (arada e vazia) › **arar** (grama).
- **[R]** troca a semente (pula as que acabaram).
- A cultura sobe **um estágio por dia em que foi regada**; toda a terra seca na virada do dia.
- Colheitas vão para a bolsa (aparecem no painel quando existem).
- Kit inicial (enquanto não há loja): 8 cenouras, 6 beterrabas, 4 repolhos.
- Sementes silvestres da Floresta viram **folhas silvestres** → folhas frescas da culinária.

## Código
| Arquivo | Papel |
|---|---|
| `scripts/systems/crop_catalog.gd` | Culturas: estágios (sprites PixelLab já exportados), semente, colheita |
| `scripts/systems/farm_state.gd` | Estado da sessão: arar, plantar, regar, crescer por dia, colher |
| `scripts/world/farm_field.gd` | Campo na cena: terra procedural (paleta dos solos PixelLab, seca/molhada, bordas pelas vizinhas), culturas com sombra, [E]/[R] |
| `scripts/world/valley_region.gd` | Instala o campo e encaminha o [E] |
| `tools/capture_farm_field.gd` | Simula dias de cultivo e captura o campo |

Estado é de sessão (limpo no Novo Jogo, sem save em disco, como os demais sistemas).
Decoração (mato, flores, cogumelos) dentro do campo some em execução; o mapa não é alterado.
Nenhum crédito PixelLab foi gasto: culturas e paleta vêm de exportações já existentes.
