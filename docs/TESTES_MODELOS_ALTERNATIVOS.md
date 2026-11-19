# Teste dos outros modelos — Codex Proxy

Além dos modelos de desenvolvimento principal **gpt-6.2-astra** e reserva **gpt-6-astra**, o monitor do Slimekeepers fará testes curtos das seguintes variantes de **texto**, em ordem: `gpt-6.2-sol`, `gpt-6.1-sol`, `gpt-6-sol`, `gpt-6-luna`, `gpt-6.1-terra`, `gpt-5.6-sol`, `gpt-5.6-terra` e `gpt-5.6-luna`.

## Quando os testes ocorrem

O GitHub Actions já verifica diariamente os modelos e a cota às **11h43 e 17h43 (horário de Brasília)**. Se a cota estiver esgotada, registra apenas a lista de modelos e os limites, **sem qualquer inferência**.

A primeira vez em que a cota permitir, o monitor tenta o smoke já programado no modelo principal, com uma reserva permanente `ai/proxy-model-smoke-once`.

Nas execuções agendadas seguintes em que a cota estiver disponível, escolhe **um** outro modelo de texto ainda não testado. Antes de cada POST, registra no GitHub uma branch `ai/model-smoke-<id-do-modelo>`. A reserva impede repetições após falha, timeout ou HTTP 429. Não há fallback nem retentativa depois de disparar a inferência.

Cada teste de texto pede uma resposta exata e curta (`SLIMEKEEPERS_MODEL_OK`, máximo de 96 tokens). Uma chamada 2xx que não cumpra o contrato **não é considerada sucesso**. O arquivo de relatório e os logs são saneados e guardados por 14 dias no artifact do workflow. Resultados como `working`, `http_429`, `contract_not_verified` e `network_or_timeout_unknown` não são confundidos com simples presença no catálogo.

Esta fila de testes é **limitada a oito modelos**, uma tentativa por modelo. Não inclui `codex-auto-review` ou `gpt-reserve`, pois a finalidade desses aliases não está comprovada; nem `gpt-image-1.5` ou `gpt-image-2`, pois gerar imagens é outro tipo de chamada.

## Limitações

- Estar listado pelo GET /v1/models não comprova capacidade de gerar texto.
- Uma resposta HTTP 429 pode significar limite da conta e não problema específico daquele modelo.
- Os testes podem consumir cota; não criam código Godot, PR de gameplay ou imagens.
- O usuário pode desabilitar o workflow **Slimekeepers - Monitorar modelos e limites do proxy** na aba GitHub Actions para suspender a fila.
- As branches de reserva servem como checkpoints de tentativa; não removê-las sem revisar os artifacts.
