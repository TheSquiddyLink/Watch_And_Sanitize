#!/bin/bash
WATCH_DIR="/watch"

sanitize_name() {
    local f="$1"
    f="${f// /_}"
    f=$(echo "$f" | sed 's/[^A-Za-z0-9._-]//g')
    echo "$f"
}

is_stable() {
    local file="$1"
    local size1 size2
    size1=$(stat -c%s "$file" 2>/dev/null || echo 0)
    sleep 2
    size2=$(stat -c%s "$file" 2>/dev/null || echo 0)
    [[ "$size1" -eq "$size2" ]]
}

inotifywait -m -r -e create -e moved_to "$WATCH_DIR" --format '%w%f' |
while read -r FILE; do
    # Wait for file to finish writing
    for i in {1..10}; do
        if is_stable "$FILE"; then
            break
        fi
        sleep 1
    done

    # Sanitize and rename
    if [[ -f "$FILE" ]]; then
        DIR=$(dirname "$FILE")
        BASE=$(basename "$FILE")
        CLEAN=$(sanitize_name "$BASE")
        if [[ "$BASE" != "$CLEAN" ]]; then
            echo "Renaming: $BASE → $CLEAN"
            mv "$DIR/$BASE" "$DIR/$CLEAN"
        fi
    fi
done
