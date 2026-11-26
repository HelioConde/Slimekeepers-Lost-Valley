# Slimekeepers: Lost Valley — instruções para Claude Code

Projeto real, não um projeto Godot novo. Antes de propor alterações, leia `README.md`, `project.godot`, os scripts/cenas envolvidos e a documentação pertinente. Use português brasileiro na comunicação e preserve nomes já estabelecidos.

## Base técnica
- Godot **4.7.2**, GDScript, renderização **GL Compatibility**; câmera 2D top-down, movimento em 8 direções e tiles de 32 px.
- Cena principal: `scenes/start_menu.tscn`. Floresta ativa: `scenes/regions/FlorestaDoDespertarV2.tscn`. Não recrie mapas ou cenas existentes por engano.
- Há `addons/gdUnit4` e `addons/godot_mcp`; preserve os addons e seus autoloads.
- Mecânicas já implementadas incluem amizade com Brotinhos, coleta, bolsa e canteiros. Ver `docs/gameplay/` e `PLANO_DE_DESENVOLVIMENTO.md`.
- A fonte narrativa é `docs/narrativa/BIBLIA_NARRATIVA.md` (contém spoilers). Não invente história, personagens, habilidades ou decisões marcadas como EM ABERTO.

## Fluxo de desenvolvimento
1. Inspecione os arquivos reais antes de sugerir código; diferencie o estado atual do plano futuro.
2. Proponha alterações pequenas, identifique cenas, scripts, sinais, Resources e testes afetados.
3. Use GDScript tipado quando fizer sentido; prefira composição, sinais e `TileMapLayer` (não APIs obsoletas).
4. Não sobrescreva arte aprovada, não regenere mapas inteiros e não altere `project.godot` ou a narrativa sem necessidade explícita.
5. Rode os testes/validações disponíveis se houver Godot instalado; se não puder executá-los, declare a limitação. Referências: `tools/validate_forest.ps1`, `tests/` e `addons/gdUnit4`.
6. Para bugs, use `systematic-debugging`; para arquitetura, `godot-specialist`; para GDScript, `godot-gdscript-specialist`; para progressão, `balance-check`.

## Arte, PixelLab e segurança
- Reutilize `assets/` e consulte `docs/ASSET_MANIFEST.md` e `docs/PIXELLAB_INTEGRACAO.md` antes de gerar arte.
- O servidor MCP `pixellab` está declarado em `.mcp.json`, mas **só conecta se PIXELLAB_API_TOKEN existir no ambiente local** e o usuário aprovar o servidor no Claude Code.
- Para pixel art, priorize a skill `pixellab`; `generate2dsprite` e `generate2dmap` organizam entregáveis compatíveis com Godot. `asset-gen` é complementar e **não** instala automaticamente GPU, APIs nem modelos.
- A autorização geral para produção visual está documentada em `docs/PIXELLAB_INTEGRACAO.md`; ainda assim, verifique a necessidade, o inventário, o saldo/custo e os jobs existentes. Não faça POSTs pagos repetidos em caso de timeout/429/resultado ambíguo.
- **Nunca leia, imprima, copie para respostas ou versione tokens, variáveis secretas, arquivos .env ou configurações locais.** Não envie assets ou código a serviços externos sem necessidade. Nunca use `--dangerously-skip-permissions`.
- O repositório é público. URLs de download PixelLab podem funcionar como credenciais de acesso ao asset: evite expor IDs/URLs privados em logs e PRs. Não envie ZIPs privados como artefatos públicos.
- Nenhuma skill deve executar scripts de terceiros, `curl | bash`, `pip install` ou `npx` sem revisão e aprovação explícitas.

## Skills e subagentes do projeto
- Plugin de Godot: `godot-prompter@claude-community` (marketplace declarado em `.claude/settings.json`; o Claude Code pode solicitar confiança/instalação).
- Subagentes locais: `godot-specialist` e `godot-gdscript-specialist`.
- Skills locais: `pixellab`, `generate2dsprite`, `generate2dmap`, `asset-gen`, `balance-check`, `systematic-debugging`.
- Guia de instalação, origem, limites e verificação: `docs/CLAUDE_CODE_SKILLS.md`.

## GodotPrompter
Ao implementar um subsistema Godot, procure primeiro uma skill `godot-prompter:*` adequada, mas não duplique o trabalho dos subagentes locais nem altere o projeto apenas porque um template sugeriu. Prefira a versão do motor declarada em `project.godot` e os padrões já existentes.

## Roteamento automático de modelos (autorizado pelo usuário, 2026-11-26)
- Perfil `balanced` do Guided Model Router: Sonnet é o modelo principal e orquestrador (`model` em `.claude/settings.json`).
- Classificar cada tarefa e subtarefa pela complexidade e **delegar aos subagentes do Model Router sem pedir confirmação**:
  - `quick-haiku`: tarefas simples, pesquisas, pequenas alterações e documentação.
  - `worker-sonnet`: desenvolvimento normal, funcionalidades e testes.
  - `deep-opus`: arquitetura, multiplayer, sincronização, salvamentos, bugs complexos e desempenho.
  - `deep-fable`: só problemas excepcionalmente complexos, quando disponível e dentro dos limites autorizados.
- Não usar um modelo mais forte quando um mais econômico basta. Não delegar quando o modelo principal resolve direto com menos consumo.
- Se um modelo falhar repetidamente ou não conseguir validar o que fez, escalar para o próximo nível.
- O fallback por API do roteador fica desligado (`haiku_fallback: false`); não definir `ANTHROPIC_API_KEY`.
- Preservar as skills especializadas existentes. Não instalar outro roteador.
- Monitorar com `/router-stats`: "sugestões" são dicas, "delegações" são o que de fato rodou. Não confundir as duas.

## Economia de tokens — Claude Code local
- Prefira busca por símbolos e intervalos de linhas; não despeje cenas, logs ou JSON enormes no contexto.
- Use `context-window-hygiene` em sessões longas e `session-handoff-notes` ao retomar trabalho.
- Antes de alegar economia, use `usage-cost-tracking` e compare tokens totais (inclusive subagentes).
- As oito skills estão documentadas em `docs/TOKEN_ECONOMY.md`; não mudam o proxy Astra das Actions.
