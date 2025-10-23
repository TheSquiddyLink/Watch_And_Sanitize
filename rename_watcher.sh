#!/bin/bash
WATCH_DIR="/watch"
LOG_FILE="/var/log/watch_rename.log"

touch "$LOG_FILE"

log() {
    local LEVEL="$1"
    local MSG="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $MSG" | tee -a "$LOG_FILE"
}

sanitize_name() {
    local f="$1"
    f="${f// /_}"
    f=$(echo "$f" | sed 's/[^A-Za-z0-9._-]//g')
    echo "$f"
}

rename_item() {
    local ITEM="$1"
    local DIR=$(dirname "$ITEM")
    local BASE=$(basename "$ITEM")
    local CLEAN=$(sanitize_name "$BASE")

    if [[ "$BASE" != "$CLEAN" ]]; then
        log "INFO" "Renaming: '$BASE' → '$CLEAN' in '$DIR'"
        if mv "$DIR/$BASE" "$DIR/$CLEAN"; then
            log "INFO" "Successfully renamed '$BASE' → '$CLEAN'"
        else
            log "ERROR" "Failed to rename '$BASE' → '$CLEAN'"
        fi
    fi
}

log "INFO" "Starting initial scan and rename of existing files in '$WATCH_DIR'"

find "$WATCH_DIR" -depth -mindepth 1 -print0 | while IFS= read -r -d '' ITEM; do
    rename_item "$ITEM"
done

log "INFO" "Watching '$WATCH_DIR' for new files and folders..."

inotifywait -m -r -e close_write -e create -e moved_to --format '%w%f' "$WATCH_DIR" | while read -r ITEM; do
    if [[ -d "$ITEM" ]]; then
        log "INFO" "New directory detected: '$ITEM'. Waiting for transfer to finish..."
        for i in {1..10}; do
            size1=$(du -sb "$ITEM" 2>/dev/null | cut -f1)
            sleep 2
            size2=$(du -sb "$ITEM" 2>/dev/null | cut -f1)
            [[ "$size1" -eq "$size2" ]] && break
        done
        find "$ITEM" -depth -mindepth 1 -print0 | while IFS= read -r -d '' SUBITEM; do
            rename_item "$SUBITEM"
        done
    fi
    rename_item "$ITEM"
    log "INFO" "Finished Renaming '$WATCH_DIR'" 
done




