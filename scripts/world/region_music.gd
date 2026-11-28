extends Node
## Música da região (2026-11-23, PixelLab create_music + make_music_loop; aprovação do
## usuário antes de entrar no jogo). Toca a faixa `TRACKS[track]` se o arquivo existir:
## a introdução uma vez e depois repete de loop_start a loop_end sem emenda (os pontos
## vêm do get_music da versão em loop). Sem arquivo, não faz nada.
## Volume: controle próprio da música (presentation.cfg, audio/music_volume; playtest ID 15),
## que começa igual ao do ambiente para quem ainda não mexeu, vezes GAIN. "Silenciar" cala tudo.

const TRACKS := {
	"floresta_dia": {"path": "res://assets/audio/music/floresta_dia.mp3", "loop_start": 63.181, "loop_end": 167.221},  # versão 1, aprovada
}
const GAIN := 0.45
const FADE_IN := 4.0

var track := "floresta_dia"
var _player: AudioStreamPlayer
var _loop_start := 0.0
var _loop_end := 0.0
var _target_db := -80.0
var _stream: AudioStream
var _fade: Tween


## Posição depois de `pos`: ao passar do fim do trecho, volta ao começo dele.
static func wrap(pos: float, loop_start: float, loop_end: float) -> float:
	if loop_end <= loop_start or pos < loop_end: return pos
	return loop_start + (pos - loop_end)


func _ready() -> void:
	var info: Dictionary = TRACKS.get(track, {})
	if info.is_empty() or not ResourceLoader.exists(str(info.path)): return
	_stream = load(str(info.path)) as AudioStream
	if _stream is AudioStreamMP3: (_stream as AudioStreamMP3).loop = true  # sem pontos: repete inteira
	_loop_start = float(info.loop_start)
	_loop_end = float(info.loop_end)
	apply_settings()


## Lê volume/mudo das opções e aplica na hora (o menu do Esc chama isto ao mudar).
## Mudo ou volume 0: sem faixa não cria o player; com ele tocando, só silencia.
func apply_settings() -> void:
	if _stream == null: return
	var prefs := ConfigFile.new()
	var volume := 0.65
	var muted := false
	if prefs.load("user://presentation.cfg") == OK:
		volume = clampf(float(prefs.get_value("audio", "music_volume", prefs.get_value("audio", "ambient_volume", 0.65))), 0.0, 1.0)
		muted = bool(prefs.get_value("audio", "muted", false))
	if is_instance_valid(_fade): _fade.kill()
	if muted or volume <= 0.0:
		if is_instance_valid(_player): _player.volume_db = -80.0
		return
	_target_db = linear_to_db(volume * GAIN)
	if is_instance_valid(_player):
		_player.volume_db = _target_db
		return
	_player = AudioStreamPlayer.new()
	_player.name = "Music"
	_player.stream = _stream
	_player.volume_db = -40.0
	add_child(_player)
	_player.play()
	if get_tree().paused:  # ligada no menu do Esc: a pausa congelaria o fade em -40 dB
		_player.volume_db = _target_db
		return
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", _target_db, FADE_IN)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not _player.playing or _loop_end <= 0.0: return
	var pos := _player.get_playback_position()
	if pos >= _loop_end: _player.seek(wrap(pos, _loop_start, _loop_end))
