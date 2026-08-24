---
name: product
description: Create or edit Roblox developer products via Open Cloud API and update the codebase
disable-model-invocation: true
argument-hint: <Name> <Price> robux OR change "<Name>" <field> to "<value>"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Developer Product Manager

Create or edit Roblox developer products via Open Cloud API and keep the codebase in sync.

## Modes

Detect the mode from `$ARGUMENTS`:

### Create Mode

If the input does NOT start with `change`/`edit`/`update`/`rename`, it's a create.

Single: `/product Gold Tier 49 robux`
Multiple: `/product Gold Tier 1 49 robux, Gold Tier 2 80 robux`

**Parsing**: Split by comma. For each entry, trim whitespace, strip trailing `robux`, the last number is the price, everything before it is the product name.

### Edit Mode

If the input starts with `change`, `edit`, `update`, or `rename`, it's an edit.

Examples:
- `/product change "Gold Tier 2" name to "Coins Tier 2"`
- `/product rename "Gold Tier 2" to "Coins Tier 2"` (shorthand — implies name change)
- `/product change "Gold Tier 2" price to 120`
- `/product edit "Starter Pack" description to "A great starter bundle"`

**Parsing**: Extract the quoted original product name, the field to change (`name`/`price`/`description`), and the new value (quoted string or number). For `rename`/`rename X to Y` without a field keyword, assume field is `name`.

Multiple edits can be comma-separated:
- `/product change "Gold Tier 1" price to 50, change "Gold Tier 2" name to "Coins Tier 2"`

## Steps — Create Mode

1. **Read credentials** from `info.env` in the project root:
   - `CLOUD_API_KEY` — Roblox Open Cloud API key
   - `GAMEID` — Universe ID

2. **Discover the codebase schema** — Search the codebase for where developer products are registered. Look for Lua/Luau files with `Products` tables, `ProductId`, `ProductName`, or `MarketplaceService` references. Read the file and study existing entries to understand the exact schema (fields, key format, naming conventions).

3. **Check for duplicates** — Skip any products that already exist in the discovered table.

4. **Create each product** via Open Cloud API:
```bash
curl -s -X POST "https://apis.roblox.com/developer-products/v2/universes/${GAMEID}/developer-products" \
  -H "x-api-key: ${CLOUD_API_KEY}" \
  -F "name=${PRODUCT_NAME}" \
  -F "price=${PRICE}" \
  -F "isForSale=true"
```
Parse JSON response for `productId`. Continue on failure.

5. **Register in codebase** — Add successful products to the discovered file, matching the exact schema/style of existing entries. The product name sent to the API MUST match the field the codebase uses for runtime identification. Always set the `ID` field in the codebase config with the `productId` returned from the API.

6. **Report** summary table: name, price, product ID, status.

## Steps — Edit Mode

1. **Read credentials** from `info.env`.

2. **Discover the codebase schema** — Same as create mode. Find and read the file where products are defined.

3. **Resolve product ID** — The update API requires the numeric product ID. To get it:
   - First check if the product ID is stored in the codebase config. If so, use it directly.
   - Otherwise, list all creator products from the API:
```bash
curl -s "https://apis.roblox.com/developer-products/v2/universes/${GAMEID}/developer-products/creator" \
  -H "x-api-key: ${CLOUD_API_KEY}"
```
   Match by name to find the `productId`. If not found, report error and stop for that product.

4. **Update via API**:
```bash
curl -s -X PATCH "https://apis.roblox.com/developer-products/v2/universes/${GAMEID}/developer-products/${PRODUCT_ID}" \
  -H "x-api-key: ${CLOUD_API_KEY}" \
  -F "${FIELD}=${NEW_VALUE}"
```
A 204 response means success. On failure, report the error and continue.

5. **Update codebase** — If a name changed, update both the table key and the product name field in the codebase file to match the new name. If price changed and the codebase stores prices, update that too. Always keep codebase in sync with what was sent to the API.

6. **Report** summary of changes made.

## Important

- Both APIs use `multipart/form-data` (not JSON)
- `GAMEID` in info.env is the **universe ID**
- Always set the ID in the codebase's developer product configuration if possible. When creating, use the `productId` from the API response. When editing, ensure the ID stays correct.
- Do NOT assume a specific file or schema — always discover from the codebase
- Use the `/creator` endpoint (`/developer-products/creator`) specifically to list and look up existing products by name
- Process all products/edits even if some fail — report failures individually
- When editing names, update ALL references in the codebase (the config file key, the name field, and any other files that reference the old product name)
