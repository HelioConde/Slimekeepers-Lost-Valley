# Slimekeepers: Lost Valley — cenário-vitrine explorável

A cena `scenes/object_catalog_demo.tscn` reutiliza o Player **original** de `scenes/player.tscn` (escala visual 0.40), com animações e movimentação do projeto. A câmera segue o personagem e seus limites são aumentados automaticamente para percorrer todas as zonas.

## Controles

| Tecla | Ação |
|---|---|
| `WASD` ou setas | Andar livremente |
| `Shift` | Correr |
| `Espaço` | Dash |
| `1` a `7` | Ir diretamente ao setor indicado no topo da tela |
| `Page Up` / `Page Down` | Setor anterior / próximo |
| Roda do mouse ou `+` / `-` | Zoom da câmera |

O catálogo percorre automaticamente `sprites/objects/pixellab_exports/` em tempo de execução, sem editar os PNGs, e mostra **um objeto por pasta**. Quando a imagem contiver múltiplas direções, usa os metadados JSON para exibir apenas a primeira célula do spritesheet como amostra (em vez de comprimir a folha inteira).

Os objetos são organizados nas áreas Floresta, Mineração, Fazenda, Construções, Ruínas e Magia, Efeitos e Diversos. As categorias sem objetos não aparecem. Os nomes das categorias no jogo não usam acentos para maximizar compatibilidade de fontes.

## Executar no Godot 4

1. Atualize o repositório: `git pull origin main` (ou extraia este pacote na raiz do projeto).
2. Abra `scenes/object_catalog_demo.tscn`.
3. Execute a cena atual com **F6** (não F5, que inicia o jogo principal).
4. Clique na janela do jogo e mova-se com `WASD` ou as setas.

Para deixar essa cena como inicial temporariamente, selecione-a no FileSystem, clique com o botão direito e escolha **Set as Main Scene**; ou continue testando com **F6**, sem alterar `main.tscn`.

## Notas

- Os objetos são **expositores sem colisão**, para facilitar a visita. Existem somente bordas externas invisíveis.
- O cenário pode ser extenso: use os números `1` a `7` ou `Page Up`/`Page Down` para navegar entre os setores.
- Ausência de objetos: verifique se os PNGs e JSONs exportados existem em `sprites/objects/pixellab_exports/` e se o Godot terminou de importar as texturas.
- Essa cena não substitui nem modifica as cenas de floresta e o jogo principal.

## Proporções revisadas e comparação com o protagonista (v3)

O personagem jogável mantém sua escala `0.40`, **sem alteração**.
Cada vitrine ganha uma cópia visual semitransparente do personagem (sem movimento,
colisão ou script) à esquerda do objeto, para referência de altura. Abaixo da
imagem aparece o percentual de altura do objeto em relação ao personagem.

O dimensionamento leva em conta **o retângulo de pixels visíveis (alfa)** de cada
objeto, não a área transparente do PNG. Também limita largura e altura, para
troncos horizontais não parecerem longos demais. A escala das **árvores em pé
permanece inalterada** (inclusive árvores frutíferas e carvalhos).

| Categoria | Altura-alvo máxima relativa ao Player |
|---|---:|
| Troncos caídos | 42% |
| Tocos de árvores | 48% |
| Plantações pequenas (estágios) | 27% |
| Canteiros | 44% |
| Terra preparada | 33% |
| Flores e gramas | 40% |
| Arbustos | 48% a 66% |
| Fogueiras | 42% |
| Caixas, baús e barris | 58% |
| Rochas comuns | 60% |
| Árvores em pé | **sem alteração** |

**Os alvos acima não são tamanhos forçados**: se o objeto já couber menor pela
regra de largura, manterá essa dimensão. Peças grandes como portais e construções
completas podem ultrapassar a altura do personagem.

### Controles visuais no Inspector

No nó raiz `ObjectCatalogDemo`:

- `Show Player Reference`: mostra/oculta as referências do protagonista ao lado de cada objeto (ativado por padrão).
- `Show Height Comparison`: mostra/oculta a altura relativa abaixo do nome (ativado por padrão).
- `Non Tree Scale`: multiplicador adicional aplicado **somente** a objetos que não sejam árvores em pé (`1.0` = ajuste recomendado).
- `Maximum Preview Scale`: limite superior para as árvores e prévias no catálogo.

Os nomes e as comparações são desenhados na cena; não alteram nem geram arquivos de sprite.

### Instalação

Extraia este ZIP na raiz do seu projeto `C:\Slimekeepers Lost Valley`, substituindo
`scenes/object_catalog_demo.tscn` e `scripts/object_catalog_demo.gd`. A cena principal
`main.tscn` e o controlador do jogador não são modificados. Abra a cena do catálogo
e execute-a com **F6**. A importação de todos os PNGs pode levar algum tempo no
primeiro carregamento do Godot.
