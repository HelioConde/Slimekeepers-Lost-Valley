# Auditoria real das cenas e do estado de gameplay — Fase 2

## Escopo conferido no código existente
- Floresta: `scenes/regions/FlorestaDoDespertarV2.tscn`, runtime `scripts/world/forest_region.gd`. Movimento do jogador, amizade (Brotinho), três manchas de sementes e transição ao Vale com a ação `interact`/E.
- Vale: `scenes/regions/ValeDasNascentes.tscn`, runtime `scripts/world/valley_region.gd`. Dois canteiros (`norte` em 1440,560 e `sul` em 1390,625), `GameClock`, bolsa na HUD, interação E, saída ao norte em 1600,70.
- Transporte: `scripts/world/region_travel.gd` usa `change_scene_to_file` com `SceneTree` preservado.
- Menu: `scripts/menu/start_menu.gd::_start_game` apaga os metadados de sessão ao criar Novo Jogo e reinicia `GameClock`. `Continuar` está desativado: não alegar save.
- Bolsa efetiva: `scripts/systems/forest_bag.gd` mantém o único saldo em `SceneTree` com chave `forest_bag_items`. `collectible_inventory.gd` existe, mas não é usado pelo gameplay.
- Cultivo: `scripts/systems/valley_starter_garden.gd` consome `sementes_silvestres`, cresce em 120 minutos do relógio e gera `folhas_frescas`. Estado da plantação em `valley_starter_garden`; cada canteiro rende uma folha.
- Culinária isolada: `cooking_recipe_book.gd`, `cooking_ingredient_rules.gd` e `cooking_serving_ledger.gd` não estavam ligados à cena ou à bolsa. Nenhuma receita canônica é definida na Bíblia Narrativa.

## Prioridade e fluxo para integração
1. Preservar `forest_bag_items` como única fonte de verdade: não criar segundo saldo paralelo. Adaptar ao `collectible_inventory` apenas por snapshot validado.
2. Criar receita explicitamente de **protótipo**, sem assumir nome, efeitos ou preferência de slime canônicos.
3. Oferecer um ponto de preparo discreto na trilha do Vale, separado dos canteiros e da saída. Interação E valida folhas, consome uma vez e registra preparo no `SceneTree`.
4. Atualizar o HUD da bolsa e mensagens; preservar saldo e registro ao viajar. Limpar chave de culinária em Novo Jogo.
5. Cobrir o ciclo real com o teste `tools/test_valley_garden.gd`: ausência de ingredientes, duas colheitas, preparo, tentativa repetida, viagem e Novo Jogo.

## Contratos de compatibilidade
- A prioridade atual de E no Vale é **saídas > canteiros > slimes > pontos de interesse**. A estação só assume E a curta distância, antes dos canteiros, sem interceptá-los.
- `GameClock` não deve ser reiniciado na troca de regiões; somente em Novo Jogo.
- Não mover slimes, mudar mapa, substituir assets ou inventar diálogos e preferências da Bíblia Narrativa.
- `scripts/ui/forest_bag_hud.gd` é utilizado nas duas regiões. Exibir pratos nela sem criar inventário visual divergente.

## Riscos e validação
- Canções, receitas finais, efeitos e sistema completo de vínculo são **EM ABERTO**. O preparo nesta etapa não cria vantagem narrativa.
- UI e interação precisam de teste com movimento real/tecla E: unit tests isolados não bastam.
- Testar Godot 4.7.2 headless, as seis suítes nativas (329+ checks acumulados), e manter PR sem merge se regressões aparecerem.
- PixelLab: não há necessidade de gerar imagem paga para validar o ciclo; primeiro usar o cenário e desenhar marco técnico discreto.
