# PixelLab — vegetação da Clareira do Despertar

Data: 26/10/2026. Destino: `C:\Slimekeepers_Lost_Valley_v0_1`.

Esta rodada recebeu autorização explícita para até quatro gerações pagas: cogumelos vermelho, marrom e luminoso, mais uma samambaia. Foram realizadas exatamente **4 chamadas de geração**, sem novas tentativas ou variantes extras. Nenhum sprite preexistente foi alterado.

## Procedimento

A [documentação oficial do PixelLab MCP](https://api.pixellab.ai/mcp/docs) e o schema disponível das ferramentas foram consultados antes da execução. As gerações usaram `create_map_object`; cada objeto recebeu confirmação `status: completed` e `background: transparent` por `get_map_object` antes do download. Os arquivos PNG foram baixados pelos links retornados pelo MCP, sem usar REST para substituir as operações de geração ou status.

Parâmetros comuns: `view="low top-down"`, `outline="selective outline"`, `shading="medium shading"`, `detail="medium detail"`, modo básico. A ferramenta não expõe seed nem retornou custo individual por objeto; esses dados ficam registrados como indisponíveis.

## Entregáveis

| Arquivo em `assets/world/forest/` | Canvas | Retângulo visível `(x,y,w,h)` | ID do objeto | Resultado |
|---|---:|---|---|---|
| `mushroom_red.png` | 32×32 | `(6,3,21,26)` | `bc50e069-b2ff-4611-8d3b-35163068a456` | Concluído, baixado e inspecionado |
| `mushroom_brown.png` | 32×32 | `(4,3,24,26)` | `23265d98-3d20-496d-84ac-f9806b3a6f9c` | Concluído, baixado e inspecionado |
| `mushroom_glow.png` | 32×32 | `(4,2,24,27)` | `0e1e1a6c-d7aa-4ddc-b9b4-19f2a74b7208` | Concluído, baixado e inspecionado |
| `fern.png` | 48×48 | `(8,3,34,36)` | `9b2b190e-680c-4f72-a375-d8b8d74e528a` | Concluído, baixado e inspecionado |

Os quatro PNGs mantêm os bytes fornecidos pelo serviço. A leitura do canal alfa encontrou somente valores0 e255, sem transparência parcial, fundo opaco ou recorte tocando os limites do canvas. As inspeções visuais confirmaram silhuetas distintas, pixels nítidos e ausência de texto. O cogumelo luminoso contém realces ciano; iluminação sobre o ambiente deve ser realizada separadamente pelo Godot.

Com um personagem de aproximadamente65px, os cogumelos em escala1 têm cerca de26px de altura visível e a samambaia cerca de36px. Use filtro Nearest e ancore o rodapé pelo retângulo visível para evitar objetos flutuando. A validação do posicionamento e do contraste na cena final pertence à etapa de integração, não é substituída por esta inspeção dos PNGs.

## Prompts exatos

### Cogumelo vermelho

```text
Single small woodland mushroom with a rounded red cap and a few cream white spots, short ivory stem. Cozy fantasy farming RPG pixel art, three quarter top down environmental prop, crisp one pixel clusters, earthy subdued colors, dark brown selective outline, sunlight from upper left. Complete object centered with a little transparent margin, isolated transparent background, no scenery no ground patch no text.
```

### Cogumelo marrom

```text
Single small woodland mushroom with a rounded chestnut brown cap, warm ochre highlight and short cream stem. Cozy fantasy farming RPG pixel art, three quarter top down environmental prop, crisp one pixel clusters, earthy subdued colors, dark brown selective outline, sunlight from upper left. Complete object centered with a little transparent margin, isolated transparent background, no scenery no ground patch no text.
```

### Cogumelo luminoso

```text
Single small magical woodland mushroom with a turquoise mint cap, pale luminous aqua gills and short cream stem. Cozy fantasy farming RPG pixel art, three quarter top down environmental prop, crisp one pixel clusters, dark teal selective outline, restrained bright mint highlights on the cap suggesting bioluminescence, no blurred halo. Complete object centered with transparent margin, isolated transparent background, no scenery no ground patch no text.
```

### Samambaia

```text
Single compact woodland fern plant, rosette of six gently arching pinnate fronds with clearly readable small leaflets, moss and olive green highlights with deep forest green shadows. Cozy fantasy farming RPG pixel art, three quarter top down environmental prop, crisp one pixel clusters, subdued natural palette, selective dark green outline, sunlight from upper left. Complete plant centered with transparent margin, isolated transparent background, no pot no soil no scenery no text.
```

## Saldo observado

| Consulta | Franquia restante | Franquia utilizada | Créditos monetários |
|---|---:|---:|---:|
| Antes desta rodada | 4.622,20 | 377,80 | US$0,00 |
| Após os quatro objetos concluídos | 4.618,20 | 381,80 | US$0,00 |

Diferença observada: **4,00 unidades de franquia**. O MCP não forneceu recibo individual por job; o delta é uma observação de saldo da conta compartilhada. O contador diário passou de5 para1; conforme a resposta do serviço, isso acompanha a mesma cobrança, não uma segunda cobrança. Plano informado: Pixel Artisan, tier2.

## Integridade

| Arquivo | SHA-256 |
|---|---|
| `mushroom_red.png` | `EE4E0CB03A5020341849E25CADE0341C0880311E50BA7EA8DF76AF0FD6E6062A` |
| `mushroom_brown.png` | `9CEAFFA56A5C6D390B55ABD81881DDD052E925D2B951DB707B9D74DF2630A224` |
| `mushroom_glow.png` | `A036CD3F1E7A908E65441E769B2105CEE3D9B2A755EF92B1B9A80DEABBAF1B08` |
| `fern.png` | `C42665B1D4B7A408C89D465C7669162D500567CE4F1AEF319C7F219918D9201A` |

Nenhuma credencial foi incluída nos arquivos ou neste documento.
