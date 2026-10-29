# Slimekeepers: Lost Valley — Protótipo 0.1

Uma primeira experiência jogável, construída com os assets originais fornecidos para o projeto. **Este é um protótipo técnico inicial**, não o jogo completo.

## Como abrir

1. Abra o **Godot 4.7.2**, versão utilizada na validação desta cópia.
2. Selecione **Importar** e escolha o arquivo `project.godot` desta pasta.
3. Espere o Godot importar as texturas na primeira abertura.
4. Pressione **F5** para abrir o menu. **Novo Jogo** inicia a Clareira do Despertar.

## Clareira do Despertar

A primeira região jogável possui 100 × 100 tiles de 32 px (3200 × 3200), spawn central, floresta densa com carvalhos e pinheiros nítidos, cogumelos, samambaias e três trilhas principais. Árvores, troncos e rochas bloqueiam o jogador; flores e vegetação baixa são atravessáveis. A câmera acompanha o personagem dentro dos limites do mapa.

O acabamento atual inclui chão com variação de tons, flores agrupadas nas bordas, recantos de cogumelos luminosos, folhas caindo e HUD compacto. As animações ambientais respeitam a opção de reduzir animações.

A composição mais recente acrescenta um marco ancestral de pedra e flores próximo ao spawn, floresta com densidade variada, sombras sob as copas e dois novos desvios para pequenos recantos. Trilhas têm bordas irregulares, largura variável e cruzamentos contínuos. Detalhes e capturas: `docs/world/REFINAMENTO_COMPOSICAO.md`.

Um pequeno lago de água cristalina fica no nordeste da clareira, com margem simples e animação discreta. Aproxime-se da margem oeste e pressione **E** para examiná-lo. A água possui colisão. A formação rochosa e a saída de água foram removidas a pedido do usuário. Coleta de água e uso em agricultura ainda não estão implementados.

Abra `scenes/regions/ClareiraDoDespertar.tscn` para editar as camadas TileMapLayer, objetos e pontos de saída. `scenes/world.tscn` mantém a entrada utilizada pelo menu. As saídas norte/leste/sul estão reservadas; não carregam outras regiões ainda. Documentação, origem dos sprites e capturas reais: `docs/world/CLAREIRA_DO_DESPERTAR.md`.

## Menu do vale

O acabamento mais recente usa caminhos curvos, chão texturizado, banco, vasos, barris, borboletas e uma placa de título com folhagem. Capturas e testes desta etapa: `docs/SPRITE_POLISH.md`.

O menu usa a nova referência de fazenda e vale, com casa à esquerda, logo superior e quatro ações à direita. A composição é formada por sprites individuais e camadas Godot; a imagem de referência não aparece como textura do jogo. Os três slimes usam as animações originais.

- **Novo Jogo:** abre o mundo e inicia a missão dos três amigos.
- **Continuar:** desabilitado, pois esta versão ainda não possui salvamento.
- **Opções:** reduzir animações do menu (preferência persistente) e tela cheia (sessão atual).
- **Sair:** encerra o jogo.

Mouse, setas, Tab, Enter e eventos de controle navegam pela interface. Esc fecha as opções. O botão **Menu** no gameplay encerra a partida atual e retorna à abertura. Os controles de exploração aparecem somente no gameplay.

Validação atual: 43 verificações do menu e missão, mais 59 da nova região, todas aprovadas no Godot 4.7.2. O menu também possui capturas em 1280×720, 960×540 e 1920×1080. Consulte `docs/PROVIDED_PACK_INTEGRATION.md` para sua seleção de sprites; `docs/UI_VALIDATION.md` preserva a comparação anterior; `docs/ASSET_MANIFEST.md` registra as gerações anteriores. As quatro novas plantas estão documentadas em `docs/world/PIXELLAB_ASSETS.md`.

## Controles

| Ação | Tecla |
|---|---|
| Caminhar em 8 direções | WASD / setas |
| Correr | Shift (segurar) |
| Interagir | E |

## Primeira missão

Encontre Gelito, Brotinho e Brasinha pelo vale e aperte **E** perto de cada um. Ao fazer amizade com os três, a missão estará concluída. Nenhum slime desaparece depois da interação.

## Estrutura

- `project.godot` — configurações do Godot 4
- `scenes/` — mundo, jogador e slime
- `scenes/start_menu.tscn` — tela inicial configurada como cena principal
- `scripts/menu/` — tema reutilizável, interface, panorama e fazenda decorativa
- `scripts/player.gd` — movimento 8 direções e animações
- `scripts/slime.gd` — interação/amizade
- `scripts/world.gd` — controlador original, reutilizado para HUD e amizade
- `scripts/world/` — controlador, geometria das trilhas e ambiente da clareira
- `assets/world/clearing_tileset.tres` — TileSet com chão, vegetação e colisões de pedras
- `tools/build_clearing.gd` — construção explícita da cena editável; reexecutar substitui alterações manuais dessa cena
- `tools/test_clearing.gd` e `tools/test_menu.gd` — verificações de física e integração
- `scripts/terrain.gd` — terreno do protótipo anterior, preservado
- `assets/` — seleção de imagens e recursos originais
- `PLANO_DE_DESENVOLVIMENTO.md` — próximos passos do projeto

## Limitações conhecidas

- A mecânica de amizade é demonstrativa; ainda não há domesticação, inventário funcional, coleta, cultivo ou salvamento.
- As saídas da clareira aguardam implementação das próximas regiões. A ilha completa da referência não faz parte desta etapa.
- A região não possui casas, plantações, inimigos, coleta ou sistema de missões narrativas.
- As animações ambientais são discretas; ainda não há trilha sonora ou paisagem sonora da floresta.

## Créditos e licenças

Assets visuais do pacote fornecido pelo criador deste projeto. A fonte Pixelify Sans acompanha a licença OFL no arquivo `assets/fonts/OFL-PixelifySans.txt`. As condições de uso de outros assets devem ser verificadas antes da publicação.
