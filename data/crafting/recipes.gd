extends RefCounted
## Receitas de fabricação (docs/gameplay/CRIACAO.md): só dados, ajustáveis aqui sem
## mexer na lógica (scripts/systems/crafting.gd).
## station: "maos" = sem bancada; "bancada" = só junto à bancada de trabalho.
## requires: itens que precisam estar na bolsa mas não são gastos (ex.: o machado).
## "fogao": só junto ao fogão da casa. cooking: usa valley_cooking.prepare (registro de porções).
## Ferramentas (machado, picareta, enxada, regador...) só na bancada; comida só no fogão;
## a bancada é feita sem madeira (gravetos, pedras e corda) — decisões de 2026-11-23.
## category/tier: aba e linha do menu de fabricação (estilo Palworld; nível só organiza,
## não trava nada por enquanto).

const RECIPES := [
	{"id": "corda", "category": "producao", "tier": 1, "station": "maos", "inputs": {"fibra": 3}, "output": {"corda": 1}},
	{"id": "machado", "category": "ferramentas", "tier": 1, "station": "bancada", "inputs": {"graveto": 2, "pedra_pequena": 2, "corda": 1}, "output": {"machado": 1}},
	{"id": "bancada", "category": "producao", "tier": 1, "station": "maos", "inputs": {"graveto": 6, "pedra_pequena": 4, "corda": 2}, "output": {"bancada": 1}},
	{"id": "bau_campo", "category": "armazenamento", "tier": 2, "station": "bancada", "inputs": {"madeira": 8, "corda": 2}, "output": {"bau_campo": 1}},
	{"id": "picareta", "category": "ferramentas", "tier": 2, "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 3, "pedra_pequena": 5, "corda": 2}, "output": {"picareta": 1}},
	{"id": "foice", "category": "ferramentas", "tier": 2, "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 2, "pedra_pequena": 3, "corda": 1}, "output": {"foice": 1}},
	{"id": "enxada", "category": "ferramentas", "tier": 2, "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 3, "pedra_pequena": 2, "corda": 1}, "output": {"enxada": 1}},
	{"id": "porcao_folhas_prototipo", "category": "comida", "tier": 1, "station": "fogao", "cooking": true, "inputs": {"folhas_frescas": 1}, "output": {"porcao_folhas_prototipo": 1}},
	{"id": "cenoura_assada", "category": "comida", "tier": 1, "station": "fogao", "inputs": {"cenoura": 2}, "output": {"cenoura_assada": 1}},
	{"id": "sopa_legumes", "category": "comida", "tier": 2, "station": "fogao", "inputs": {"cenoura": 1, "beterraba": 1, "repolho": 1}, "output": {"sopa_legumes": 1}},
	{"id": "regador", "category": "ferramentas", "tier": 2, "station": "bancada", "requires": ["machado"], "inputs": {"madeira": 4, "corda": 2}, "output": {"regador": 1}},
]
