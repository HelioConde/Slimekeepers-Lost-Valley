# Mundo Vivo 3.0 — execução incremental

Pedido: anexo `a7d1a2a4-ff79-4196-b596-c646adcc4eb2/Texto colado.txt`.
Evoluir a floresta 200×200 e o Vale, preservando mapas, pintura, colisões, caminhos, zoom e o menu. A entrega em branch/PR foi autorizada posteriormente no anexo de correções visuais de 28/10.

## Critérios e sequência

- [x] Auditar relatório v2, GDD extraído, scripts, assets e testes; Godot MCP conectado ao projeto correto.
- [x] Criar checkpoint restaurável e verificar todas as entradas (ver `docs/world/living_v3/checkpoint.json`).
- [x] Reexecutar regressão anterior: 405 verificações + 7 GdUnit4, antes de modificar produção.
- [x] Medir versão atual em 1280×720 durante cinco minutos, usando input real e mesmas rotas.
- [x] Localizar o slime aquático existente no PixelLab e confirmar export concluído.
- [x] Integrar animações aquáticas existentes; completar somente lacunas e fauna/espécie ausentes após autorização do lote.
- [x] Evoluir controlador ambiental compartilhado: materiais por vegetação, rajadas, reação de passagem, borboletas, fauna limitada, sombra de nuvem, áudio e interface simples de condições ambientais.
- [x] Evoluir a IA compartilhada e dados de espécies: preferências, descanso, curiosidade, interações sociais com prioridade e cooldown, retorno ao habitat, amizade persistida na sessão.
- [x] Integrar sistemas nas duas regiões; preservar oito Brotinhos, adicionar Musguinho apenas com arte aprovada e Bolhinha aquático nas margens transitáveis.
- [x] Melhorar descoberta com composição e deslocamentos seletivos sobre caminhos existentes, sem atraso artificial ou redução de velocidade.
- [x] Acrescentar testes focados, executar regressão e verificar redução de movimento, limites, trajetos, viagem e restauração de amizades.
- [x] Capturar telas nativas, corrigir problemas e repetir medição comparável; documentar observações e limitações.

## Divisão de trabalho

Root: integração, posição de habitats, cenas preservadas, descoberta/navegação, MCP, baseline, validação final e relatório.
Ambiente: forest_life, forest_wind, forest_audio, estado ambiental e testes relacionados.
Criaturas: forest_slime, forest_habitats, dados de espécie e testes relacionados.
Arte: export aquático, assets adicionais autorizados e SpriteFrames, inventário PixelLab.

Nenhum agente altera produção enquanto a medição inicial estiver em curso. Contratos preservam APIs antigas. A autorização contínua do usuário dispensa confirmação por etapa; créditos novos exigem aprovação explícita do lote.

## Preservação e evidência

Comparar hashes das cenas e PNGs com o novo checkpoint. Não rebakear mapas. Transições existentes permanecem. Testes antigos só mudam quando a expectativa funcional foi deliberadamente ampliada, mantendo as verificações de colisão e preservação. Preferências locais não devem ser alteradas pelos testes.
Os números históricos do relatório v2 são referência; resultados desta execução serão registrados separadamente em `docs/world/living_v3`.

## Encerramento da validação

Resultados finais e limites: `docs/world/living_v3/RELATORIO_FINAL.md`. Repetição solicitada pelo usuário: 6.174 verificações e 7 casos GdUnit4 aprovados. Godot MCP indisponível na rodada final; CLI nativa utilizada.
