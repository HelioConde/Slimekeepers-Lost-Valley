# Slime ecosystem 3.0 contract

Scope: forest_slime.gd, forest_habitats.gd, new slime_species.gd, tools/test_slime_ecosystem.gd. Region integration is owned by root. Baseline must finish before production edits or Godot runs.

## Compatibility and integration
- Preserve FRAMES Brotinho constant, existing configure(manager, player, habitat, id), make_friend(), display_name(), move_toward_point(), collision capsule and default Brotinho IDs.
- Habitat configure(region, player, spawn, habitats, options = {}) adds optional world_bounds (Rect2), exclusion_radius (float), max_population (int), session_key (String), protect_initial_view (bool; default true). Existing constants/default behavior remain.
- Each habitat can supply species_slots: ["brotinho", "brotinho", "musguinho"]. Without it, population/default two uses Brotinho as before. IDs use species/habitat/index, keeping the two original Brotinho indices intact.
- Optional spawn_points are actual free-bank points; controller validates physics, exclusion, visibility, spacing and bounds before use. It never forces unsafe fallback spawns.
- Environmental points: flower_points, shade_points, mushroom_points, water_points (arrays of world Vector2 positions). Water points must be accessible BANK/shallow dry collision-free positions, not impassable water centers.
- Shared species dictionary defines curiosity, shyness, energy, sociability, preference, frame path and visual scale. Non-Brotinho species only spawn when their real frame resource exists. No final disguised fallback species.
- Species resources: res://assets/slimes/living_v3/bolhinha/frames.tres and musguinho/frames.tres. Animation aliases idle/move/happy/curious/sleep/plant/play/splash. Missing cosmetic aliases fall back to genuine available idle/happy/move resources.
- Group living_slimes. Habitat manager environmental_state {period: morning/day/evening/night, rain: 0..1} and set_environment_state(Dictionary) to integrate environment without a calendar. Default day.

## Behavior
Priority: brief friendship happiness > bounded retreat from approaching runner > sleep at night/low energy > curious observation (cooldown) > social approach/play (cooldown and same habitat) > preferred environmental visit > short purposeful exploration > rest. Idle intervals between choices and limited action durations prevent constant wandering. Pair interaction targets keep MIN_SEPARATION, share happiness moment, and reject partners already busy. All movement retains real capsule collision and habitat checks. Culling freezes AI and motion at existing 1000 px range while idle remains animated.

## Verification
First run a failing ecosystem test for configurable bounds/slots/personality/environment handling. Then implement and run the new test plus existing tools/test_habitats.gd; parent runs complete validate_forest.ps1 after integration. Assertions cover legacy identities/caps, stable IDs across respawn, species/personality distinctions, actual sleep/wake behavior, player reaction, bounded social pairing/cooldown, session-key friendship restore, genuine frame resource gating, and custom world bounds. Existing physics and culling regression assertions are retained unchanged.

## Implemented and verified (2026-10-28)
- Shared species data, three display names, eight active behavior labels (rest, explore, plants, social, curious, flee, sleep, play) plus splash. Friendship happiness temporarily takes priority.
- Social visits reserve a peer, preserve 50px minimum spacing, share a 2.4s play interval, and start 17–25s cooldowns for both partners. Visits are limited to one habitat.
- Night/low-energy sleep stops motion; daytime wakes a recovered creature. Fast approaching players interrupt leisure on a 0.35s threat check. All motion uses the existing capsule sweep and bounded per-step probes.
- Preferred points create purposeful plant/shade/water visits, with real rest intervals. Distant (>1000px) navigation freezes. Spawn options and species slots retain existing defaults and Brotinho identities.
- A procedural ground-contact ellipse (24px wide at rest, alpha .18) subtly shrinks and fades with a hop. It adds no node, collider, texture, or generated asset.
- `tools/test_slime_ecosystem.gd`: 35 checks / 0 failures with current available art. Includes actual sleep/wake, runner reaction, social synchronization, session restoration, Bolhinha splash at supplied bank point, and two simulated minutes of habitat confinement with motion and pauses.
- `tools/test_habitats.gd`: 37 checks / 0 failures unchanged. GdUnit forest suite: 7 tests / 0 failures/errors/skips/orphans.
- The current Bolhinha resource has NO sleep animation. Test prints ART_PENDING explicitly. Final art completion gate: Godot --headless --path PROJECT --script res://tools/test_slime_ecosystem.gd -- --require-complete-art. This gate must be rerun after the art agent supplies sleep; the implementation gracefully uses available idle in the interim without claiming a completed sleep sprite.
- New species only spawn if their own resource exists. Musguinho actual sprite validation awaits the authorized art batch.
- Full map integration, native visuals and the complete validate_forest.ps1 suite are owned by the parent task and remain separate from these isolated tests.
