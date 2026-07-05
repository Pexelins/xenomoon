# Jeh3no FPS Weapon System — Salvage

Addon rejected. Reference snippets only — NOT drop-in code.
Re-implement against project conventions: strict typed GDScript, composition model.
Rejection verdict: `library/addons/fps-weapon-system.md`
Full addon in git at commit `8defbf2` ("experiment: install Jeh3no FPS weapon system addon").

---

## 1. Shot SFX

**Salvaged to:** `assets/audio/weapon_fire.wav` (also `pistol_shoot.wav`)
**Original addon path:** `addons/JehenoSimpleFPSWeaponSystem/Weapons/Audio/`
**What it is:** One-shot pistol fire SFX triggered by shoot manager. Use as reference WAV when
wiring audio to the project's own weapon system (skill: godot-audio).

---

## 2. Camera Recoil on Shooting

**Salvaged scripts:**

- `camera_recoil_holder_script.gd` — Node that owns recoil state; apply impulse on fire, spring back
- `viewport_camera_script.gd` — Camera wrapper; receives recoil from holder

**Original addon paths:**

- `addons/JehenoSimpleFPSWeaponSystem/Weapons/Scripts/Camera/camera_recoil_holder_script.gd`
- `addons/JehenoSimpleFPSWeaponSystem/Weapons/Scripts/Camera/viewport_camera_script.gd`

**Shoot-manager hook:** `shoot_managers_script.gd` (also salvaged) calls into recoil holder on
each successful fire. See `_apply_recoil()` region in that script.

**Tuning notes:** Recoil feel is good. Parameters will need tweaking when adapting.

---

## 3. Player Movement Controller

**Salvaged scripts:**

- `input_management_component_script.gd` — Handles all player input including mouse look
- `player_camera_script.gd` — Aim / mouse-look camera (vertical pitch + horizontal yaw)
- `state_machine_script.gd` — Minimal state machine base
- `state_script.gd` — Base state node
- `idle_state_script.gd` — Idle state
- `walk_state_script.gd` — Walk state
- `run_state_script.gd` — Run state
- `jump_state_script.gd` — Jump state
- `inair_state_script.gd` — In-air state

**Original addon paths:** all under
`addons/JehenoSimpleFPSWeaponSystem/Weapons/Scripts/` (movement sub-tree)

**TUNING NOTES (user, 2026-06-18):**

> Player movement is much better than ours but TOO FAST.
> Aim/mouse-look also TOO FAST — slow both when adapting.

When re-implementing: reduce base `speed` and `mouse_sensitivity` constants significantly
before first playtest. The state-machine structure is worth keeping; the raw values are not.

---

## Re-implementation guidance

1. Do NOT copy-paste these scripts into the game. They are untyped / mixed-style Godot 3/4.
2. Extract the _logic_ (state transitions, recoil spring math, mouse-look clamp) and rewrite
   per `godot-code-rules` (strict typed GDScript, `class_name`, signals up / calls down).
3. Follow `godot-composition`: one component per job, exports for tunable params.
4. Wire audio per `godot-audio` skill (no global AudioManager).
