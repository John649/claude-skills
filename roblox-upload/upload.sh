#!/usr/bin/env bash
# Upload a local file to Roblox as an asset via the Open Cloud Assets API.
#
#   upload.sh <file> [displayName]     upload and poll until moderated
#   upload.sh --check <operationPath>  re-poll an operation from a prior run
#
# Reads config.env (ROBLOX_API_KEY, ROBLOX_CREATOR_TYPE, ROBLOX_CREATOR_ID)
# from the script's own directory. Prints ASSET_ID=<id> as the last line on
# success. See SKILL.md for setup and failure modes.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DIR/config.env"
API="https://apis.roblox.com/assets/v1"

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: $CONFIG missing — see SKILL.md setup section" >&2
    exit 2
fi
# shellcheck disable=SC1090
source "$CONFIG"
: "${ROBLOX_API_KEY:?config.env must set ROBLOX_API_KEY}"
: "${ROBLOX_CREATOR_TYPE:=userId}"
: "${ROBLOX_CREATOR_ID:?config.env must set ROBLOX_CREATOR_ID}"

# Minimal JSON field extraction; uses jq when present, falls back to sed.
json_get() { # json_get <key> — reads stdin
    if command -v jq >/dev/null 2>&1; then
        jq -r "..|.\"$1\"? // empty" 2>/dev/null | head -1
    else
        sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" | head -1
    fi
}

poll_operation() { # poll_operation <operationPath like operations/uuid>
    local op="$1" tries=0 body done_flag asset_id
    while [ $tries -lt 24 ]; do
        body=$(curl -sS -H "x-api-key: $ROBLOX_API_KEY" "$API/$op")
        done_flag=$(printf '%s' "$body" | json_get done)
        if [ "$done_flag" = "true" ]; then
            asset_id=$(printf '%s' "$body" | json_get assetId)
            if [ -n "$asset_id" ]; then
                echo "ASSET_ID=$asset_id"
                return 0
            fi
            echo "Operation finished without an assetId — likely rejected by moderation:" >&2
            printf '%s\n' "$body" >&2
            return 3
        fi
        tries=$((tries + 1))
        sleep 5
    done
    echo "Still processing after ~2 minutes. Re-check later with:" >&2
    echo "  bash \"$DIR/upload.sh\" --check $op" >&2
    return 4
}

if [ "${1:-}" = "--check" ]; then
    [ -n "${2:-}" ] || { echo "usage: upload.sh --check <operationPath>" >&2; exit 2; }
    poll_operation "$2"
    exit $?
fi

FILE="${1:-}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: upload.sh <file> [displayName]" >&2; exit 2; }
NAME="${2:-$(basename "$FILE" | sed 's/\.[^.]*$//')}"

ext="${FILE##*.}"
case "$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')" in
    mp3) TYPE=Audio; MIME=audio/mpeg ;;
    ogg) TYPE=Audio; MIME=audio/ogg ;;
    png) TYPE=Decal; MIME=image/png ;;
    jpg|jpeg) TYPE=Decal; MIME=image/jpeg ;;
    bmp) TYPE=Decal; MIME=image/bmp ;;
    tga) TYPE=Decal; MIME=image/tga ;;
    fbx) TYPE=Model; MIME=model/fbx ;;
    wav) echo "ERROR: Roblox audio upload accepts only .mp3/.ogg — convert first (ffmpeg -i in.wav out.ogg)" >&2; exit 2 ;;
    *) echo "ERROR: unsupported extension .$ext (mp3, ogg, png, jpg, jpeg, bmp, tga, fbx)" >&2; exit 2 ;;
esac

REQUEST=$(printf '{"assetType":"%s","displayName":"%s","description":"Uploaded via roblox-upload skill","creationContext":{"creator":{"%s":%s}}}' \
    "$TYPE" "$NAME" "$ROBLOX_CREATOR_TYPE" "$ROBLOX_CREATOR_ID")

echo "Uploading $FILE as $TYPE \"$NAME\" (creator $ROBLOX_CREATOR_TYPE=$ROBLOX_CREATOR_ID)..."
RESPONSE=$(curl -sS -X POST "$API/assets" \
    -H "x-api-key: $ROBLOX_API_KEY" \
    -F "request=$REQUEST;type=application/json" \
    -F "fileContent=@$FILE;type=$MIME")

OP=$(printf '%s' "$RESPONSE" | json_get path)
if [ -z "$OP" ]; then
    echo "Upload request failed:" >&2
    printf '%s\n' "$RESPONSE" >&2
    exit 1
fi
echo "Operation: $OP — polling moderation..."
poll_operation "$OP"
