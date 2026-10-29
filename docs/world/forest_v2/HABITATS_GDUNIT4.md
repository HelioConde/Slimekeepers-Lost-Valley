# Validação dos habitats — GdUnit4

Executado em 27/10/2026 com Godot 4.7.2 stable (`ed1daf0bf`).

## Comando PowerShell

```powershell
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\Slimekeepers_Lost_Valley_v0_1' -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/forest -c --ignoreHeadlessMode
```

As opções foram conferidas em `addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd`: `-a` seleciona diretório/suíte, `-c` continua após falhas e `--ignoreHeadlessMode` permite execução sem janela. Os testes usam nós e física reais, sem eventos de entrada nem assertions de renderização.

## Resultado observado

```text
Run Test Suite: res://tests/forest/test_habitats.gd
Overall Summary: 7 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans |
Executed test suites: (1/1)
Executed test cases : (7/7)
Total execution time: 320ms
Exit code: 0
```

Relatórios gerados: `reports/report_1/results.xml` e `reports/report_1/index.html`.

Cobertura: quatro habitats/oito instâncias, identidade estável, limite global dez, exclusão do início, distância entre criaturas, população idempotente, cooldown de reposição, amizade restaurada por instância, cápsula bloqueada por prop sólido, suspensão distante e proteção da posição atual do jogador contra aparecimento de criaturas.

A suíte cria sua própria região e jogador; não carrega o mapa completo. Isto valida o contrato de habitats e a física dos slimes, sem substituir a verificação de integração e a inspeção visual do mapa.
