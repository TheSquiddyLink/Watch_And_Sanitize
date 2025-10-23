#!/bin/bash
WATCH_DIR="/watch"

sanitize_name() {
    local f="$1"
    # Replace spaces with underscores
    f="${f// /_}"
    # Remove unwanted characters
    f=$(echo "$f" | sed 's/[^A-Za-z0-9._-]//g')
    echo "$f"
}

rename_item() {
    local ITEM="$1"
    local DIR=$(dirname "$ITEM")
    local BASE=$(basename "$ITEM")
    local CLEAN=$(sanitize_name "$BASE")

    if [[ "$BASE" != "$CLEAN" ]]; then
        echo "Renaming: $BASE → $CLEAN"
        mv "$DIR/$BASE" "$DIR/$CLEAN"
    fi
}

# Rename existing items, deepest first
find "$WATCH_DIR" -depth -mindepth 1 -print0 | while IFS= read -r -d '' ITEM; do
    rename_item "$ITEM"
done

# Watch for new items
inotifywait -m -r -e close_write -e create -e moved_to --format '%w%f' "$WATCH_DIR" | while read -r ITEM; do
    if [[ -e "$ITEM" ]]; then
        # If it's a directory, rename contents first
        if [[ -d "$ITEM" ]]; then
            find "$ITEM" -depth -mindepth 1 -print0 | while IFS= read -r -d '' SUBITEM; do
                rename_item "$SUBITEM"
            done
        fi
        # Then rename the item itself (file or folder)
        rename_item "$ITEM"
    fi
done
