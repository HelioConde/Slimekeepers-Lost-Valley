extends Node
## Multijogador P2P (decisão do usuário, 2026-11-23: pela Steam). Autoload "NetSession".
## Dois jogadores (Aren e Moni). Playtest ID 17: o anfitrião abre a sala ao entrar na
## tela de escolha; quem entra vai para a mesma tela, cada um escolhe um protagonista
## diferente, fica pronto e o anfitrião começa quando os dois estão prontos ("lobby",
## "lobby_start"). Quem entra com a partida já em andamento fica com o outro
## protagonista e cai direto no mapa. Mesmo protocolo em dois transportes:
## - "steam": lobby de amigos + Steam Networking Messages (GodotSteam, addons/godotsteam);
## - "enet": rede local (IP/porta) para testes sem a Steam e jogos na mesma rede.
## Mensagens: Dictionary serializado com var_to_bytes (sem objetos).

signal status_changed(text: String)
signal peer_joined(protagonist: String)
signal peer_left()
signal message(data: Dictionary)

const PROTAGONIST := preload("res://scripts/systems/protagonist.gd")
const TUTORIAL_KEY := "tutorial_step"  # scripts/ui/tutorial_hud.gd KEY
const SELECT := "res://scenes/protagonist_select.tscn"
const STEAM_APP_ID := 480  # Spacewar (teste da Valve) até o jogo ter App ID próprio
const ENET_PORT := 24680
const CHANNEL := 0
const SEND_RELIABLE := 8  # k_nSteamNetworkingSend_Reliable

var mode := ""  # "", "host", "guest"
var transport := ""  # "steam" ou "enet"
var connected := false
## Protagonista de cada lado (o convidado recebe o que o anfitrião não escolheu).
var local_protagonist := ""
var remote_protagonist := ""
var status := ""
## Sala na tela de escolha (antes de começar): escolha atual de cada lado em
## local/remote_protagonist ("" = ainda não escolheu) e quem está pronto.
var in_lobby := false
var local_ready := false
var remote_ready := false
## Aviso para o menu principal mostrar ao voltar (ex.: a sala fechou).
var menu_notice := ""

var _steam: Object = null
var _steam_ready := false
var lobby_id := 0
var _remote_steam_id := 0
var _enet: ENetMultiplayerPeer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_packet.connect(_on_enet_packet)
	multiplayer.peer_connected.connect(_on_enet_peer_connected)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void: _on_peer_gone())
	# Aberto pelo convite da Steam com o jogo fechado: "+connect_lobby <id>".
	var args := OS.get_cmdline_args()
	var at := args.find("+connect_lobby")
	if at >= 0 and at + 1 < args.size() and args[at + 1].is_valid_int():
		join_steam.call_deferred(int(args[at + 1]))


func is_active() -> bool:
	return not mode.is_empty()


## O outro protagonista (quem entra joga com o que o anfitrião não escolheu).
static func other_of(id: String) -> String:
	return "moni" if id == "aren" else "aren"


# --- Steam -----------------------------------------------------------------

## Liga a Steam (precisa do cliente Steam aberto). Devolve "" ou o motivo.
func steam_init() -> String:
	if _steam_ready: return ""
	if not Engine.has_singleton("Steam"):
		return "GodotSteam não está instalado."
	_steam = Engine.get_singleton("Steam")
	var result: Dictionary = _steam.call("steamInitEx", STEAM_APP_ID, true)
	if int(result.get("status", 1)) != 0:
		return "Steam não iniciou: %s" % str(result.get("verbal", "abra o cliente Steam"))
	_steam_ready = true
	_steam.connect("lobby_created", _on_lobby_created)
	_steam.connect("lobby_joined", _on_lobby_joined)
	_steam.connect("join_requested", func(lobby: int, _friend: int) -> void: join_steam(lobby))
	_steam.connect("lobby_chat_update", _on_lobby_chat_update)
	_steam.connect("network_messages_session_request", func(remote: int) -> void:
		if remote == _remote_steam_id or mode == "host": _steam.call("acceptSessionWithUser", remote))
	return ""


## Anfitrião pela Steam: cria um lobby só de amigos (2 vagas) e abre o convite.
func host_steam(protagonist: String) -> String:
	var problem := steam_init()
	if not problem.is_empty(): return problem
	_end_previous()
	_begin("host", "steam", protagonist)
	_steam.call("createLobby", 1, 2)  # 1 = LOBBY_TYPE_FRIENDS_ONLY
	_set_status("Criando sala na Steam...")
	return ""


func join_steam(lobby: int) -> String:
	var problem := steam_init()
	if not problem.is_empty(): return problem
	_end_previous()
	_begin("guest", "steam", "")
	_steam.call("joinLobby", lobby)
	_set_status("Entrando na sala do amigo...")
	return ""


## Abre o convite de amigos da Steam para o lobby atual.
func invite_friends() -> void:
	if _steam_ready and lobby_id != 0: _steam.call("activateGameOverlayInviteDialog", lobby_id)


func _on_lobby_created(result: int, lobby: int) -> void:
	if result != 1:
		_set_status("Não foi possível criar a sala (%d)." % result)
		return
	lobby_id = lobby
	_steam.call("setLobbyData", lobby, "game", "slimekeepers")
	_steam.call("setLobbyData", lobby, "host_protagonist", local_protagonist)
	_set_status("Sala criada (ID %d). Convide um amigo pela Steam ou passe o ID." % lobby)
	invite_friends()


func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		_set_status("Não foi possível entrar na sala (%d)." % response)
		return
	lobby_id = lobby
	var owner: int = _steam.call("getLobbyOwner", lobby)
	var me: int = _steam.call("getSteamID")
	if mode == "guest" and owner != me:
		_remote_steam_id = owner
		send({"t": "hello"})  # o anfitrião responde com "welcome" (protagonista e mundo)
		_set_status("Conectando ao anfitrião...")


func _on_lobby_chat_update(lobby: int, changed: int, _making: int, chat_state: int) -> void:
	if lobby != lobby_id: return
	if chat_state == 1 and mode == "host":  # entrou
		_remote_steam_id = changed
		_steam.call("acceptSessionWithUser", changed)
	elif chat_state in [2, 4, 8, 16] and changed == _remote_steam_id:  # saiu / caiu
		_on_peer_gone()


# --- ENet (rede local / testes) --------------------------------------------

func host_enet(protagonist: String, port: int = ENET_PORT) -> String:
	_end_previous()
	_enet = ENetMultiplayerPeer.new()
	var err := _enet.create_server(port, 1)
	if err != OK: return "Não foi possível abrir a porta %d." % port
	multiplayer.multiplayer_peer = _enet
	_begin("host", "enet", protagonist)
	_set_status("Aguardando o outro jogador na porta %d..." % port)
	return ""


func join_enet(address: String, port: int = ENET_PORT) -> String:
	_end_previous()
	_enet = ENetMultiplayerPeer.new()
	var err := _enet.create_client(address, port)
	if err != OK: return "Não foi possível conectar a %s:%d." % [address, port]
	multiplayer.multiplayer_peer = _enet
	_begin("guest", "enet", "")
	_set_status("Conectando a %s..." % address)
	return ""


## Tempo limite do ENet maior que o padrão (~5 s sem resposta): carregar o mapa ou
## avançar o relógio trava o jogo alguns segundos e a conexão caía (teste com dois jogos).
const ENET_TIMEOUT_MS := [32, 20000, 60000]  # limite, mínimo, máximo


func _on_enet_peer_connected(id: int) -> void:
	var peer := _enet.get_peer(id) if is_instance_valid(_enet) else null
	if peer: peer.set_timeout(ENET_TIMEOUT_MS[0], ENET_TIMEOUT_MS[1], ENET_TIMEOUT_MS[2])
	if mode == "guest": send({"t": "hello"})


func _on_enet_packet(_id: int, bytes: PackedByteArray) -> void:
	_receive(bytes)


# --- Protocolo comum ---------------------------------------------------------

func _begin(new_mode: String, new_transport: String, protagonist: String) -> void:
	mode = new_mode
	transport = new_transport
	connected = false
	local_protagonist = protagonist
	remote_protagonist = ""
	in_lobby = false
	local_ready = false
	remote_ready = false


## Sala: avisa o outro da escolha e da prontidão deste lado.
func lobby_update(pick: String, is_ready: bool) -> void:
	local_protagonist = pick
	local_ready = is_ready and not pick.is_empty()
	send({"t": "lobby", "pick": pick, "ready": local_ready})


## A sala vira partida; o aviso que aparece ao chegar no mapa diz quem joga com quem.
func lobby_begin() -> void:
	in_lobby = false
	if PROTAGONIST.ALL.has(local_protagonist):
		_set_status("Partida em dupla: você joga com %s." % PROTAGONIST.ALL[local_protagonist].name)


## Anfitrião: os dois conectados, prontos e com protagonistas diferentes.
func lobby_can_start() -> bool:
	return mode == "host" and connected and in_lobby and local_ready and remote_ready \
		and PROTAGONIST.ALL.has(local_protagonist) and PROTAGONIST.ALL.has(remote_protagonist) \
		and local_protagonist != remote_protagonist


func send(data: Dictionary) -> void:
	var bytes := var_to_bytes(data)
	if transport == "enet" and is_instance_valid(_enet) and _enet.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.send_bytes(bytes, 0, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
	elif transport == "steam" and _steam_ready and _remote_steam_id != 0:
		_steam.call("sendMessageToUser", _remote_steam_id, bytes, SEND_RELIABLE, CHANNEL)


func _receive(bytes: PackedByteArray) -> void:
	var data: Variant = bytes_to_var(bytes)  # sem objetos: bytes_to_var não instancia nada
	if typeof(data) != TYPE_DICTIONARY: return
	if OS.has_environment("SK_NET_DEBUG") and str(data.get("t", "")) != "state": print("NETMSG ", mode, " ", data.get("t"), " ", str(data.get("key", "")))
	match str(data.get("t", "")):
		"hello":
			if mode != "host": return
			connected = true
			if in_lobby:  # ainda na tela de escolha: o convidado vai para ela e escolhe
				remote_protagonist = ""
				remote_ready = false
				send({"t": "welcome", "lobby": true, "host": local_protagonist, "ready": local_ready})
				_set_status("Jogador 2 entrou na sala.")
				peer_joined.emit("")
				return
			remote_protagonist = other_of(local_protagonist)
			var here: String = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
			send({"t": "welcome", "you": remote_protagonist, "host": local_protagonist, "scene": here,
				"day": GameClock.day_number, "hour": GameClock.get_hour(), "minute": GameClock.get_minute(),
				"bag": guest_bag(get_tree(), remote_protagonist)})
			_set_status("%s entrou no jogo." % PROTAGONIST.ALL[remote_protagonist].name)
			peer_joined.emit(remote_protagonist)
		"welcome":
			if mode != "guest": return
			connected = true
			if bool(data.get("lobby", false)):
				in_lobby = true
				local_protagonist = ""
				local_ready = false
				remote_protagonist = str(data.get("host", ""))
				remote_ready = bool(data.get("ready", false))
				_set_status("Conectado! Escolha seu protagonista.")
				peer_joined.emit(remote_protagonist)
				message.emit(data)
				if auto_enter: get_tree().change_scene_to_file(SELECT)
				return
			local_protagonist = str(data.get("you", "moni"))
			remote_protagonist = str(data.get("host", "aren"))
			_set_status("Conectado! Você joga com %s." % PROTAGONIST.ALL[local_protagonist].name)
			peer_joined.emit(remote_protagonist)
			message.emit(data)
			if auto_enter: _enter_host_world(data)
		"lobby":
			if not in_lobby: return
			remote_protagonist = str(data.get("pick", ""))
			remote_ready = bool(data.get("ready", false))
			# Os dois pegaram o mesmo ao mesmo tempo: fica com o anfitrião (Jogador 1).
			if mode == "guest" and not remote_protagonist.is_empty() and remote_protagonist == local_protagonist:
				lobby_update("", false)
			message.emit(data)
		"guest_bag":  # Continuar em dupla: a bolsa do convidado fica no save do anfitrião
			if mode == "host" and not remote_protagonist.is_empty():
				store_guest_bag(get_tree(), remote_protagonist, data.get("bag", {}))
		"bye":
			_on_peer_gone()
		_:
			message.emit(data)


## Quem entra começa uma sessão nova com o outro protagonista, no horário do
## anfitrião, direto no mapa dele (sem a introdução do despertar).
var auto_enter := true
## Anfitrião: transporte escolhido no menu ("steam" ou "enet"); a sala abre quando o
## protagonista é confirmado na tela de escolha.
var pending_host := ""
var pending_port := ENET_PORT  ## porta da sala na rede local (os testes usam outra)


func _enter_host_world(data: Dictionary) -> void:
	var tree := get_tree()
	GameClock.reset_new_game()
	preload("res://scripts/systems/session_state.gd").clear_session(tree)
	PROTAGONIST.choose(tree, local_protagonist)
	start_guest_tutorial(tree)
	apply_bag(tree, data.get("bag", {}))  # volta com a bolsa da última vez nesse save
	GameClock.set_time(int(data.get("hour", 7)), int(data.get("minute", 0)))
	var scene := str(data.get("scene", "res://scenes/regions/FlorestaDoDespertarV2.tscn"))
	if not scene.begins_with("res://scenes/regions/"): scene = "res://scenes/regions/FlorestaDoDespertarV2.tscn"
	tree.root.content_scale_size = Vector2i(960, 540)
	tree.change_scene_to_file(scene)


## Playtest ID 18: o convidado não passa pelo despertar (que liga o tutorial no fim);
## o tutorial dele começa ao chegar, com o passo só deste jogo (não sincronizado).
static func start_guest_tutorial(tree: SceneTree) -> void:
	PROTAGONIST.finish_intro(tree)
	tree.set_meta(TUTORIAL_KEY, 0)


## Abre a sala pendente (chamado pela tela de escolha ao abrir): a sala fica na tela
## de escolha até os dois estarem prontos.
func open_pending_host(protagonist: String = "") -> String:
	var kind := pending_host
	pending_host = ""
	var problem := "Escolha Steam ou rede local no menu."
	if kind == "steam": problem = host_steam(protagonist)
	elif kind == "enet": problem = host_enet(protagonist, pending_port)
	in_lobby = problem.is_empty()
	return problem


# --- Continuar em dupla (pedido do usuário, 2026-11-27) -------------------------
## O anfitrião abre um save já em andamento (Continuar partida ou "Abrir para amigo" no
## Esc): a sala abre sem a tela de escolha e o amigo entra com o outro protagonista.
## A bolsa do amigo fica no save do anfitrião (GUEST_BAGS_KEY) e volta quando ele entra.
const GUEST_BAGS_KEY := "mp_guest_bags"
const BAG_KEYS := ["forest_bag_items", "bag_layout", "tool_wear", "hotbar_selected"]
## Confere a bolsa a cada segundo e manda só quando mudou: fechar a conexão descarta o
## que ainda está na fila, então a última mudança não pode esperar o "tchau".
const BAG_SYNC_SECONDS := 1.0
var _bag_timer := 0.0
var _bag_sent := ""


## Abre a sala com o jogo já carregado. "" = abriu; senão o motivo.
func open_in_world(kind: String, protagonist: String) -> String:
	var problem := host_steam(protagonist) if kind == "steam" else host_enet(protagonist, pending_port)
	in_lobby = false
	return problem


## Sala pedida no menu (Continuar partida): a região chama ao carregar o save.
func open_pending_in_world(protagonist: String) -> String:
	if pending_host.is_empty(): return ""
	var kind := pending_host
	pending_host = ""
	return open_in_world(kind, protagonist)


static func bag_snapshot(tree: SceneTree) -> Dictionary:
	var out := {}
	for key: String in BAG_KEYS:
		if tree.has_meta(key): out[key] = tree.get_meta(key)
	return out


static func apply_bag(tree: SceneTree, bag: Variant) -> void:
	if typeof(bag) != TYPE_DICTIONARY: return
	for key: String in BAG_KEYS:
		if (bag as Dictionary).has(key): tree.set_meta(key, bag[key])


static func guest_bag(tree: SceneTree, protagonist: String) -> Dictionary:
	return (tree.get_meta(GUEST_BAGS_KEY, {}) as Dictionary).get(protagonist, {})


static func store_guest_bag(tree: SceneTree, protagonist: String, bag: Variant) -> void:
	if typeof(bag) != TYPE_DICTIONARY: return
	var bags: Dictionary = (tree.get_meta(GUEST_BAGS_KEY, {}) as Dictionary).duplicate(true)
	bags[protagonist] = (bag as Dictionary).duplicate(true)
	tree.set_meta(GUEST_BAGS_KEY, bags)


## Convidado em jogo manda a bolsa de tempos em tempos (e ao sair, em leave()).
func _sync_guest_bag(delta: float) -> void:
	if mode != "guest" or not connected or in_lobby: return
	_bag_timer -= delta
	if _bag_timer > 0.0: return
	_bag_timer = BAG_SYNC_SECONDS
	var bag := bag_snapshot(get_tree())
	var stamp := var_to_str(bag)
	if stamp == _bag_sent: return
	_bag_sent = stamp
	send({"t": "guest_bag", "bag": bag})


func _on_peer_gone() -> void:
	if OS.has_environment("SK_NET_DEBUG"): print("NETGONE ", mode, " t=", Time.get_ticks_msec())
	if not connected and mode == "": return
	connected = false
	if in_lobby:  # a vaga da sala fica livre para entrar de novo
		remote_protagonist = ""
		remote_ready = false
	_set_status("O outro jogador saiu.")
	peer_left.emit()


## Playtest ID 12: hospedar/entrar de novo (ou trocar Steam <-> rede local) fecha a
## sessão anterior antes; senão a porta ficava ocupada e a sala antiga aberta.
func _end_previous() -> void:
	if mode != "" or is_instance_valid(_enet): leave()


func leave() -> void:
	if connected and mode == "guest" and not in_lobby: send({"t": "guest_bag", "bag": bag_snapshot(get_tree())})
	if connected: send({"t": "bye"})
	if transport == "steam" and _steam_ready and lobby_id != 0:
		if _remote_steam_id != 0: _steam.call("closeSessionWithUser", _remote_steam_id)
		_steam.call("leaveLobby", lobby_id)
	if is_instance_valid(_enet):
		multiplayer.poll()  # a bolsa e o tchau saem antes de fechar
		if _enet.host: _enet.host.flush()
		_enet.close()
		multiplayer.multiplayer_peer = null
	mode = ""
	transport = ""
	connected = false
	in_lobby = false
	local_ready = false
	remote_ready = false
	lobby_id = 0
	_remote_steam_id = 0


func _set_status(text: String) -> void:
	status = text
	status_changed.emit(text)


func _process(_delta: float) -> void:
	_sync_guest_bag(_delta)
	if not _steam_ready: return
	_steam.call("run_callbacks")
	if transport != "steam": return
	var messages: Array = _steam.call("receiveMessagesOnChannel", CHANNEL, 32)
	for m in messages:
		if typeof(m) != TYPE_DICTIONARY: continue
		var sender := int(m.get("remote_steam_id", m.get("identity", 0)))
		if mode == "host" and _remote_steam_id == 0: _remote_steam_id = sender
		if sender != _remote_steam_id and _remote_steam_id != 0: continue  # só o par da sala
		_receive(m.get("payload", PackedByteArray()))
