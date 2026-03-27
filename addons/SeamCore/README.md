# SeamCore Level Persistence (Godot 4.6)

This plugin implements a Half-Life 2 style save model:

- Base scene data stays in `.tscn`
- Runtime changes are captured as level deltas
- Re-entering a level reapplies those deltas
- Entities can be carried through transitions and re-injected

## Core scripts

- `core/world_state.gd` (autoload): Stores all level deltas and transfer payloads.
- `core/saveable.gd`: Base type for persistent entities.
- `core/level_transition.gd`: Saves/loads current level state and handles entity transfer.
- `core/nodes/transition_marker.gd`: Marker node used to place incoming transferred entities.

## Saveable contract

A node is treated as persistent when it:

- Is in group `seam_saveable`
- Exposes `unique_id` and `save_enabled`
- Implements:
  - `save_state() -> Dictionary`
  - `load_state(data: Dictionary) -> void`
  - `get_save_scene_path() -> String`

`SeamSaveable` already provides these and can be used as a base class.

## Included templates

- `core/saveables/physics_prop_saveable.gd`
- `core/saveables/npc_saveable.gd`
- `core/saveables/trigger_saveable.gd`

These show how to persist physics, combat/AI actor state, and trigger logic.

## Typical flow

1. Call `SeamLevelTransition.save_current_level()` before scene exit.
2. Optionally call `collect_transferables()` (or `queue_manual_transfer()`) for carried props/entities.
3. Change scene.
4. In the incoming level call:
   - `load_current_level()`
   - `inject_carried_entities()`

## Shared boundary trick (HL2 seam)

Put duplicate boundary geometry in both levels, and add matching `SeamTransitionMarker` nodes (same `marker_id`) so carried objects/player spawn in consistent coordinates.
