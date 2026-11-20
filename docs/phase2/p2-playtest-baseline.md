# Baseline reproduzível do jogo — Fase 2

## Cenários de entrada
**Engine:** Godot 4.7.2 oficial, Linux headless; importar primeiro `godot --headless --editor --path . --import`.

1. Menu de título: `tools/test_menu.gd`; Novo Jogo leva à Floresta e reinicia `GameClock`. O botão Continuar continua desabilitado.
2. Floresta: `tools/test_forest_v2.gd` e `tools/test_habitats.gd`; três slimes originais, habitantes adicionais, limites, movimento, interações e renders.
3. Viagem: `tools/test_region_travel.gd`; usar E para ir Floresta → Vale → Floresta e preservar amizades.
4. Coleta: `tools/test_forest_foraging.gd`; amizade com Brotinho, três manchas, HUD com sementes e reinício.
5. Cultivo: `tools/test_valley_garden.gd`; dois canteiros, 120 minutos, duas folhas, saldo preservado na viagem e limpeza em Novo Jogo.

## Comandos de verificação
```sh
godot --headless --editor --path . --import
for suite in test_menu test_forest_v2 test_habitats test_region_travel test_forest_foraging test_valley_garden; do
  godot --headless --path . --script "res://tools/$suite.gd"
done
```

O workflow existente `.github/workflows/slimekeepers-godot-gameplay.yml` já executa essas seis suítes e arquiva os logs em artifacts, com mínimos de checagens por suíte.

## Base verificada e lacunas
A última execução nativa anterior a esta alteração, [run #44650994742](https://github.com/HelioConde/Slimekeepers-Lost-Valley/actions/runs/44650994742), concluiu com `success`. Os módulos novos de culinária/inventário haviam sido integrados e testados isoladamente, **mas não havia interação jogável de preparo**. Qualquer nova funcionalidade precisa preservar o baseline e adicionar testes de gameplay verificáveis. A aprovação da nova PR deve ser conferida separadamente; este documento não antecipa o resultado.
