extends RefCounted
## Receitas de fabricação (docs/gameplay/CRIACAO.md): só dados, ajustáveis aqui sem
## mexer na lógica (scripts/systems/crafting.gd).
## station: "maos" = sem bancada; "bancada" = só junto à bancada de trabalho.
## requires: itens que precisam estar na bolsa mas não são gastos (ex.: o machado).
## "fogao": só junto ao fogão da casa. cooking: usa valley_cooking.prepare (registro de porções).

const RECIPES := [
	{"id": "corda", "station": "maos", "inputs": {"fibra": 3}, "output": {"corda": 1}},
	{"id": "machado", "station": "maos", "inputs": {"graveto": 2, "pedra_pequena": 2, "corda": 1}, "output": {"machado": 1}},
	{"id": "bancada", "station": "maos", "inputs": {"madeira": 6, "corda": 3, "pedra_pequena": 4}, "output": {"bancada": 1}},
	{"id": "picareta", "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 3, "pedra_pequena": 5, "corda": 2}, "output": {"picareta": 1}},
	{"id": "enxada", "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 3, "pedra_pequena": 2, "corda": 1}, "output": {"enxada": 1}},
	{"id": "porcao_folhas_prototipo", "station": "fogao", "cooking": true, "inputs": {"folhas_frescas": 1}, "output": {"porcao_folhas_prototipo": 1}},
	{"id": "cenoura_assada", "station": "fogao", "inputs": {"cenoura": 2}, "output": {"cenoura_assada": 1}},
	{"id": "sopa_legumes", "station": "fogao", "inputs": {"cenoura": 1, "beterraba": 1, "repolho": 1}, "output": {"sopa_legumes": 1}},
	{"id": "regador", "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 4, "corda": 2}, "output": {"regador": 1}},
]
