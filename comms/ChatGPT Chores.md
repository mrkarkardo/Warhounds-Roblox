# ChatGPT Chores

From Jackson, 2026-11-12. **Top priority: better gun effects.** Work top to bottom.
When you finish something, post a `DONE:` note on `comms/BOARD.md` saying what you changed in Studio.
Also tick its box here.

---

## How to work (read once)

- **You write the code or images; Jackson puts them in Studio.** Give him complete script text to
  paste over the old script, and say exactly which object it replaces. Don't send fragments.
- **Images go in `art/inbox/`** (PNG, transparent background, named
  `wh_fx_<name>_<size>.png`). Jackson uploads them and writes the asset ID back here.
- **The effects code lives in one place:** `ReplicatedStorage.WeaponEffects` (a ModuleScript).
  - Keep its function names and arguments exactly as they are: `Tracer(from, to)`,
    `MuzzleFlash(muzzleCf)`, `Impact(info)`, `BodyHit(pos)`, `PlaySound(id, parent, volume, maxDistance)`.
    Other scripts already call these.
  - You can add new functions; tell systems (Claude) on the board and we'll hook them up.
  - `info` in `Impact` has `Position`, `Normal`, `Color` and also `Material` (an `Enum.Material`).
    Use that to pick the effect.
- Effects run **on each player's computer only** (client side). They never change gameplay.
- **Performance rules (phones play this too):**
  - Every effect deletes itself within 2 seconds (`Debris:AddItem`).
  - No more than ~30 particles per shot.
  - Lights only on the muzzle flash, and nowhere else.
  - Keep the bullet-hole cap (`MAX_HOLES = 80`).
  - Prefer `ParticleEmitter:Emit(n)` bursts over emitters left running.
- **No z-fighting:** decals and holes sit 0.01–0.02 studs off the surface, never exactly on it.
- **Sounds and images must be ours or free to use:** Roblox audio library or self-made. No ripped
  CoD/Battlefield sounds. Toolbox items must contain **no scripts**.
- **Style:** grounded and realistic, not cartoony. Warm orange flash, grey-white smoke, short
  and punchy. Keep blood to a small dark-red puff (the game is for teens).
- Test in the **firing range**: Tab → walk into the range. You get free ammo there, and the paper
  targets show your hits.

---

## A. Gun effects (priority)

- [x] **A1. Muzzle flash.** Replace the orange block with a real flash.
  - Use 2–3 flash sprite images (front star plus side "petals") as a `ParticleEmitter` burst, plus
    a few fast sparks.
  - Keep the short `PointLight` (about 0.05 s).
  - Size by gun type: pistol small; rifle and SMG medium; LMG and sniper big. Systems can pass the
    gun's class in as a second argument; ask on the board.
  - *Images needed:* `wh_fx_flash_front_256`, `wh_fx_flash_side_256`.
- [ ] **A2. Muzzle smoke.** A small grey puff that drifts up after each shot. During long bursts
  (LMGs) it builds into a light haze at the barrel, then fades.
  - *Image needed:* `wh_fx_smoke_256` (soft puff).
- [x] **A3. Tracers.**
  - Replace the stick with a `Beam` between two attachments: bright head, fading tail, lives about
    0.06 s.
  - Not every bullet: LMGs show every 3rd round, other guns every 5th, snipers none. Systems will
    pass a shot counter; ask on the board.
- [x] **A4. Impacts by surface.** Use `info.Material`:
  - concrete, brick or rock: grey dust puff and chips
  - metal: bright sparks, no dust
  - wood: brown splinters and a light dust
  - dirt, grass or sand: dirt kick-up
  - glass: small white shards
  - Fall back to the current effect for anything else.
- [ ] **A5. Bullet holes by surface.** Decal holes instead of the black square: concrete, metal
  and wood versions. Same cap (80), same 12 s lifetime.
  - *Images needed:* `wh_fx_hole_concrete_128`, `wh_fx_hole_metal_128`, `wh_fx_hole_wood_128`.
- [x] **A6. Shell casings.** New function `Effects.Shell(ejectCf, caliberSize)`: a small brass part
  flips out to the right and up, spins, falls and is gone within about 1.5 s. Shotguns throw red
  hulls; bolt-action rifles throw only when you work the bolt.
  - **Systems will add an `EjectionPort` point to every gun and call this;** you only write the
    function.
- [ ] **A7. Sounds.** Find or make (Roblox library, free to use):
  - reload: mag out, mag in, charging handle
  - dry fire (click on empty)
  - bolt cycle (snipers)
  - shotgun pump
  - casings landing (tinkle)
  - impacts: concrete, metal, wood, dirt, body
  - a "distant shot" tail for gunfire far away
  - List the asset IDs in a table in this file. Systems wires them in.
- [x] **A8. Body hit.** Make `BodyHit` a short dark-red mist puff (no chunks). Keep it subtle.
- [ ] **A9. Frag grenade explosion.** Fireball flash, dust ring along the ground, smoke column,
  debris chips, and a scorch decal for 10 s. The current one is in `StarterCharacterScripts.GrenadeClient`;
  post the new effect as a function `Effects.Explosion(position)` and systems will switch it over.
  - *Image needed:* `wh_fx_scorch_256`.

**Finished means:** in the range, every gun's shot reads clearly from first person *and* from a
second player's view. No lag in a 30-round mag dump. Nothing is left behind in
`Workspace.WeaponEffects` after 2 s, except bullet holes.

---

## B. Environment helper (after A, or when Jackson asks)

The environment Claude owns the maps; coordinate on the board before moving anything solid.
Follow the six Studio rules in `ART-BRIEF.md` §3b (no coplanar faces, decor is
non-collidable, group in Models, etc.).

- [x] **B1. Lobby north wall posters** (art request #6). Two images for `MapScreen_1` and
  `MapScreen_2`: "WARHOUNDS 6v6" and "FIRING RANGE through the armory".
- [x] **B2. Map preview images** for the three vote boards, one per map (SIDING, BOCAGE, REACTOR,
  SOUK), 16:9. Systems will show them on the boards.
- [ ] **B3. Range ambience:** a low background hum, plus a muffled "ear-pro" feel? Propose it on the
  board first.
- [x] **B4. "Lived in" detail** wherever Jackson points: same rules as your last pass, which
  environment reviewed and liked.

---

## Asset IDs (systems fills these in after uploading; files then move to `art/uploaded/`)

| Name | Asset ID |
|---|---|
| wh_fx_flash_front_256 | `rbxassetid://102955940755279` ✅ |
| wh_fx_flash_side_256 | `rbxassetid://129889449766098` ✅ |
| wh_fx_smoke_256 | |
| wh_fx_hole_concrete_128 | |
| wh_fx_hole_metal_128 | |
| wh_fx_hole_wood_128 | |
| wh_fx_scorch_256 | |
| sounds (A7) | See the Creator Store shortlist below. |

## FX implementation and verification

- Shared Studio version **158** contains the current WeaponEffects module and the two client render call sites. The replacement sources are under `src/`.
- In the shared firing-range playtest, an actual 30-round AK-47 magazine ran in about 3.26 seconds at roughly 36 FPS on this Studio session. The observer event path rendered five rifle flashes and one tracer from five test events. The module smoke test exercised all five material groups, the casing and frag APIs, the 80-mark cap, and cleanup of transient effects within two seconds.
- A2 uses Roblox's built-in smoke texture until the new smoke is approved. A5 uses the round fallback marks until the three decal IDs are available. Set the WeaponEffects string attributes `SmokeTexture`, `HoleConcreteTexture`, `HoleMetalTexture`, `HoleWoodTexture`, and `ScorchTexture` to the approved asset IDs as they arrive.
- The shell and frag functions are ready for the systems call sites. The frag test ran without the custom scorch image. The full two-player and every-weapon visual acceptance pass is still open.
- B1 and B2 images are in the upload pipeline. The four previews are stills from the current Studio maps.

### A7 free Creator Store audio shortlist

These are audition candidates. The catalog describes the sources below. Sample the attack for longer foley recordings before wiring.

| Cue | Asset ID | Source and use |
|---|---|---|
| Magazine out | `9114704338` | Pro Sound Effects gun handling. Audition a short release or rattle. |
| Magazine in | `126787322008796` | Assembly Zero MP7 handling partial. Audition an insertion transient. |
| Charging handle | `9116342102` | Pro Sound Effects metal slide and ratchet. |
| Dry fire | `9116321026` | Pro Sound Effects locking-wrench click as mechanical foley. |
| Bolt cycle | `9116357621` | Pro Sound Effects bolt opening and closing. |
| Shotgun pump | `9112910701` | Pro Sound Effects pump and shell ejection. |
| Casings landing | `9113630798` | Pro Sound Effects metal casings on linoleum. |
| Concrete impact | `131554175554758` | Creator Store concrete impact candidate. Verify provenance before wiring. |
| Metal impact | `9114776487` | Pro Sound Effects metal clank. Use a short initial transient. |
| Wood impact | `9120964387` | Pro Sound Effects splinter sound. Audition the crack at the tail. |
| Dirt impact | `9113806887` | Pro Sound Effects cinder block falling into dirt. Trim and lower the level. |
| Body impact | `9113525391` | Pro Sound Effects body thud. |
| Distant shot tail | `116107048006711` | Creator Store distant-shot candidate. Verify provenance before wiring. |

### B3 range ambience proposal

Audition Pro Sound Effects Machine Room 4 (`9112825488`) as a low loop. Start at roughly 5% volume and fade it in and out with the Range zone. If ear protection is added, apply a mild high-frequency roll-off to range shots on the listener's client and leave voice, UI sounds, and footsteps clear.

### B4 lobby armory

Saved in Team Create version 160. Added a service mat and tools, inventory clipboard, hearing protection, and field kit under Workspace.Lobby.Armory.MaintenanceDetails. The 43 new parts have no collision, touch, raycast, or shadow behavior. Edit-mode inspection and the nearby block-face scan found zero near-coplanar overlaps. The builder is stored in studio/environment/armory-maintenance-details.luau. Remove the MaintenanceDetails folder to roll back this pass.
