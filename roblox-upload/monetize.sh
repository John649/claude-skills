#!/usr/bin/env bash
# Create or list developer products and game passes via Open Cloud (Beta APIs).
#
#   monetize.sh devproduct <universeId> <name> <price> [description]
#   monetize.sh gamepass   <universeId> <name> <price> [description]
#   monetize.sh list-devproducts <universeId>
#   monetize.sh list-gamepasses  <universeId>
#
# Reads ROBLOX_API_KEY from config.env next to this script. The API key must
# have the developer-products / game-passes API systems enabled with write
# (read for the list commands). Prints DEV_PRODUCT_ID=<id> or GAME_PASS_ID=<id>
# on success. Endpoints are marked Beta by Roblox and may change.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$DIR/config.env"
[ -f "$CONFIG" ] || { echo "ERROR: $CONFIG missing — see SKILL.md setup section" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONFIG"
: "${ROBLOX_API_KEY:?config.env must set ROBLOX_API_KEY}"

API="https://apis.roblox.com"

json_get() { # json_get <key> — reads stdin, first match
    if command -v jq >/dev/null 2>&1; then
        jq -r "..|.\"$1\"? // empty" 2>/dev/null | head -1
    else
        sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\{0,1\}\([^\",}]*\)\"\{0,1\}.*/\1/p" | head -1
    fi
}

CMD="${1:-}"
UNIVERSE="${2:-}"
[ -n "$CMD" ] && [ -n "$UNIVERSE" ] || {
    echo "usage: monetize.sh devproduct|gamepass|list-devproducts|list-gamepasses <universeId> [...]" >&2
    exit 2
}

create() { # create <url> <idField> <name> <price> <description>
    local url="$1" id_field="$2" name="$3" price="$4" desc="$5" response id
    response=$(curl -sS -X POST "$url" \
        -H "x-api-key: $ROBLOX_API_KEY" \
        -F "name=$name" \
        -F "price=$price" \
        -F "description=$desc" \
        -F "isForSale=true")
    id=$(printf '%s' "$response" | json_get "$id_field")
    if [ -z "$id" ]; then
        # Some deployments of these Beta endpoints want JSON instead of form data.
        response=$(curl -sS -X POST "$url" \
            -H "x-api-key: $ROBLOX_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"$name\",\"price\":$price,\"description\":\"$desc\",\"isForSale\":true}")
        id=$(printf '%s' "$response" | json_get "$id_field")
    fi
    if [ -z "$id" ]; then
        echo "Create failed:" >&2
        printf '%s\n' "$response" >&2
        return 1
    fi
    printf '%s\n' "$response"
    echo "${6}=${id}"
}

case "$CMD" in
    devproduct)
        NAME="${3:?name required}"; PRICE="${4:?price (Robux) required}"; DESC="${5:-}"
        create "$API/developer-products/v2/universes/$UNIVERSE/developer-products" \
            "productId" "$NAME" "$PRICE" "$DESC" "DEV_PRODUCT_ID" \
        || create "$API/developer-products/v2/universes/$UNIVERSE/developer-products" \
            "id" "$NAME" "$PRICE" "$DESC" "DEV_PRODUCT_ID"
        ;;
    gamepass)
        NAME="${3:?name required}"; PRICE="${4:?price (Robux) required}"; DESC="${5:-}"
        create "$API/game-passes/v1/universes/$UNIVERSE/game-passes" \
            "gamePassId" "$NAME" "$PRICE" "$DESC" "GAME_PASS_ID" \
        || create "$API/game-passes/v1/universes/$UNIVERSE/game-passes" \
            "id" "$NAME" "$PRICE" "$DESC" "GAME_PASS_ID"
        ;;
    list-devproducts)
        curl -sS -H "x-api-key: $ROBLOX_API_KEY" \
            "$API/developer-products/v2/universes/$UNIVERSE/developer-products/creator"
        echo
        ;;
    list-gamepasses)
        curl -sS -H "x-api-key: $ROBLOX_API_KEY" \
            "$API/game-passes/v1/universes/$UNIVERSE/game-passes/creator"
        echo
        ;;
    *)
        echo "unknown command: $CMD" >&2
        exit 2
        ;;
esac
