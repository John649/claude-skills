---
name: roblox-asset-transfer
description: Transfer live instances (models, VFX, GUIs, folders) between two open Roblox Studio places using SerializationService and a local HTTP relay — no manual copy-paste. Use when the user asks to move/copy/port instances or assets from one Studio place to another.
---

# Roblox Studio → Studio instance transfer

Moves instances between two Studio places open on this machine, via the Roblox Studio MCP
(`mcp__roblox__*`). Flow: **source place → SerializeInstancesAsync → POST to local relay →
GET from relay → DeserializeInstancesAsync → target place**. Copies are faithful: all
descendants, properties, and attributes survive.

## Prerequisites

- Both places open in Studio and connected to the MCP (`list_roblox_studios` shows both).
- Python available (for the relay).
- Know the exact source path of the instances and the desired target parent path.

## Procedure

### 1. Start the relay

Run `asset_relay.py` (in this skill's directory) with Bash `run_in_background: true`:

```
python "<skill-dir>/asset_relay.py"        # listens on 127.0.0.1:8667
```

It is a dumb mailbox: `POST /assets` stores raw bytes in memory, `GET /assets` returns them.
Any path works, so multiple transfers can use different paths in one session.

### 2. Identify the two Studios

`list_roblox_studios`, then `set_active_studio` on the presumed **source**. Never trust the
window name alone — probe with `execute_luau` (datamodel `Edit`) that the expected source
instances actually exist before serializing (return `game.Name` on failure so you can retarget).

### 3. Serialize + POST from the source place

`execute_luau` (Edit) in the source Studio:

```lua
local HttpService = game:GetService("HttpService")
local SerializationService = game:GetService("SerializationService")
local wasEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local instances = { --[[ exact instances to copy ]] }
local ok, err = pcall(function()
	local buf = SerializationService:SerializeInstancesAsync(instances)
	local resp = HttpService:RequestAsync({
		Url = "http://localhost:8667/assets",
		Method = "POST",
		Headers = { ["Content-Type"] = "application/octet-stream" },
		Body = buffer.tostring(buf),
	})
	assert(resp.Success, "HTTP " .. tostring(resp.StatusCode))
end)
HttpService.HttpEnabled = wasEnabled  -- ALWAYS restore, even on failure
if not ok then return "FAILED: " .. tostring(err) end
return "POSTED ok"
```

Confirm receipt by reading the relay's output file (`stored N bytes at /assets`).

### 4. GET + deserialize into the target place

`set_active_studio` to the target, probe it's the right place, then `execute_luau` (Edit):

```lua
local HttpService = game:GetService("HttpService")
local SerializationService = game:GetService("SerializationService")
local wasEnabled = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local result
local ok, err = pcall(function()
	local resp = HttpService:RequestAsync({ Url = "http://localhost:8667/assets", Method = "GET" })
	assert(resp.Success, "HTTP " .. tostring(resp.StatusCode))
	local instances = SerializationService:DeserializeInstancesAsync(buffer.fromstring(resp.Body))
	local targetParent = --[[ ensure/create the destination folder chain ]]
	local names = {}
	for _, inst in instances do
		local old = targetParent:FindFirstChild(inst.Name)
		if old then old:Destroy() end  -- replace same-named leftovers
		inst.Parent = targetParent
		table.insert(names, inst.ClassName .. ":" .. inst.Name .. " (" .. #inst:GetDescendants() .. " desc)")
	end
	result = table.concat(names, ", ")
end)
HttpService.HttpEnabled = wasEnabled
if not ok then return "FAILED: " .. tostring(err) end
return "IMPORTED: " .. result
```

### 5. Verify and clean up

- `execute_luau` in the target: enumerate descendants of each imported root and check the
  expected children (attachments, emitters, beams, welds, scripts) arrived.
- Stop the relay (`TaskStop` on the background Bash task).
- If the target project uses Argon/Rojo two-way sync, remind the user to **save the place**
  so the instances persist (with `keep_unknowns`, unmanaged instances survive sync; without
  it, park them outside file-managed folders).

## Gotchas

- `Enum.HttpContentType.ApplicationOctetStream` **does not exist** — use
  `HttpService:RequestAsync` with a `Content-Type` header, not `PostAsync`.
- `HttpService.HttpEnabled` must be flipped on in **both** places; always restore the prior
  value in the same script (pcall around the network work, restore after).
- `SerializationService` requires a recent Studio; if it's missing, fall back to asking the
  user to copy-paste between the two Studio windows.
- Serialized copies carry **instances, not cloud assets**: `rbxassetid://` references
  (textures, meshes, sounds, animations) still load from Roblox and only render if the
  target game's owner/group can use them. Flag this to the user when owners differ.
- `RequestAsync` bodies are strings and binary-safe, but very large payloads can hit
  HttpService limits (~1 GB practical ceiling is far above typical models; multi-MB is fine).
  For huge trees, serialize in batches to different relay paths.
- Scripts inside the copied tree transfer with full source. That is usually desired; mention
  it if the user only wanted visuals.
