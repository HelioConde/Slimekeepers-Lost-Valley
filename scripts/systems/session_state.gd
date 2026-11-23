extends RefCounted
## Fonte única das chaves de estado de sessão guardadas como metas do SceneTree.
## Viagens entre regiões preservam essas metas; somente o Novo Jogo as limpa.
## tests/forest/test_p2_session_reset.gd falha se um script usar chave fora desta lista.

const SESSION_META_KEYS: PackedStringArray = [
	"clearing_friends",
	"forest_slime_friends",
	"valley_slime_friends",
	"environment_conditions",
	"forest_places",
	"region_arrival",
	"valley_discoveries",
	"forest_bag_items",
	"forest_seed_patches_collected",
	"forage_taken",
	"chopped_trees",
	"placed_stations",
	"protagonist",
	"intro_pending",
	"valley_starter_garden",
	"valley_starter_garden_harvests",
	"farm_cells",
	"farm_starter_seeds_given",
	"hotbar_selected",
	"player_energy",
	"farm_last_day",
	"watering_can_water",
	"slime_affinity",
	"player_house",
	"chest_items",
	"rocks_broken",
	"farm_helpers_done",
	"build_mode",
	"slime_fed_day",
	"valley_cooking_ledger",
	"slime_food_offers",
	"session_progress_flags",
	"tutorial_step",
	"player_health",
	"placed_chest_items",
]


static func clear_session(tree: SceneTree) -> void:
	for key in SESSION_META_KEYS:
		if tree.has_meta(key):
			tree.remove_meta(key)
