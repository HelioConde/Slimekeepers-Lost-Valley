extends RefCounted
## Save em disco: todas as chaves de sessão (SessionState), o relógio e a região
## atual. Grava ao dormir e todo amanhecer (autosave, relatório de playtest ID 57).
## "Continuar" no menu restaura tudo e abre a região.
## Formato: texto do Godot (var_to_str) — aceita Vector2i nas chaves da fazenda.
##
## Espaços (ID 58): SLOTS partidas independentes, cada uma no seu arquivo. A gravação é
## atômica: escreve em .tmp, guarda o save anterior em .bak e só então troca; a leitura
## usa o .bak se o arquivo principal estiver ruim (ID 57). O save antigo de arquivo
## único é copiado para o espaço 1 sem ser apagado (ID 56).

const SESSION := preload("res://scripts/systems/session_state.gd")
const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const VERSION := 1
const SLOTS := 3
const LEGACY_PATH := "user://slimekeepers_save.txt"
const DEFAULT_PREFIX := "user://slimekeepers_slot_"
## Os testes restauram `path` com isto: vazio = arquivo do espaço atual.
const DEFAULT_PATH := ""

## Os testes trocam o prefixo (ou o caminho) para não tocar nos saves do jogador.
static var prefix := DEFAULT_PREFIX
static var path := DEFAULT_PATH
static var slot := 1


static func slot_path(n: int) -> String:
	return "%s%d.txt" % [prefix, n]


## Arquivo em uso: `path` quando um teste fixou um, senão o do espaço atual.
static func current() -> String:
	return path if not path.is_empty() else slot_path(slot)


static func use_slot(n: int) -> void:
	slot = clampi(n, 1, SLOTS)
	path = ""


static func has_save() -> bool:
	return not _parse(current()).is_empty() or not _parse(current() + ".bak").is_empty()


## Copia o save de arquivo único (versões antigas) para o espaço 1, sem apagar o original.
static func migrate_legacy() -> void:
	if prefix != DEFAULT_PREFIX or not FileAccess.file_exists(LEGACY_PATH): return
	if FileAccess.file_exists(slot_path(1)): return
	DirAccess.copy_absolute(ProjectSettings.globalize_path(LEGACY_PATH), ProjectSettings.globalize_path(slot_path(1)))


## Resumo de um espaço para a tela de escolha ({} = vazio).
static func info(n: int) -> Dictionary:
	var data := _parse(slot_path(n))
	if data.is_empty(): data = _parse(slot_path(n) + ".bak")
	if data.is_empty(): return {}
	var clock: Dictionary = data.clock
	return {"slot": n, "day": int(clock.get("day_number", clock.get("day", 1))),
		"protagonist": str((data.metas as Dictionary).get("protagonist", "")),
		"mode": str(data.get("mode", "solo")), "saved_at": int(data.get("saved_at", 0))}


## Espaço gravado mais recentemente (0 = nenhum).
static func latest_slot() -> int:
	var best := 0
	var when := -1
	for n in range(1, SLOTS + 1):
		var i := info(n)
		if not i.is_empty() and int(i.saved_at) > when:
			best = n
			when = int(i.saved_at)
	return best


static func used_slots() -> Array:
	return range(1, SLOTS + 1).filter(func(n: int) -> bool: return not info(n).is_empty())


static func snapshot(tree: SceneTree, clock: Node, region_path: String) -> Dictionary:
	var metas := {}
	for key in SESSION.SESSION_META_KEYS:
		if key != "region_arrival" and tree.has_meta(key):
			metas[key] = tree.get_meta(key)
	var net := tree.root.get_node_or_null("NetSession")
	var mode := "mp" if net != null and str(net.get("mode")) != "" else "solo"
	# "crafting": save feito com a fabricação (CRIACAO.md); sem ela é save antigo.
	return {"version": VERSION, "region": region_path, "clock": clock.get_save_data(), "metas": metas,
		"crafting": 1, "saved_at": int(Time.get_unix_time_from_system()), "mode": mode}


## Gravação atômica: .tmp completo → save anterior vira .bak → .tmp vira o save.
static func save(tree: SceneTree, clock: Node, region_path: String) -> bool:
	var target := current()
	var tmp := target + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(var_to_str(snapshot(tree, clock, region_path)))
	file.close()
	if _parse(tmp).is_empty():  # não troca um save bom por um arquivo incompleto
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		return false
	var real := ProjectSettings.globalize_path(target)
	if FileAccess.file_exists(target):
		DirAccess.copy_absolute(real, real + ".bak")
		DirAccess.remove_absolute(real)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), real) == OK


## Lê e valida o save; {} se não existir ou estiver corrompido (tenta o .bak).
static func read() -> Dictionary:
	var data := _parse(current())
	return data if not data.is_empty() else _parse(current() + ".bak")


static func _parse(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var data: Variant = str_to_var(FileAccess.get_file_as_string(file_path))
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != VERSION:
		return {}
	if typeof(data.get("metas")) != TYPE_DICTIONARY or typeof(data.get("clock")) != TYPE_DICTIONARY:
		return {}
	if not ResourceLoader.exists(str(data.get("region", ""))):
		return {}
	return data


## Restaura sessão e relógio; devolve a cena a abrir ("" se o save for inválido).
## Nada é alterado se o save for inválido.
static func restore(tree: SceneTree, clock: Node) -> String:
	var data := read()
	if data.is_empty():
		return ""
	var backup: Dictionary = clock.get_save_data()
	if not clock.load_save_data(data.clock):
		clock.load_save_data(backup)
		return ""
	SESSION.clear_session(tree)
	for key in data.metas:
		if key in SESSION.SESSION_META_KEYS:
			tree.set_meta(key, data.metas[key])
	if not data.has("crafting"):  # save antigo: enxada e regador eram de graça
		for tool: String in ITEMS.LEGACY_TOOLS:
			if BAG.count_item(tree, tool) == 0: BAG.add_item(tree, tool)
	return str(data.region)


static func delete() -> void:
	for file_path in [current(), current() + ".bak", current() + ".tmp"]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
