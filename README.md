# WARHOUNDS shared repo

Shared between the team (Jackson), the Claude sessions (systems + environment) and the imaging
teammate (ChatGPT). Studio pulls from here; Claude reads and writes here; ChatGPT can drop files here.

| Folder | What goes in it | Who writes |
|---|---|---|
| `comms/ChatGPT Chores.md` | **ChatGPT's to-do list** (effects first, then environment help). Tick boxes when done. | ChatGPT / Jackson |
| `comms/ChatGPT Optimization Rules.md` | **Performance rules and budgets** for everything built, plus optimisation chores. | ChatGPT / Jackson |
| `comms/BOARD.md` | **The message board.** Notes between teammates, newest on top. Post here whenever you change something in Studio. | Everyone |
| `batches/` | Gun model data that Studio imports (`GunImport.ImportBatch`) | Claude (systems) |
| `art/requests/` | What we need drawn next: one `.md` per request, with size, style and status | Claude |
| `art/inbox/` | Finished images for the game. PNG only. | Imaging teammate |

## Image handoff
1. Read `art/requests/` and `comms/ChatGPT Chores.md` for what's needed, and `art/BRIEF.md` for colours, style and rules.
2. Name files `wh_<type>_<name>_<WxH>.png`, e.g. `wh_fx_smoke_256.png`. PNG only.
3. Push them to `art/inbox/`.
4. **Claude (systems) uploads them to Roblox automatically** (standing OK from Jackson). It copies
   them to Jackson's PC (`Downloads\WARHOUNDS-art`, the approved upload folder), uploads through
   Studio, and writes each asset ID into the table in `ChatGPT Chores` or the request file.
   Uploaded files then move from `art/inbox/` to `art/uploaded/`.
5. Images can show blank in game for a few minutes while Roblox moderates them.

Uploaded so far: `art/brand/warhounds_logo_transparent.png` → `rbxassetid://129051910041827`
(loading screen + lobby wall screen 1).

Nothing in this repo is secret: it's public. Don't put passwords, keys or personal info here.
