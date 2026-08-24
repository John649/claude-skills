---
name: gamepass
description: Create or edit Roblox game passes via Open Cloud API and update the codebase
disable-model-invocation: true
argument-hint: <Name> <Price> robux OR change "<Name>" <field> to "<value>"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Game Pass Manager

Create or edit Roblox game passes via Open Cloud API and keep the codebase in sync.

## Modes

Detect the mode from `$ARGUMENTS`:

### Create Mode

If the input does NOT start with `change`/`edit`/`update`/`rename`, it's a create.

Single: `/gamepass VIP 499 robux`
Multiple: `/gamepass VIP 499 robux, Double XP 299 robux`

**Parsing**: Split by comma. For each entry, trim whitespace, strip trailing `robux`, the last number is the price, everything before it is the game pass name.

### Edit Mode

If the input starts with `change`, `edit`, `update`, or `rename`, it's an edit.

Examples:
- `/gamepass change "VIP" name to "VIP Plus"`
- `/gamepass rename "VIP" to "VIP Plus"` (shorthand — implies name change)
- `/gamepass change "VIP" price to 699`
- `/gamepass edit "VIP" description to "Premium perks for racers"`

**Parsing**: Extract the quoted original game pass name, the field to change (`name`/`price`/`description`), and the new value (quoted string or number). For `rename`/`rename X to Y` without a field keyword, assume field is `name`.

Multiple edits can be comma-separated:
- `/gamepass change "VIP" price to 699, rename "Double XP" to "Triple XP"`

## Steps — Create Mode

1. **Read credentials** from `info.env` in the project root:
   - `CLOUD_API_KEY` — Roblox Open Cloud API key
   - `GAMEID` — Universe ID

2. **Discover the codebase schema** — Search the codebase for where game passes are registered. Look for Lua/Luau files with `Gamepasses`/`GamePasses` tables, `GamepassId`, `GamePassId`, or `MarketplaceService` references. Read the file and study existing entries to understand the exact schema (fields, key format, naming conventions).

3. **Check for duplicates** — Skip any game passes that already exist in the discovered table.

4. **Create each game pass** via Open Cloud API:
```bash
curl -s -X POST "https://apis.roblox.com/game-passes/v1/universes/${GAMEID}/game-passes" \
  -H "x-api-key: ${CLOUD_API_KEY}" \
  -F "name=${GAMEPASS_NAME}" \
  -F "price=${PRICE}" \
  -F "isForSale=true"
```
Parse JSON response for `gamePassId`. Continue on failure.

5. **Register in codebase** — Add successful game passes to the discovered file, matching the exact schema/style of existing entries. The game pass name sent to the API MUST match the field the codebase uses for runtime identification. Always set the `ID` field in the codebase config with the `gamePassId` returned from the API.

6. **Report** summary table: name, price, game pass ID, status.

## Steps — Edit Mode

1. **Read credentials** from `info.env`.

2. **Discover the codebase schema** — Same as create mode. Find and read the file where game passes are defined.

3. **Resolve game pass ID** — The update API requires the numeric game pass ID. To get it:
   - First check if the game pass ID is stored in the codebase config. If so, use it directly.
   - Otherwise, list all creator game passes from the API:
```bash
curl -s "https://apis.roblox.com/game-passes/v1/universes/${GAMEID}/game-passes/creator" \
  -H "x-api-key: ${CLOUD_API_KEY}"
```
   Match by name to find the `gamePassId`. If not found, report error and stop for that game pass. Paginate with `pageToken` if needed.

4. **Update via API**:
```bash
curl -s -X PATCH "https://apis.roblox.com/game-passes/v1/universes/${GAMEID}/game-passes/${GAMEPASS_ID}" \
  -H "x-api-key: ${CLOUD_API_KEY}" \
  -F "${FIELD}=${NEW_VALUE}"
```
A 204 response means success. On failure, report the error and continue.

5. **Update codebase** — If a name changed, update both the table key and the game pass name field in the codebase file to match the new name. If price changed and the codebase stores prices, update that too. Always keep codebase in sync with what was sent to the API.

6. **Report** summary of changes made.

## Important

- Both APIs use `multipart/form-data` (not JSON)
- `GAMEID` in info.env is the **universe ID**
- Always set the ID in the codebase's game pass configuration if possible. When creating, use the `gamePassId` from the API response. When editing, ensure the ID stays correct.
- Do NOT assume a specific file or schema — always discover from the codebase
- Use the `/creator` endpoint (`/game-passes/creator`) specifically to list and look up existing game passes by name
- Process all game passes/edits even if some fail — report failures individually
- When editing names, update ALL references in the codebase (the config file key, the name field, and any other files that reference the old game pass name)
