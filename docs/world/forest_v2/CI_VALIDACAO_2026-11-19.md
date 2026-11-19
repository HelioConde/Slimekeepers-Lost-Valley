# Validação nativa do percurso inicial — 19/11/2026

## Escopo verificado

O Slimekeepers usa **Godot 4.7.2**. A nova workflow `.github/workflows/slimekeepers-godot-gameplay.yml` executa as suítes existentes do jogo no Linux, com download oficial verificado por SHA-256. Não utiliza chamadas de IA, não faz geração visual e não altera o estado do gameplay.

| Suíte | Evidência nativa inicial |
|---|---:|
| `tools/test_menu.gd` | 61 verificações |
| `tools/test_forest_v2.gd` | 157 verificações |
| `tools/test_habitats.gd` | 37 verificações |
| `tools/test_region_travel.gd` | 9 verificações |
| **Total** | **264 verificações** |

A primeira execução detectou uma única incompatibilidade entre teste e cena: a asserção da câmera exigia zoom `1.14`, enquanto o `scenes/player.tscn` e a câmera ativa da floresta usam `0.8`. A expectativa desatualizada do teste foi corrigida; **não houve mudança visual no jogo**. A execução com essa correção está em [GitHub Actions #44605081402](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/runs/44605081402) e concluiu com sucesso.

## O que esses testes comprovam

- O menu abre **Novo Jogo** na Floresta do Despertar v2, e permite retornar.
- O fluxo de fazer amizade com slimes atualiza o contador sem duplicar vínculos.
- Habitats, exclusão de spawn, cooldown e respawn executam verificações físicas.
- A interação pela saída sul conecta Floresta → Vale → Floresta. O ID do slime amigo permanece na sessão e o retorno ocorre longe do gatilho de saída.

## Limites das conclusões

São testes automatizados headless, não playtest humano ou avaliação de qualidade artística. O resultado **não** comprova salvamento em disco, coleta, agricultura ou melhorias no vale, que pertencem a etapas posteriores. O relatório histórico `RELATORIO_FINAL.md` registra medições da configuração local de outubro; o zoom atual confirmado em novembro é `0.8`.

Os logs de importação e de cada suíte são anexados como artifacts ao GitHub Actions para facilitar futuras correções.
