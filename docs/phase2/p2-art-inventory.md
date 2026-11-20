# Auditoria dos assets existentes antes de qualquer chamada PixelLab

**Fase 2 — `p2-art-inventory`**. Inventário de nomes e manifests existentes em `main` após as PRs #44–#46. **Esta é uma auditoria de arquivos, não uma aprovação visual de cada sprite**; nenhuma geração foi realizada nem há garantia sobre créditos disponíveis na API.

## Slimes disponíveis

| Origem | Slimes | Recursos no projeto |
|---|---|---|
| `assets/slimes/bestiary/` | Brotinho, Brasinha, Gelito | `<id>.png` e `<id>_frames.tres` para cada um |
| `assets/slimes/living_v3/` | Bolhinha, Musguinho | `manifest.json`, `frames.tres`, `animations/`, `source/` |
| Bolhinha (manifest) | Um conjunto de movimentos | `idle` (9 quadros), `blink` (8), `move` (9), `happy` (9), `curious` (9), `plant` (9), `play` (9), `splash` (9), `drink` (9), `sleep` (5) |
| Musguinho | Pastas de animação verificadas | `curious`, `happy`, `idle`, `jump`, `move`, `plant`, `play`, `sleep` |

## Protagonista e mundo

- `assets/player/rotations/`: oito direções PNG: norte, nordeste, leste, sudeste, sul, sudoeste, oeste, noroeste.
- `assets/player/animations/Walk/` e `Running/`: pastas para as oito direções cada. A pasta sul de `Walk` usa o identificador `south-f96d7729`, e deve ser referenciada pelo manifest/loader, não suposta como `south`.
- `assets/world/forest/`: cogumelos marrom/vermelho/brilhante, samambaia, rochas com musgo, carvalhos/pinheiros.
- `assets/world/valley/`: penhascos, bancos de água, rampas, vitórias-régias, juncos, pedras e cachoeiras com arquivos PNG, JSON e/ou recursos `.tres`.
- `assets/world/curated_exports/`: banco, arbustos, cristal, flores, tronco, cogumelos, rochas, ruínas e poste.
- `assets/tilesets/`: tilesets `grass_dirt_v3_32x32.png` e `meadow_forest_refined_32x32.png`.

## Exportações PixelLab a reutilizar

A pasta `assets/objects/pixellab_exports/` possui **553 diretórios de exportação** na consulta ao GitHub. Isso **não** significa 553 objetos únicos: podem existir versões e duplicatas. Exemplo: `campfire_unlit_compact_64x48_292e36a0/` possui PNG, JSON, import e ZIP; há diversos outros diretórios de fogueiras no mesmo padrão.

Antes de pedir qualquer arte nova, primeiro procurar na pasta, comparar versões e verificar os manifests. A estação de culinária introduzida na PR #44 usa atualmente desenho técnico `scripts/world/valley_cooking_station.gd`: há imagens de fogueira já arquivadas, mas **não foi comprovado** que sejam o mesmo utensílio desejado. Não trocar sprites aprovados automaticamente.

## Lacunas atuais e critérios de aceite visual

1. **Ponto de preparo culinário definitivo:** decidir se reutiliza uma das exportações existentes ou se precisa de um novo utensílio; conferir escala no Vale, pivô, fundo transparente e consistência artística. O marcador procedural atual é temporário.
2. **Animação de oferecer porção:** interação F foi implementada na PR #45, mas não foi adicionada animação específica do jogador ou slime. A função trabalha sem regenerar os personagens.
3. **Consistência das referências:** validar visualmente cada sprite importado, folhas e bordas, oito direções quando a mecânica exigir, e animações de `idle`/`move` (arquivo existente não prova qualidade).
4. **PixelLab controlado:** o workflow de exportação atual é GET-only; não disparar POST sem o produtor de jobs com verificação de quota, idempotência por chave, hash, aprovação visual e evidências.

**Resultado:** assets úteis já existem para jogador, cinco slimes e as duas regiões. **Nenhuma necessidade concreta de gerar imagem paga foi comprovada nesta auditoria.** A produção visual segue dependente de revisão e de requisitos específicos do gameplay.
