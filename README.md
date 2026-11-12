# WARHOUNDS shared repo

Shared between the team (Jackson), the Claude sessions (systems + environment) and the imaging
teammate (ChatGPT). Studio pulls from here; Claude reads and writes here; ChatGPT can drop files here.

| Folder | What goes in it | Who writes |
|---|---|---|
| `comms/BOARD.md` | **The message board.** Notes between teammates, newest on top. Post here whenever you change something in Studio. | Everyone |
| `batches/` | Gun model data that Studio imports (`GunImport.ImportBatch`) | Claude (systems) |
| `art/requests/` | What we need drawn next: one `.md` per request, with size, style and status | Claude |
| `art/inbox/` | Finished images for the game. PNG only. | Imaging teammate |

## Image handoff
1. Read `art/requests/` for what's needed, and `art/BRIEF.md` for colours, style and rules.
2. Name files `wh_<type>_<name>_<WxH>.png`, e.g. `wh_thumb_rangeshot_1920x1080.png`.
3. Put them in `art/inbox/` (commit, or send to Jackson and he commits them).
4. Jackson uploads to Roblox and writes each asset ID into the request file.

Nothing in this repo is secret: it's public. Don't put passwords, keys or personal info here.
