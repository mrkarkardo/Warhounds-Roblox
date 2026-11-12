# ChatGPT Optimization Rules

From Jackson, 2026-11-12: "optimize the game to standard." These are the house rules for
anything you build or change in WARHOUNDS. They apply on top of `comms/ChatGPT Chores.md`
and `art/BRIEF.md`.

**The standard:** 60 fps on a mid-range PC and 30 fps on a 3-year-old phone in a full 6v6
match. Join time under 20 s, and under 1 GB of memory on phones (Developer Console, F9 → Memory).

---

## 1. Budgets (hard limits)

| Thing | Limit | Today |
|---|---|---|
| One match map: parts | ≤ 3,000 | ~750 each ✅ |
| One match map: collidable parts | ≤ 600 | ~145 each ✅ |
| One match map: lights | ≤ 20, **≤ 8 with shadows** | ~17, all shadowed ⚠ |
| Lobby: parts | ≤ 3,500 | 2,982 ✅ |
| Lobby: lights | **≤ 30**, ≤ 8 with shadows | **66** ❌ |
| One gun effect (one shot) | ≤ 30 particles, gone in ≤ 2 s | — |
| Lights in effects | muzzle flash only, ≤ 0.06 s | — |
| One image | 256×256 for FX, 512 for decals, 1024 max | — |
| One sound | ≤ 10 s for SFX, ≤ 2 min for ambience | — |

If a change would break a limit, don't make it. Post on `comms/BOARD.md` and ask first.

## 2. Parts

- **Anchored = true** on everything that doesn't move. Unanchored parts cost physics every frame.
- **Decor** (anything you can't stand on or take cover behind):
  - `CanCollide = false`, `CanTouch = false`, `CanQuery = false`.
  - Bullets and players then skip it entirely.
- **`CastShadow = false`** on small parts (under ~2 studs) and anything thin: trim, cables,
  signs, bolts.
- **Fewer, bigger parts.** A wall is 1 part, not 12. A shelf of 20 identical cans is better as
  1 MeshPart.
- **MeshParts over Unions** for complex shapes. If you do use a union, keep it under ~500 triangles.
- **Reuse meshes and images.** 50 crates that use the same `MeshId` and texture cost about as
  much as one. 50 slightly different crates cost 50×.
- **MeshPart settings:**
  - decor: `CollisionFidelity = Box`, `RenderFidelity = Automatic`
  - cover: `CollisionFidelity = Hull`
- **No coplanar faces** (z-fighting): overlap by 0.05 studs or sink one part into the other.
- **Group into Models inside Folders** (rule G). Set big decor Models to
  `ModelStreamingMode = Atomic` so they stream in whole.

## 3. Lights

- **Shadows are the expensive part.** Only the 2–4 lights that *define* a room cast shadows.
  Fill and accent lights have `Shadows = false`.
- `Range` ≤ 24 studs indoors. A bigger range touches more parts.
- Prefer **Neon material + no light** for small glowing things (signs, LEDs, screens).
- One `SurfaceLight` lights a whole panel. Don't put 5 `PointLight`s in a row.

## 4. Images and materials

- Use Roblox **Materials** (Concrete, Metal, Wood…) before reaching for a `Texture` or `Decal`.
- Only use transparent PNGs when you need the transparency. Every transparent layer is drawn
  on top of everything behind it.
- Same image = same asset ID. Upload once and reuse (systems handles uploads; see README).

## 5. Scripts (code you write for Jackson to paste)

- **Visual effects run on the client only.** The server never creates parts for visuals.
- **No `while true do` without a `task.wait()`.** No loops that walk `GetDescendants()` every
  frame. Walk once, keep the list.
- **Events over polling:** `.Changed`, `GetAttributeChangedSignal`, `ChildAdded`, and so on.
- **Clean up:**
  - `Debris:AddItem(x, seconds)` for anything temporary.
  - `:Disconnect()` connections you no longer need.
  - Destroy what you create when the character dies or the player leaves.
- `RenderStepped` / `BindToRenderStep` only for things tied to the camera. Everything else uses
  `Heartbeat` or events.
- **Pool things fired many times a second.** Reuse 20 tracer parts instead of creating 600 a
  minute.
- **Streaming is ON.** On the client a part may not exist yet:
  - Use `WaitForChild(name, timeout)` and handle `nil`.
  - Never assume the whole map is loaded.
- **Remotes:** never fire every frame. At most ~10/s per player, and the server checks every
  value it receives.

## 6. Sounds

- `.ogg`/`.mp3`, mono for 3D sounds.
- Set `RollOffMaxDistance`; weapons use 300.
- Never stack the same sound more than 3 times at once (cap it in code).
- Destroy one-shot sounds after they play (`Debris`).

## 7. How to check your work

- **Count:** paste in the Studio command bar:
  `local n,c,l,s=0,0,0,0 for _,d in workspace.Maps.SOUK:GetDescendants() do if d:IsA("BasePart") then n+=1 if d.CanCollide then c+=1 end elseif d:IsA("Light") then l+=1 if d.Shadows then s+=1 end end end print(n,"parts",c,"collide",l,"lights",s,"shadowed")`
- **Frame time:** in a playtest press **Ctrl+F6** (MicroProfiler). Frames should stay under
  16 ms on PC.
- **Memory:** **F9** → Memory. Watch `PlaceMemory` and `GraphicsTexture` before and after your
  change.
- **Phone:** Studio → Test → Device emulator → a phone, and play a full round.
- Post the before/after numbers on the board with every optimisation `DONE:`.

## 8. Don't touch

- **Gun models and the armory wall display** belong to the systems pipeline. Gun optimisation
  ("gun diet") is a systems job.
- **Scripts** other than `WeaponEffects` and ones you created. Ask on the board first.
- **Collision or cover on maps:** coordinate with the environment Claude. Gameplay depends on it.

---

## Optimisation chores (found 2026-11-12)

- [ ] **O1. Lobby lights 66 → ≤ 30.** Merge rows of point lights into SurfaceLights, swap tiny
  lights for Neon, and keep shadows on ≤ 8. Make sure it still looks the same in a screenshot.
- [ ] **O2. Map shadows.** On each map, keep shadows on the main 4–8 lights and turn them off
  on the rest. Before/after screenshots on the board.
- [ ] **O3. `Workspace.Wood Craftes`** (76 loose collidable parts). Move it into the right map
  or lobby folder as a grouped Model, or delete it if it's a leftover. Ask Jackson which.
- [ ] **O4. Decor audit.** Walk every map and the lobby: any part that isn't floor, wall or
  cover → decor flags (section 2), and `CastShadow` off on small parts. Report counts.
- [ ] **O5 (systems, FYI).** Gun diet: ~960 parts per gun → a few MeshParts each, and the wall
  display reuses the game models. This is the biggest win in the game: about 118k parts.
  Systems will do it.
- [ ] **O6 (ask Jackson).** `Workspace.Map_Shipment` (2,105 parts) is the old test map. Remove it
  from Workspace if it's no longer used.
