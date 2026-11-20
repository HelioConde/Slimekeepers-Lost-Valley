# Esquema de salvamento V1 (somente snapshot, sem gravação)

**Fase 2 / p2-save-schema.** Implementado em `scripts/systems/session_save_schema.gd` e validado em `tests/forest/test_p2_session_save_schema.gd`.

Este formato prepara um contrato de dados JSON-safe para a vertical slice atual. **Não grava `user://`, não restaura automaticamente o jogo e não ativa o botão Continuar.** O mecanismo futuro precisará de restauração transacional dos sistemas, posição do jogador, regiões, testes de compatibilidade e prova de integridade antes de habilitar a interface.

## Conteúdo fechado do snapshot V1

- `version: 1`: número obrigatório e exato; rejeita versões desconhecidas.
- `clock`: objeto `version/day/minutes` obtido de `GameClock.get_save_data()`.
- `bag`: quantidades positivas por item, usando o inventário real (sementes, folhas e porções).
- `seed_patches`: manchas já coletadas na Floresta.
- `garden`: estado dos dois canteiros iniciais, com `planted_at` e `harvested`.
- `harvests`: linhas com `cycle`, `bed_id` e `resources`, evitando chaves inteiras que o JSON converteria implicitamente.
- `meals_prepared`: contagem do histórico de preparos, **não** o objeto interno `cooking_serving_ledger` de GDScript.
- `food_offers`: primeira oferta por slime e receita de protótipo.
- `progress`: quatro marcos verificados na sessão.
- `forest_friends` e `valley_friends`: mapas de identidade/amizade já registrados.

O snapshot **não contém** tokens, chaves de API, endereço do usuário, sprites, caminhos arbitrários, objetos RefCounted, nós, scripts ou recursos executáveis. Não lê metadados extras não declarados. O esquema recusa dados não finitos, tipos inesperados, IDs inválidos e duplicações de colheita/oferta.

## Uso futuro

1. `SessionSaveSchema.capture(tree, GameClock)` produz um dicionário independente apenas se o estado real for válido; falhas retornam `{}` sem corrigir dados silenciosamente.
2. `SessionSaveSchema.validate(snapshot)` confere o objeto inteiro de maneira **somente leitura**.
3. `JSON.stringify(snapshot)` e `JSON.parse_string(encoded)` devem preservar um objeto validável, coberto por testes GdUnit4.
4. Antes de implementar uma gravação real: formalizar o identificador do mapa atual, posição/direção do jogador, versões e migrações, checksum e estratégia de rollback; restaurar em objeto temporário, validar consistência de todas as dependências e só então aplicar ao `SceneTree`.
5. Até a restauração transacional com QA de viagem e Novo Jogo, manter **Continuar desabilitado** e não prometer jogo salvo.

**Limitação deliberada:** o snapshot é uma especificação verificável, não um save funcional. A tarefa seguinte `p2-session-reset-qa` deve cobrir reinícios e viagens, sem representar serialização como persistência ativa.
