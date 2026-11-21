extends RefCounted
## Céu do Slimekeepers (V10): Sol e Lua calculados só a partir do GameClock (dia +
## minuto). Determinístico — não depende de jogador, câmera ou região — e contínuo
## na virada da meia-noite, porque tudo parte do tempo absoluto.
##
## Modelo simplificado (estilizado para fantasia, com as relações reais):
## - Sol: arco diurno de SUNRISE a SUNSET (coerente com DayShadows e o ciclo de luz);
##   abaixo do horizonte no resto do dia.
## - Lua: mesma forma de arco, atrasada pela fase. A fase p avança 1/29,53 por dia,
##   então o "dia lunar" dura 1440 / (1 - 1/29,53) ≈ 1490 min (24h50): a Lua nasce
##   ~49 min mais tarde a cada dia. Lua nova nasce com o Sol; cheia, ao pôr do sol.
## - Fração iluminada f = (1 - cos 2πp) / 2; oito fases nomeadas.
## - Azimute em tela: +1 = leste (direita, onde o astro nasce), -1 = oeste.

const SUNRISE := 330.0   # 5h30 — opacidade de sombra começa a subir (DayShadows)
const SUNSET := 1170.0   # 19h30 — fim do crepúsculo (AmbientLights.DUSK_END)
const SYNODIC_DAYS := 29.53
## Fase no início do jogo (dia 1, 00h): gibosa crescente, para a primeira noite ter Lua.
const PHASE_AT_START := 0.45
const PHASE_NAMES := ["Lua nova", "Lua crescente fina", "Quarto crescente", "Lua gibosa crescente",
	"Lua cheia", "Lua gibosa minguante", "Quarto minguante", "Lua minguante fina"]


static func absolute_minutes(day: int, minutes: float) -> float:
	return float(maxi(day, 1) - 1) * 1440.0 + minutes


## Arco de um astro dado o seu "horário local" (0..1440): altura -1..1 e azimute.
static func arc(local_minutes: float) -> Dictionary:
	var m := fposmod(local_minutes, 1440.0)
	var day_length := SUNSET - SUNRISE
	var altitude: float
	var azimuth: float
	if m >= SUNRISE and m <= SUNSET:
		var u := (m - SUNRISE) / day_length
		altitude = sin(PI * u)
		azimuth = cos(PI * u)            # +1 ao nascer (leste) → -1 ao pôr (oeste)
	else:
		var u := fposmod(m - SUNSET, 1440.0) / (1440.0 - day_length)
		altitude = -sin(PI * u)
		azimuth = -cos(PI * u)           # volta de oeste para leste por baixo
	return {"altitude": altitude, "azimuth": azimuth}


static func moon_phase(day: int, minutes: float) -> float:
	return fposmod(PHASE_AT_START + absolute_minutes(day, minutes) / (1440.0 * SYNODIC_DAYS), 1.0)


static func phase_index(phase: float) -> int:
	return int(floor(fposmod(phase, 1.0) * 8.0 + 0.5)) % 8


static func illuminated_fraction(phase: float) -> float:
	return (1.0 - cos(TAU * phase)) * 0.5


## Estado completo do céu. Mesmo (dia, minuto) → mesmo resultado, sempre.
static func sky(day: int, minutes: float) -> Dictionary:
	var sun := arc(minutes)
	var phase := moon_phase(day, minutes)
	var moon_local := absolute_minutes(day, minutes) - phase * 1440.0
	var moon := arc(moon_local)
	var fraction := illuminated_fraction(phase)
	var daylight := smoothstep(-0.08, 0.2, float(sun.altitude))
	var moon_up := smoothstep(0.0, 0.25, float(moon.altitude))  # rampa suave no horizonte
	# Luar físico: fase × altura; durante o dia o céu claro o apaga quase todo.
	var moonlight := fraction * moon_up
	var moon_visible := moon_up > 0.0 and fraction > 0.04
	var sun_strength := smoothstep(0.0, 0.1, float(sun.altitude))
	var low_sun := 1.0 - smoothstep(0.15, 0.6, float(sun.altitude))
	var morning := float(sun.azimuth) > 0.0
	var sun_color := Color(1.0, 0.97, 0.82).lerp(Color(1.0, 0.82, 0.45) if morning else Color(1.0, 0.56, 0.28), low_sun)
	return {
		"day": day, "minutes": minutes,
		"sun_altitude": sun.altitude, "sun_azimuth": sun.azimuth, "daylight": daylight,
		"sun_reflection": sun_strength * (0.45 + 0.55 * float(sun.altitude)) * (1.0 if not morning else 0.85),
		"sun_color": sun_color,
		"moon_altitude": moon.altitude, "moon_azimuth": moon.azimuth,
		"moon_phase": phase, "moon_phase_index": phase_index(phase), "moon_phase_name": PHASE_NAMES[phase_index(phase)],
		"moon_fraction": fraction, "moonlight": moonlight, "moon_visible": moon_visible,
		# Reflexo: cheio à noite; de dia só um traço quase imperceptível.
		"moon_reflection": moonlight * lerpf(1.0, 0.08, daylight),
	}


static func now() -> Dictionary:
	var clock: Node = Engine.get_main_loop().root.get_node_or_null("GameClock") if Engine.get_main_loop() is SceneTree else null
	if clock == null: return sky(1, 540.0)
	var data: Dictionary = clock.get_save_data()
	return sky(int(data.day), float(data.minutes))


## Onde o astro se reflete dentro de um corpo d'água (unidades da meia-extensão):
## lado do céu em que está (azimute) e quão perto da margem distante (altura).
## Só depende do céu — nunca do jogador ou da câmera.
static func reflection_offset(altitude: float, azimuth: float) -> Vector2:
	return Vector2(clampf(azimuth, -1.0, 1.0) * 0.5, lerpf(-0.45, 0.25, clampf(altitude, 0.0, 1.0)))
