# Contrato bolsa/inventário da Fase 2

## Fonte de verdade
O único saldo jogável fica em `SceneTree` com `forest_bag_items`, usado por `forest_bag.gd`, manchas de sementes, canteiros, HUD e transições. **Não** adicionar uma segunda instância persistente de bolsa que possa divergir na troca de região.

## IDs já utilizados
- `sementes_silvestres`: aumenta pela coleta ajudada pelo Brotinho; diminui ao plantar.
- `folhas_frescas`: aumenta quando um canteiro amadurece e é colhido.
- Um prato de teste preparado deve ser registrado em um **ledger distinto**, não inserido como folha ou semente.

## Adaptador
- `ForestBag.inventory_snapshot(tree)` cria um retrato com IDs de string e quantidades inteiras estritamente positivas; zero no metadado legado vira ausência no retrato.
- `ForestBag.spend_item(tree,id,qty)` e `add_item(tree,id,qty)` validam o estado todo antes de fazer uma única alteração no meta. Recusas preservam a bolsa.
- `seeds()`, `leaves()`, `spend_seed()`, `add_leaves()` e `harvest()` preservam a API e o comportamento existentes para não quebrar os testes nativos.
- O componente `collectible_inventory.gd` valida a transação; não detém estado global. Isso evita bolsa duplicada e deixa o núcleo reutilizável.
- Culinária valida ingredientes contra o mesmo retrato, sem confiar em um saldo de interface. Só registra uma porção se o débito real for possível. Os registros do preparo vivem apenas na sessão e são apagados pelo menu Novo Jogo.

## Critérios de segurança e testes
Quantidade negativa, zero, fracionada, ID vazio, saldo insuficiente e inventário malformado são recusados sem alteração parcial. Colheita repetida, E repetido, troca de mapa e Novo Jogo devem ser cobertos. Não são definidos efeitos de alimento, preferências canônicas ou salvamento em disco.
