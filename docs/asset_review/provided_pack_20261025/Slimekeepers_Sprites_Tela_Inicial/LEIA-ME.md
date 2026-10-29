# Slimekeepers: Lost Valley — sprites da tela inicial

## O que há neste pacote

Este pacote contém elementos SEPARADOS em PNG e transparência real, prontos para importar no **Godot 4**:

- `01_Fundos`: duas versões do cenário do vale, com céu, montanhas, rio e cachoeira — fundos retangulares opacos para camadas distantes;
- `02_Casa`: casa principal, casas menores, portas, janelas, cercas, poço e floreiras;
- `03_Arvores`: árvores, pinheiros e arbustos;
- `04_Agua_Cachoeiras`: cachoeira grande, cachoeira lateral, rochas aquáticas e módulos de água;
- `05_Terrenos`: amostras de chão, pedras e grama;
- `06_Plantacoes_Objetos`: canteiros, vegetação, cercas e objetos da fazenda;
- `07_Protagonista`: poses de exemplo para compor o menu (não substituem as animações originais do jogo);
- `08_Slimes`: variações estáticas de slimes de água, fogo e natureza;
- `09_Decoracoes`: ponte, placas, borboletas e mobiliário;
- `10_Interface`: logo, botões com texto e ícones;
- `11_Assets_Originais`: seleção dos assets que já existiam no seu `assents.zip`, preservados sem edição, incluindo os tilesets 32×32 e spritesheets dos três slimes;
- `12_Referencia`: arte conceitual original em uma única imagem, apenas para comparação.

Arquivo `PREVIA_ASSETS.png`: visão geral de exemplos.

## Como usar no Godot 4

1. Extraia o ZIP em `res://assets/menu_principal/` ou importe as pastas desejadas.
2. No Godot configure **Texture Filter = Nearest** nos nós 2D para manter o visual pixel art.
3. Crie uma cena `Control` e use `TextureRect` para o fundo, o logo e decorações; use `TextureButton` para a interface (ou um `Button` sobre cada imagem para facilitar foco por teclado).
4. Comece com o fundo `01_Fundos/vale_cenario_16x9.png`. Coloque a casa sobre ele, em primeiro plano, e a cachoeira como elemento animável independente. Atenção: o fundo já mostra uma cachoeira integrada na paisagem; para animar água, você pode sobrepor os módulos na região adequada.
5. Os sprites na pasta `10_Interface` já contêm o texto dos botões. Para tradução/mudança de nome, prefira o `botao_base_sem_texto.png` da pasta de originais e desenhe o texto usando `Label`.

## Notas de produção importantes

- **São sprites ilustrativos recriados a partir do conceito**, não separação pixel a pixel exata da ilustração anterior. Não existe informação sobre camadas escondidas de elementos no arquivo plano original.
- As peças do atlas gerado têm dimensões diferentes e **não formam automaticamente um tileset uniforme**. Para mapas de gameplay, use `11_Assets_Originais/tileset_..._32.png` ou redesenhe um tileset padronizado.
- O pacote não inclui animações prontas de cachoeira, água ou personagem (somente imagens estáticas). Para animar no Godot, utilize frames adicionais e `AnimatedSprite2D` ou `AnimationPlayer`.
- Não há efeitos sonoros, scripts de menu, nem cena Godot neste ZIP: ele entrega especificamente os arquivos gráficos solicitados.
- Os PNGs com recortes têm canal alfa. O cenário de fundo é retangular e opaco, como esperado.

## Quantidade por pasta

- 01_Fundos: 2 imagens
- 02_Casa: 16 imagens
- 03_Arvores: 13 imagens
- 04_Agua_Cachoeiras: 9 imagens
- 05_Terrenos: 12 imagens
- 06_Plantacoes_Objetos: 19 imagens
- 07_Protagonista: 15 imagens
- 08_Slimes: 18 imagens
- 09_Decoracoes: 15 imagens
- 10_Interface: 9 imagens
- 11_Assets_Originais: 12 imagens
