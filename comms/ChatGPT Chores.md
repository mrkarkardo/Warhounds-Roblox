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

- [ ] **A1. Muzzle flash.** Replace the orange block with a real flash.
  - Use 2–3 flash sprite images (front star plus side "petals") as a `ParticleEmitter` burst, plus
    a few fast sparks.
  - Keep the short `PointLight` (about 0.05 s).
  - Size by gun type: pistol small; rifle and SMG medium; LMG and sniper big. Systems can pass the
    gun's class in as a second argument; ask on the board.
  - *Images needed:* `wh_fx_flash_front_256`, `wh_fx_flash_side_256`.
- [ ] **A2. Muzzle smoke.** A small grey puff that drifts up after each shot. During long bursts
  (LMGs) it builds into a light haze at the barrel, then fades.
  - *Image needed:* `wh_fx_smoke_256` (soft puff).
- [ ] **A3. Tracers.**
  - Replace the stick with a `Beam` between two attachments: bright head, fading tail, lives about
    0.06 s.
  - Not every bullet: LMGs show every 3rd round, other guns every 5th, snipers none. Systems will
    pass a shot counter; ask on the board.
- [ ] **A4. Impacts by surface.** Use `info.Material`:
  - concrete, brick or rock: grey dust puff and chips
  - metal: bright sparks, no dust
  - wood: brown splinters and a light dust
  - dirt, grass or sand: dirt kick-up
  - glass: small white shards
  - Fall back to the current effect for anything else.
- [ ] **A5. Bullet holes by surface.** Decal holes instead of the black square: concrete, metal
  and wood versions. Same cap (80), same 12 s lifetime.
  - *Images needed:* `wh_fx_hole_concrete_128`, `wh_fx_hole_metal_128`, `wh_fx_hole_wood_128`.
- [ ] **A6. Shell casings.** New function `Effects.Shell(ejectCf, caliberSize)`: a small brass part
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
- [ ] **A8. Body hit.** Make `BodyHit` a short dark-red mist puff (no chunks). Keep it subtle.
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

- [ ] **B1. Lobby north wall posters** (art request #6). Two images for `MapScreen_1` and
  `MapScreen_2`: "WARHOUNDS 6v6" and "FIRING RANGE through the armory".
- [ ] **B2. Map preview images** for the three vote boards, one per map (SIDING, BOCAGE, REACTOR,
  SOUK), 16:9. Systems will show them on the boards.
- [ ] **B3. Range ambience:** a low background hum, plus a muffled "ear-pro" feel? Propose it on the
  board first.
- [ ] **B4. "Lived in" detail** wherever Jackson points: same rules as your last pass, which
  environment reviewed and liked.

---

## Asset IDs (Jackson fills these in after uploading)

| Name | Asset ID |
|---|---|
| wh_fx_flash_front_256 | |
| wh_fx_flash_side_256 | |
| wh_fx_smoke_256 | |
| wh_fx_hole_concrete_128 | |
| wh_fx_hole_metal_128 | |
| wh_fx_hole_wood_128 | |
| wh_fx_scorch_256 | |
| sounds (A7) | |
