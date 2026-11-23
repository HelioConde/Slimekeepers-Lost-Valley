extends RefCounted
## Estações do ano (decisão de 2026-11-23, opção recomendada): 4 estações de 28 dias.
## Cada cultura cresce só nas estações dela (crop_catalog "seasons"); fora delas para de
## crescer, mas não morre. Sem "seasons" = cresce o ano todo (folhas silvestres).

const DAYS := 28
const IDS := ["primavera", "verao", "outono", "inverno"]
const NAMES := {"primavera": "Primavera", "verao": "Verão", "outono": "Outono", "inverno": "Inverno"}


static func of(day: int) -> String:
	return str(IDS[posmod((maxi(day, 1) - 1) / DAYS, IDS.size())])


static func display(day: int) -> String:
	return str(NAMES[of(day)])


## Dia dentro da estação (1..28).
static func day_in(day: int) -> int:
	return posmod(maxi(day, 1) - 1, DAYS) + 1


static func grows(crop: Dictionary, day: int) -> bool:
	var allowed: Array = crop.get("seasons", [])
	return allowed.is_empty() or allowed.has(of(day))
