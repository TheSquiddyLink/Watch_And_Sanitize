#!/bin/bash
WATCH_DIR="/watch"

sanitize_name() {
    local f="$1"
    f="${f// /_}"
    f=$(echo "$f" | sed 's/[^A-Za-z0-9._-]//g')
    echo "$f"
}

find "$WATCH_DIR" -depth -mindepth 1 | while read -r ITEM; do
    DIR=$(dirname "$ITEM")
    BASE=$(basename "$ITEM")
    CLEAN=$(sanitize_name "$BASE")
    if [[ "$BASE" != "$CLEAN" ]]; then
        echo "Renaming existing: $BASE → $CLEAN"
        mv "$DIR/$BASE" "$DIR/$CLEAN"
    fi
done

inotifywait -m -r -e create -e moved_to "$WATCH_DIR" --format '%w%f' |
while read -r FILE; do
    for i in {1..10}; do
        size1=$(stat -c%s "$FILE" 2>/dev/null || echo 0)
        sleep 2
        size2=$(stat -c%s "$FILE" 2>/dev/null || echo 0)
        [[ "$size1" -eq "$size2" ]] && break
    done

    if [[ -e "$FILE" ]]; then
        DIR=$(dirname "$FILE")
        BASE=$(basename "$FILE")
        CLEAN=$(sanitize_name "$BASE")
        if [[ "$BASE" != "$CLEAN" ]]; then
            echo "Renaming new: $BASE → $CLEAN"
            mv "$DIR/$BASE" "$DIR/$CLEAN"
        fi
    fi
done
