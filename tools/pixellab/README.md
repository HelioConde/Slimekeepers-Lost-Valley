# Download de todos os objetos PixelLab — Slimekeepers: Lost Valley

Exporta os objetos **existentes** pela API v2, sem criar imagens nem gastar gerações de criação. Usa `/objects` (paginação de até 100 por página) e `/objects/{id}/spritesheet` (ZIP com PNG + JSON). O script faz várias páginas e exporta cada objeto, mesmo que haja centenas.

## Windows / PowerShell

1. Com o repositório atualizado, abra o PowerShell na pasta do projeto.
2. Execute:

```powershell
cd "C:\Slimekeepers Lost Valley"
$env:PIXELLAB_API_TOKEN="COLE_SEU_TOKEN"
python .\tools\pixellab\baixar_todos_objetos.py --dry-run
python .\tools\pixellab\baixar_todos_objetos.py
```

### Comandos opcionais

```powershell
# Filtrar pelo prompt, nome ou tags dos objetos do seu jogo
python .\tools\pixellab\baixar_todos_objetos.py --contains "Slimekeepers"

# Testar com somente dez objetos
python .\tools\pixellab\baixar_todos_objetos.py --max-items 10

# Reduzir concorrência
python .\tools\pixellab\baixar_todos_objetos.py --workers 1
```

## Resultado

Uma pasta por objeto em `sprites/objects/pixellab_exports/`, com `spritesheet.zip`, PNG e JSON extraídos; além de `manifest.json` com resultados da execução. Nomes incluem parte do UUID para não colidirem. Se rodar novamente, não baixa de novo um ZIP já válido.

**Cuidados:** Não publique sua chave da API; não grave a chave em arquivo do repositório. A API retorna spritesheet e layout JSON; isso pode diferir da estrutura de quadros individuais dos downloads da interface. O script não modifica `sprites/objects` atual e não faz push para o GitHub.

Documentação oficial: https://api.pixellab.ai/v2/docs
