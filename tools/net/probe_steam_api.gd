extends SceneTree
## Lista a API do GodotSteam usada pelo multijogador (nomes e argumentos reais).
func _initialize() -> void:
	print("class Steam: ", ClassDB.class_exists("Steam"), " singleton: ", Engine.has_singleton("Steam"))
	if not ClassDB.class_exists("Steam"):
		quit(); return
	for m in ClassDB.class_get_method_list("Steam", true):
		var n: String = m.name
		if n in ["steamInitEx", "steamInit", "run_callbacks", "createLobby", "joinLobby", "leaveLobby", "getLobbyOwner", "getNumLobbyMembers", "getLobbyMemberByIndex", "activateGameOverlayInviteDialog", "sendMessageToUser", "receiveMessagesOnChannel", "acceptSessionWithUser", "closeSessionWithUser", "getSteamID", "getPersonaName", "getFriendPersonaName", "setLobbyData", "getLobbyData", "isSteamRunning"]:
			var args := []
			for a in m.args: args.append("%s:%s" % [a.name, type_string(a.type)])
			print(n, "(", ", ".join(args), ")")
	for s in ClassDB.class_get_signal_list("Steam", true):
		if s.name in ["lobby_created", "lobby_joined", "join_requested", "lobby_chat_update", "network_messages_session_request", "network_messages_session_failed", "persona_state_change"]:
			var args := []
			for a in s.args: args.append(a.name)
			print("signal ", s.name, "(", ", ".join(args), ")")
	quit()
