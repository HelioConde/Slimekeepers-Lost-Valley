# Bestiario Slime-Harvest no Slimekeepers — demo da Clareira Encantada

A cena `scenes/enchanted_clearing_demo.tscn` recebe uma população ambiental baseada no bestiário autoral do **Slime-Harvest**. Reaproveitamos as mesmas **32 espécies**, os PNGs originais e os `SpriteFrames` completos (por espécie), enquanto a lógica de passeio é uma versão leve específica para a Clareira.

## Importação dos arquivos
Os 32 pares `.png` e `_frames.tres` são transferidos de:
`HelioConde/Slime-Harvest/assets/slimes/bestiary/<especie>/`

para o mesmo caminho `assets/slimes/bestiary/` dentro de Slimekeepers. Isso preserva as referências `res://assets/slimes/bestiary/...` usadas pelos recursos de animação.

O workflow `.github/workflows/importar_slimes.yml` faz a cópia por GitHub Actions automaticamente quando publicado e permite repetição manual via Actions. **Se o Actions estiver desativado ou sem permissão de escrita**, execute no PowerShell (raiz do projeto):
```powershell
.\tools\importar_slimes_slimeharvest.ps1
```
Após copiar, registre os arquivos com `git add assets/slimes/bestiary` e faça commit/push.

## Habitat de teste
| Área | Espécies |
|---|---|
| Horta | brotinho, colhita, compo, terrinho, capinito, fiapo, seletim |
| Lagoa | gota, riacho, chuvao |
| Rochas | pedrito, ferrito, engrenito, prismita, faisca, gelito |
| Floresta | lenhoco, raizela, pomelo, funguinho, chefito, noturno, alquimita, guardito |
| Prado | polenita, melado, curinha, ventinho, lumito, brasinha, carreguim, construlim |

Cada espécie aparece uma vez (total **32 slimes**), com semente de distribuição determinística. O motor procura pontos caminháveis, evita a água, obstáculos, colisões do mapa, a casa construída e um raio ao redor do spawn do personagem.

Os slimes utilizam `idle` e `move` dos próprios `SpriteFrames` e se deslocam lentamente perto do habitat de origem. O sprite mantém filtro nearest e escala visual própria para ficar menor que o protagonista (escala do Player = 0.40).

**Escopo de protótipo:** essas criaturas são pacíficas e decorativas; **não** foram trazidas ainda as rotinas do Slime-Harvest de fome, água, personalidade, trabalho, combate ou captura. Os slimes não são salvos e reaparecem no reinício da cena.

## Estrutura
- `scripts/slimes/ambient_slime.gd`: deslocamento e animações de cada slime.
- `scripts/slimes/clearing_slime_population.gd`: spawns por bioma + verificação de terreno e colisão.
- `assets/slimes/bestiary/`: 32 PNGs e 32 `SpriteFrames` do projeto original.
- `scenes/enchanted_clearing_demo.tscn`: instancia o gerenciador ao abrir F6.
- `tools/importar_slimes_slimeharvest.ps1`: importação alternativa para Windows.

O construtor automático de casa, o mini inventário, o terreno 32×32 e as ferramentas existentes continuam funcionando. A validação visual ainda precisa ser feita no Godot.
