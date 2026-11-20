extends RefCounted
## Inventario de sessao: SceneTree e a unica fonte de verdade; sem save em disco.
## O adaptador valida transacoes usando collectible_inventory, sem duplicar saldos.
const INVENTORY := preload("res://scripts/systems/collectible_inventory.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const ITEM_ID := "sementes_silvestres"
const LEAVES_ID := "folhas_frescas"
const INVENTORY_KEY := "forest_bag_items"
const PATCHES_KEY := "forest_seed_patches_collected"
const FRIENDS_KEY := "forest_slime_friends"

static func _load_inventory(tree: SceneTree) -> Variant:
	var raw: Variant = tree.get_meta(INVENTORY_KEY, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return null
	var clean: Dictionary = {}
	for item_id: Variant in raw:
		if typeof(item_id) != TYPE_STRING or item_id.strip_edges().is_empty():
			return null
		var quantity: Variant = raw[item_id]
		if typeof(quantity) != TYPE_INT or quantity < 0:
			return null
		if quantity > 0:
			clean[item_id] = quantity
	var inventory = INVENTORY.new()
	if not inventory.deserialize(clean):
		return null
	return inventory

## O meta legado pode conter saldos zero; no snapshot zero vira ausencia.
static func inventory_snapshot(tree: SceneTree) -> Dictionary:
	var inventory = _load_inventory(tree)
	return inventory.serialize() if inventory != null else {}

static func count_item(tree: SceneTree, item_id: String) -> int:
	var inventory = _load_inventory(tree)
	return inventory.count(item_id) if inventory != null else 0

## Transacao unica e validada; falha nunca sobrescreve saldo.
static func spend_item(tree: SceneTree, item_id: String, quantity: int = 1) -> bool:
	var inventory = _load_inventory(tree)
	if inventory == null or not inventory.remove(item_id, quantity):
		return false
	tree.set_meta(INVENTORY_KEY, inventory.serialize())
	return true

static func add_item(tree: SceneTree, item_id: String, quantity: int = 1) -> bool:
	var inventory = _load_inventory(tree)
	if inventory == null or not inventory.add(item_id, quantity):
		return false
	tree.set_meta(INVENTORY_KEY, inventory.serialize())
	return true

## Troca atomica: nenhuma folha desaparece caso o alimento de destino estoure o saldo.
static func exchange_item(tree: SceneTree, consume_id: String, produce_id: String, quantity: int = 1) -> bool:
	if consume_id == produce_id:
		return false
	var inventory = _load_inventory(tree)
	if inventory == null or not inventory.remove(consume_id, quantity):
		return false
	if not inventory.add(produce_id, quantity):
		return false
	tree.set_meta(INVENTORY_KEY, inventory.serialize())
	return true

static func seeds(tree: SceneTree) -> int:
	return count_item(tree, ITEM_ID)

static func leaves(tree: SceneTree) -> int:
	return count_item(tree, LEAVES_ID)

static func spend_seed(tree: SceneTree) -> bool:
	return spend_item(tree, ITEM_ID)

static func add_leaves(tree: SceneTree) -> void:
	add_item(tree, LEAVES_ID)

static func has_brotinho_friend(tree: SceneTree) -> bool:
	var friends: Dictionary = tree.get_meta(FRIENDS_KEY, {})
	for identity in friends:
		if str(identity).begins_with("brotinho/") and bool(friends[identity]):
			return true
	return false

static func is_collected(tree: SceneTree, patch_id: String) -> bool:
	var patches: Dictionary = tree.get_meta(PATCHES_KEY, {})
	return bool(patches.get(patch_id, false))

static func harvest(tree: SceneTree, patch_id: String) -> bool:
	if patch_id.is_empty() or not has_brotinho_friend(tree) or is_collected(tree, patch_id):
		return false
	if not add_item(tree, ITEM_ID):
		return false
	var patches: Dictionary = tree.get_meta(PATCHES_KEY, {}).duplicate()
	patches[patch_id] = true
	tree.set_meta(PATCHES_KEY, patches)
	PROGRESS.mark_event(tree, PROGRESS.SEEDS_COLLECTED)
	return true
