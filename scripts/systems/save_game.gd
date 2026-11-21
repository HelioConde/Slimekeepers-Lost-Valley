extends RefCounted
## Save em disco: todas as chaves de sessão (SessionState), o relógio e a região
## atual, gravados ao dormir. "Continuar" no menu restaura tudo e abre a região.
## Formato: texto do Godot (var_to_str) — aceita Vector2i nas chaves da fazenda.

const SESSION := preload("res://scripts/systems/session_state.gd")
const VERSION := 1
const DEFAULT_PATH := "user://slimekeepers_save.txt"

## Os testes trocam o caminho para não tocar no save do jogador.
static var path := DEFAULT_PATH


static func has_save() -> bool:
	return FileAccess.file_exists(path)


static func snapshot(tree: SceneTree, clock: Node, region_path: String) -> Dictionary:
	var metas := {}
	for key in SESSION.SESSION_META_KEYS:
		if key != "region_arrival" and tree.has_meta(key):
			metas[key] = tree.get_meta(key)
	return {"version": VERSION, "region": region_path, "clock": clock.get_save_data(), "metas": metas}


static func save(tree: SceneTree, clock: Node, region_path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(var_to_str(snapshot(tree, clock, region_path)))
	file.close()
	return true


## Lê e valida o save; {} se não existir ou estiver corrompido.
static func read() -> Dictionary:
	if not has_save():
		return {}
	var data: Variant = str_to_var(FileAccess.get_file_as_string(path))
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
	return str(data.region)


static func delete() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
