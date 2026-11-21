extends RefCounted
## Dinheiro e caixa de venda: colheitas postas na caixa são pagas na virada do dia.

const BAG := preload("res://scripts/systems/forest_bag.gd")
const ITEMS := preload("res://scripts/systems/item_catalog.gd")
const MONEY_KEY := "player_money"
const BIN_KEY := "shipping_bin"
const STARTING_MONEY := 200


static func money(tree: SceneTree) -> int:
	return int(tree.get_meta(MONEY_KEY, STARTING_MONEY))


static func add_money(tree: SceneTree, amount: int) -> void:
	tree.set_meta(MONEY_KEY, money(tree) + amount)


static func spend_money(tree: SceneTree, amount: int) -> bool:
	if amount < 0 or money(tree) < amount:
		return false
	tree.set_meta(MONEY_KEY, money(tree) - amount)
	return true


static func bin(tree: SceneTree) -> Dictionary:
	return tree.get_meta(BIN_KEY, {})


## Valor do que está na caixa (a ser pago amanhã).
static func bin_value(tree: SceneTree) -> int:
	var total := 0
	var items := bin(tree)
	for item in items:
		total += ITEMS.price(item) * int(items[item])
	return total


## Move todas as colheitas vendáveis da bolsa para a caixa; devolve quantas.
static func ship_all(tree: SceneTree) -> int:
	var moved := 0
	var items := bin(tree).duplicate()
	for item in ITEMS.ORDER:
		if ITEMS.kind(item) != "crop" or ITEMS.price(item) <= 0:
			continue
		var amount := BAG.count_item(tree, item)
		if amount > 0 and BAG.spend_item(tree, item, amount):
			items[item] = int(items.get(item, 0)) + amount
			moved += amount
	tree.set_meta(BIN_KEY, items)
	return moved


## Virada do dia: paga a caixa e esvazia. Devolve o valor recebido.
static func pay_out(tree: SceneTree) -> int:
	var total := bin_value(tree)
	add_money(tree, total)
	tree.set_meta(BIN_KEY, {})
	return total
