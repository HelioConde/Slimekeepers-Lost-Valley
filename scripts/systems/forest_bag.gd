extends RefCounted
## Inventario de sessao: SceneTree e a unica fonte de verdade; sem save em disco.
## O adaptador valida transacoes usando collectible_inventory, sem duplicar saldos.
const INVENTORY := preload("res://scripts/systems/collectible_inventory.gd")
const PROGRESS := preload("res://scripts/systems/session_progress_session.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const ITEM_ID := "sementes_silvestres"
const LEAVES_ID := "folhas_frescas"
const INVENTORY_KEY := "forest_bag_items"
const PATCHES_KEY := "forest_seed_patches_collected"
const FRIENDS_KEY := "forest_slime_friends"
## Mochila com 10 espaços (pedido do usuário, 2026-11-22): cada item diferente
## ocupa um espaço (pilha até max_stack), ferramentas inclusive.
const SLOTS := 10

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

## Cabe `quantity` de `item_id`? Pilha até max_stack; item novo precisa de espaço livre.
static func can_add(tree: SceneTree, item_id: String, quantity: int = 1) -> bool:
	return _fits(inventory_snapshot(tree), item_id, quantity)


static func _fits(items: Dictionary, item_id: String, quantity: int) -> bool:
	var have := int(items.get(item_id, 0))
	if have + quantity > ITEMS.max_stack(item_id):
		return false
	return have > 0 or items.size() < SLOTS


## Espaços ocupados (itens diferentes na mochila).
static func used_slots(tree: SceneTree) -> int:
	return inventory_snapshot(tree).size()


## Respeita a pilha (item_catalog.max_stack) e os 10 espaços: cheio = false, nada muda.
static func add_item(tree: SceneTree, item_id: String, quantity: int = 1) -> bool:
	var inventory = _load_inventory(tree)
	if inventory != null and not _fits(inventory.serialize(), item_id, quantity):
		return false
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
	if not _fits(inventory.serialize(), produce_id, quantity) or not inventory.add(produce_id, quantity):
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
