# Primeiro ciclo de coleta — Brotinho e sementes silvestres

## Funcionalidade

Esta entrega implementa um **protótipo de coleta**, não um sistema de fazenda, cozinha ou progressão completo.

1. Abrir **Novo Jogo** e explorar a Floresta do Despertar v2.
2. Encontrar um Brotinho e pressionar **E** para fazer amizade.
3. Procurar pequenas plantas com sementes nos caminhos do Jardim das Folhas, Bosque dos Cogumelos e Campo dos Brotos.
4. Pressionar **E** sobre um broto disponível. A amizade com **qualquer Brotinho da floresta** libera a habilidade inicial de recolher sementes.
5. O painel **Bolsa · sementes silvestres: N/3** atualiza imediatamente. Um ponto de coleta só pode ser utilizado uma vez por partida.
6. Viajar ao Vale das Nascentes e retornar à floresta: os itens e pontos já coletados permanecem na **mesma sessão**.
7. Voltar ao menu e escolher **Novo Jogo**: bolsa, amizades e pontos de coleta recomeçam vazios.

A interpretação é uma **técnica aprendida com o Brotinho**. Não foi implementada uma bolsa mágica herdada; essa hipótese antiga não é canônica, conforme `docs/narrativa/BIBLIA_NARRATIVA.md`. A coleta não inventa revelações da história ou poderes adicionais.

## Código

- `scripts/systems/forest_bag.gd`: inventário mínimo e prevenção de coleta duplicada por ID de recurso
- `scripts/world/forest_seed_patch.gd`: recurso visual pixel-art simples e estado de coleta
- `scripts/ui/forest_bag_hud.gd`: painel da bolsa compartilhado pelas duas regiões
- `scripts/world/forest_region.gd`: instâncias de coleta, prioridade de interação e feedback
- `scripts/world/valley_region.gd`: visualização do mesmo inventário da sessão
- `scripts/menu/start_menu.gd`: limpa estados ao iniciar uma nova partida
- `tools/test_forest_foraging.gd`: teste end-to-end real no Godot

## Fora do escopo

Não há save em disco, plantio, fabricação, cozinha, seguidores, regeneração automática das plantas ou melhoria do vale. A coleta só desbloqueia a bolsa inicial; o consumo das sementes poderá ser conectado à agricultura/cozinha quando esses sistemas forem planejados.

## Verificação

O workflow `Slimekeepers - Testes reais de gameplay no Godot` executa a suíte `tools/test_forest_foraging.gd`, além dos testes anteriores de menu, habitats, floresta e viagem. Ele baixa o Godot 4.7.2 oficial, verifica SHA-256 e guarda os logs em artifacts. Aprovação da Action é teste automatizado headless, não playtest humano.
