# Environment v3 implementation contract

Status: audit only; production edits held until root finishes baseline benchmark.

Existing API and budgets stay valid: configure(player, flowers, water), configure_leaf_sources, open_area_test, shared_wind_material, set_reduced_motion, debug_snapshot; central simulation 8 Hz and camera buckets. ForestAudio continues existing configure/volume/mute API and bounded synthesis.

## Root integration

- life.get_wind_material(kind: String = "oak") -> ShaderMaterial. Three cached/shared variants oak, pine, plant; default shared_wind_material remains oak. Use pine for texture path containing pine; plant for low flora, oak otherwise. Shader changes texture sampling only, leaving physics and lower trunk fixed.
- life.register_reactor(actor: Node2D): register spawned slimes from _on_forest_slime. Player included automatically. Only nearest seven live local slimes feed bounded plant reaction uniforms alongside player.
- State script scripts/world/environment_state.gd extends RefCounted. Create one per region. state.set_conditions(period: String, rain: float, wind: float, fog: float), state.snapshot() -> Dictionary. Defaults morning, dry, normal wind, clear. life.set_environment_state(state), audio.set_environment_state(state). No clock, calendar, save or automatic storm system.
- life.configure_wildlife(points: Array[Vector2], walkable_test: Callable): tree-foot/clearing anchors. Explicit valid-ground callback prevents animals crossing water/walls. Defaults disabled without supplied anchors and validation.
- life.configure_wildlife_frames(species: String, frames: SpriteFrames): squirrel and bird. Assets optional; unavailable species remains inactive, documented rather than inventing finished art. A shared SpriteFrames per species; per-creature render node at most four, no per-creature processing. Need source asset delivery from asset task.

## Intended changes

- Spatial phases plus species-specific gust response; plant reaction uses bounded nearby reactor positions. No per-flower scripts.
- Butterfly colors/size vary, independent flight/landing/rest timers; player/slime proximity initiates gentle flight with cooldown.
- Leaves follow gust strength and remain capped at eight.
- One occasional subtle cloud shadow, existing one bird shadow unchanged. Shadows cease under reduced motion.
- Wildlife state records rest/forage/hop/flee; camera-local max two squirrels and two birds, culling and valid-ground checks; birds flee out then despawn, squirrels stop safely if ground blocked.
- Audio shares weather intensity, sheltered/open mix and night insect texture; short occasional leaf rustle. Preserve volume/mute and three voice cap by sharing event voice.
- Reduced motion freezes decorative time, wildlife, wind, flying effects. Region teardown owns every node. No new external assets or paid generation.

## Verification

Extend existing life/audio tests (keep prior checks), add environmental state and wildlife contracts. Check exact caps over simulation, fleeing, safe ground, invalid/removed reactors, weather clamping, reduced-motion shader/actors, locality and teardown. Native shader pixel test must continue confirming stable lower trunk and original colors. Root runs integrated suite and comparable gameplay benchmark after changes.
