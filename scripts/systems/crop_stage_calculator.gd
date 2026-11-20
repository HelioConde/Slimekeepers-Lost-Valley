extends RefCounted
## Calcula a fase de um cultivo já plantado, sem consultar o relógio ou a cena.
## Os instantes usam a mesma origem: (dia - 1) * 1440 + minutos do dia.


## remaining_minutes é o tempo até a maturação, sem arredondamento para exibição.
## Uma consulta anterior ao plantio ou com duração não positiva é inválida.
static func calculate(planted_at: float, now: float, duration_minutes: float) -> Dictionary:
	if not is_finite(planted_at) or not is_finite(now) or not is_finite(duration_minutes):
		return {"phase": "invalid", "remaining_minutes": 0.0}
	if planted_at < 0.0 or now < planted_at or duration_minutes <= 0.0:
		return {"phase": "invalid", "remaining_minutes": 0.0}

	var elapsed := now - planted_at
	if elapsed >= duration_minutes:
		return {"phase": "ready", "remaining_minutes": 0.0}
	return {"phase": "growing", "remaining_minutes": duration_minutes - elapsed}
