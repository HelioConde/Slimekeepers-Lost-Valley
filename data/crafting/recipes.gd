extends RefCounted
## Receitas de fabricação (docs/gameplay/CRIACAO.md): só dados, ajustáveis aqui sem
## mexer na lógica (scripts/systems/crafting.gd).
## station: "maos" = sem bancada; "bancada" = só junto à bancada de trabalho.
## requires: itens que precisam estar na bolsa mas não são gastos (ex.: o machado).

const RECIPES := [
	{"id": "corda", "station": "maos", "inputs": {"fibra": 3}, "output": {"corda": 1}},
	{"id": "machado", "station": "maos", "inputs": {"graveto": 2, "pedra_pequena": 2, "corda": 1}, "output": {"machado": 1}},
	{"id": "bancada", "station": "maos", "inputs": {"madeira": 6, "corda": 3, "pedra_pequena": 4}, "output": {"bancada": 1}},
	{"id": "enxada", "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 3, "pedra_pequena": 2, "corda": 1}, "output": {"enxada": 1}},
	{"id": "regador", "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 4, "corda": 2}, "output": {"regador": 1}},
]
