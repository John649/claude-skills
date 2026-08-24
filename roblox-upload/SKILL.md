---
name: roblox-upload
description: Upload local asset files (audio .mp3/.ogg, images .png/.jpg, models .fbx) to Roblox via the Open Cloud Assets API and get back the rbxassetid, and create/list developer products and game passes for a universe. Use when the user asks to upload a sound, image, decal, or asset to Roblox, to create a dev product or game pass, or when ported content needs re-uploaded assets because the originals are private to another experience or archived.
---

# roblox-upload — publish local files as Roblox assets

Uploads a file from disk to Roblox with the Open Cloud Assets API and returns
the new asset id, ready to paste into a `SoundId`/`Image` property or a
constants file. Built because copied content (e.g. GUIs/sounds ported from
another experience) often references audio that is private to the source
experience or archived — the fix is re-uploading the file under the user's own
account.

## Setup (first run only)

Config lives at `<this skill's directory>/config.env`:

```
ROBLOX_API_KEY=<Open Cloud API key>
ROBLOX_CREATOR_TYPE=userId        # or groupId
ROBLOX_CREATOR_ID=<numeric user or group id>
```

If `config.env` is missing, walk the user through creating it — you cannot do
this for them:

1. https://create.roblox.com/dashboard/credentials → **Create API Key**.
2. Add the **assets** API system with **read** and **write** permissions.
3. Accepted IP: their IP, or `0.0.0.0/0` for any (less secure, simpler).
4. They paste the key to you **in chat only if they choose to**; better, have
   them create `config.env` themselves (`! notepad <path>` works). Never echo
   the key back, never commit it, never send it anywhere except
   `apis.roblox.com`.
5. `ROBLOX_CREATOR_ID`: their user id (profile URL number) — or a group id
   with `ROBLOX_CREATOR_TYPE=groupId` if assets should belong to a group.
   Uploading under the same identity that owns the experience is what makes
   audio playable in it without extra permission grants.

## Usage

```bash
bash "<this skill's directory>/upload.sh" <file> [displayName]
```

- Asset type is inferred from the extension: `.mp3`/`.ogg` → Audio,
  `.png`/`.jpg`/`.jpeg`/`.bmp`/`.tga` → Decal, `.fbx` → Model.
  (Roblox audio upload accepts only mp3 and ogg — convert `.wav` first, e.g.
  `ffmpeg -i in.wav out.ogg`.)
- `displayName` defaults to the file stem. Roblox moderates names — keep them
  bland.
- The script polls the returned operation until moderation finishes and prints
  the asset id as the last line: `ASSET_ID=1234567890`.
- Batch: loop over files, one call each; report a table of file → id at the end.

After a successful upload, offer the follow-through, not just the id:
- Set it live via msync if a place is connected
  (`msync set <path> SoundId rbxassetid://<id> --place <id>`), or
- Edit the id into the code/constants file that references the old asset.

## Dev products and game passes

```bash
bash "<this skill's directory>/monetize.sh" devproduct <universeId> <name> <priceRobux> [description]
bash "<this skill's directory>/monetize.sh" gamepass   <universeId> <name> <priceRobux> [description]
bash "<this skill's directory>/monetize.sh" list-devproducts <universeId>
bash "<this skill's directory>/monetize.sh" list-gamepasses  <universeId>
```

- Prints `DEV_PRODUCT_ID=<id>` / `GAME_PASS_ID=<id>` on success — the id to
  paste into the code that prompts the purchase (e.g. a ProductIds constants
  module).
- `universeId` is the **universe** id, not a place id. In a Rojo project it is
  the `gameId` field of `*.project.json`; otherwise Creator Dashboard → the
  experience → the number in its URL.
- The same `config.env` API key needs the **developer-products** and
  **game-passes** API systems added (write to create, read to list) — these are
  separate systems from **assets** in the key editor.
- These are **Beta** Open Cloud endpoints (they replaced the legacy web
  endpoints, deprecated April 2026). The create call tries multipart form
  first, then falls back to JSON; if both fail, show the raw response — the
  shape may have shifted, so check the docs at
  https://create.roblox.com/docs/cloud/features/developer-products before
  patching the script.
- Creating things that charge Robux is an outward-facing account action:
  always confirm name + price with the user before calling create.

## Failure modes

| Symptom | Meaning / fix |
| --- | --- |
| 401 | Bad or expired key, or IP not in the key's accepted list. |
| 403 `Insufficient scope` | Key lacks assets read/write. |
| 429 | Quota hit — audio uploads are rate/volume limited per month; tell the user, don't retry-loop. |
| Operation ends without an assetId | Moderation rejected the file or name — report the `moderationResult` the script prints. |
| Asset id works in Studio but not in game | Audio under ~6s is public by default; longer audio uploaded by the experience owner is auto-granted. If the owner differs (group vs user), grant access under the asset's permissions on the Creator Dashboard. |

## Notes

- Uploads are **public actions against the user's account** — upload only files
  the user asked to upload.
- Fresh audio can take a minute+ to pass moderation; the script polls up to
  ~2 minutes, then prints the operation path so you can re-check later with
  `bash upload.sh --check <operationPath>`.
