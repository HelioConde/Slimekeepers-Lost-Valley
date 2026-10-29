# PixelLab — assets do Mundo Vivo 3.0

## Origem e preservação

Documentação consultada: https://api.pixellab.ai/mcp/docs (27/10/2026).
Auditoria feita pelo MCP PixelLab; nenhuma chamada REST substituiu geração MCP.
Saldo inicial: 4.591,20 gerações de 5.000, US$ 0,00 em créditos, Pixel Artisan Tier 2,
renovação em 24/11/2026. Nenhuma geração executada nesta integração inicial.

Bolhinha reutiliza o slime de água já criado, sem duplicar uma espécie equivalente.
Character ID: `48e3207b-546f-4fa7-bf90-e67d8bd3105c`.
Group ID: `49a6c2b0-4311-48fb-beec-1aea4cc19042`; estado único `Idle`.
Status `completed` confirmado antes do download.

- ZIP: https://api.pixellab.ai/mcp/characters/48e3207b-546f-4fa7-bf90-e67d8bd3105c/download
- Spritesheet opcional: https://api.pixellab.ai/mcp/characters/48e3207b-546f-4fa7-bf90-e67d8bd3105c/spritesheet
- Export integral: `assets/slimes/living_v3/bolhinha/source/pixellab_original.zip`.
- Metadados e PNGs extraídos preservados em `source/`, ignorados pelo importador Godot.
- Runtime: cópias byte a byte em `animations/`, `frames.tres` e `manifest.json` com SHA-256.
- Importador reproduzível: `python tools/import_living_v3_assets.py`.

O original tem oito rotações 64×64, mas os clips têm canvas **76×76** com padding
PixelLab. Mantivemos todas as animações nesse canvas uniforme e com pivô central.
Recortar para 64×64 removeria pixels do jato em `splash` (alcança y=76).
Não houve redimensionamento, recorte, recoloração ou outra edição de PNG.
O corpo ocupa cerca de 44×44 pixels. A integração usa a direção south, compatível
com as animações sem direções do Brotinho; as demais direções continuam no export.

## Revisão visual e mapeamento

Foram vistos os frames south 2, 4 e 7 de cada um dos seis clips antes do mapeamento.
O slime mantém corpo azul translúcido, olhos grandes, sorriso, bochechas e gotículas.

| Runtime | Clip original | Uso |
|---|---|---|
| idle | gentle rhythmic bobbing | Oscilação suave, 5 fps |
| blink | Idle | Pisca e fecha brevemente os olhos; não é sono |
| move | rhythmic vertical bounce | Deslocamento com pequenos pulos |
| happy | rhythmic vertical bounce | Reuso de pulo alegre a 11 fps; expressão nova pendente |
| curious | gentle rhythmic bobbing | Reuso de observação; expressão nova pendente |
| plant | magically watering plants | Interação que emite água, para regar |
| play | rhythmic vertical bounce | Pulo de brincadeira |
| splash | squashes downward to charge energy | Pequeno jato/respingo |
| drink | gently leans forward to submerge mouth | Inclina o corpo para beber |

`sleep` está **ausente** nesta primeira importação: fechar os olhos brevemente em
`blink` não foi rotulado como uma animação de sono. O importador incorpora os clips
autorizados e baixados em `source/supplemental/{happy,curious,sleep}` quando existirem.

Grupos originais: bobbing `019d1be6-5440-4a55-a5ea-7893a6d81128` (8 direções),
bounce `4aaaad6a-8b5f-476e-9998-f832fbcfd934` (5),
watering `53444d31-dc22-4d22-bbac-85d72f5ac821` (4),
splash `88dbf305-30fe-4e46-b55c-20746b6e0bec` (8),
drink `954ad3c4-ddea-4b87-a532-83f1afcefafb` (5),
Idle `e7311937-91d0-4fa0-8228-0249331a4138` (south).
São 31 sequências direcionais; não 31 movimentos diferentes.

## Lote autorizado em 28/10/2026

O usuário autorizou até 50 gerações. Foram submetidas apenas as **16 necessárias**
ao lote abaixo. Cada recibo de submissão informa 1 geração. Três tentativas
recusadas pelo limite de dez jobs simultâneos foram repetidas após liberar vagas;
essas recusas não criaram jobs nem foram cobradas. O estado de cada job, seus
prompts, URLs documentadas e recibos estão em `pixellab_jobs.json`.

Não existem esquilo, pássaro, Musguinho ou Bolhinha adicional apropriados nos
24 personagens e 58 imagens de galeria consultados, nem nas buscas de objetos.
Gelito é a espécie de gelo existente, não o aquático procurado.

| Operação | Gerações |
|---|---:|
| Bolhinha: sono, feliz, curioso (3 clips) | 3 |
| Esquilo: base + andar + procurar comida | 3 |
| Pássaro: base + saltitar + voar | 3 |
| Musguinho: base + idle, move, jump, happy, sleep, plant | 7 |
| Total máximo proposto, sem tentativas adicionais | 16 |

Custos documentados: `create_image_pixen` custa 1 geração por base;
`animate_image` em 64×64 com oito frames gerados custa 1 por clip.
O retorno inclui o frame inicial (nove imagens). As bases usam `no_background=true`.
As animações devem partir da base original 64×64, não do clip exportado com padding.
Não foram usados templates humanoides para estes animais/slimes. Novas tentativas
devem continuar respeitando o teto autorizado, sem gastar a sobra sem necessidade.

Prompts preparados: Musguinho verde-escuro, musgo discreto, forma pequena arredondada,
olhos legíveis e personalidade tímida; esquilo castanho de cauda fofa perto de árvores;
pássaro silvestre pequeno com corpo arredondado e bico legível. Todos high top-down,
pixel art limpa, contorno consistente, canvas transparente, sem sombra de chão.

## Validação executada

Godot 4.7.2 headless importou os PNGs e carregou `frames.tres` sem erros (exit 0).
Verificação de runtime: nove animações presentes, 80 referências a PNGs válidos,
todas as texturas 76×76, pelo menos oito frames por animação e ausência explícita
de `sleep`. Saída: `BOLHINHA_ASSETS_OK`.
O importador também confirmou igualdade de bytes entre fonte e cópia e canvas
uniforme em cada clip. Log do import: `asset_import.log` nesta pasta.

## Complementos autorais gerados em 28/10

Os três clips autorais de Bolhinha substituem os reusos provisórios de `happy` e
`curious` e acrescentam `sleep`. Foi confirmado visualmente que os frames 4–8 de
`sleep` mantêm olhos fechados; somente esses cinco frames formam o loop de sono.
A transição completa permanece na fonte. As fontes novas continuam 64×64; um
`AtlasTexture` com `margin = Rect2(6, 6, 12, 12)` centraliza cada PNG em 76×76,
sem editar pixels, garantindo origem uniforme com as animações anteriores.

Bases de Musguinho, esquilo e pássaro foram conferidas visualmente antes de animar.
Musguinho preserva formato arredondado, olhos legíveis, verde-escuro e pequenos
detalhes de musgo; o esquilo é castanho de cauda fofa; a ave tem asas azuladas,
peito creme e bico pequeno. Os três têm canvas 64×64 e transparência.

Downloads são permitidos somente após `get_image` confirmar `status: completed`.
O utilitário `tools/download_living_v3_assets.py` verifica esse estado no ledger,
usa a URL retornada pelo MCP e preserva PNGs originais em `source/`.

## Resultado final do lote

**16 jobs concluídos e salvos na galeria; 16 gerações consumidas.**
Saldo posterior confirmado por `get_balance`: **4.575,20** gerações, US$ 0,00 em
créditos. Diferença exata de 16 em relação a 4.591,20; nenhuma cobrança adicional
em dólares e nenhum consumo da margem restante de 34 gerações autorizadas.

| Resource | Animações disponíveis | Canvas no Godot |
|---|---|---|
| `assets/slimes/living_v3/bolhinha/frames.tres` | idle, blink, move, happy, curious, sleep, plant, play, splash, drink | 76×76 |
| `assets/slimes/living_v3/musguinho/frames.tres` | idle, move, jump, happy, sleep, plant, play, curious | 64×64 |
| `assets/wildlife/living_v3/squirrel/frames.tres` | idle, walk, forage | 64×64 |
| `assets/wildlife/living_v3/bird/frames.tres` | idle, walk, fly | 64×64 |

Musguinho possui seis clips autorais: `play` reutiliza seu pulo e `curious` reutiliza
a investigação de planta em velocidade menor. `sleep` usa os cinco frames finais
de olhos fechados, visualmente conferidos. Nos animais, `idle` usa a base estática,
enquanto os dois movimentos de cada espécie usam os respectivos clips autorais.
A batida de asas é discreta; o deslocamento pelo mundo é responsabilidade da IA.
Foram conferidos frames 4 e 8 de todos os clips e a sequência completa de voo.

O download preservou 120 PNGs novos: três bases e 117 frames em 13 clips. Os
resources referenciam 191 frames incluindo reaproveitamentos, sem gerar imagens
adicionais para os aliases. Fontes e SHA-256 permanecem por categoria.

Validação final no Godot 4.7.2: `--headless --editor --import --quit`, exit 0;
em seguida, carregamento dos quatro SpriteFrames, verificação de 24 animações,
191 referências, dimensões uniformes por espécie e leitura real de cada textura
por `get_image()`, exit 0. Saída `LIVING_V3_ASSETS_OK`.
Evidências: `asset_import_final.log`, `asset_validation_final.log`.
