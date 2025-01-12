#!/bin/bash
LOG_TAG="REDIS_BACKUP_SCRIPT"

log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    logger -t "$LOG_TAG" -p "user.$LEVEL" "$MESSAGE"
    echo "$(date +"%F %T") [$LEVEL] $MESSAGE"
}
if ! command -v redis-cli &> /dev/null; then
    log "err" "redis-cli is not installed or not in PATH. Please install it."
    exit 1
fi
REDIS_URI="redis://%url%:%port%"
BACKUP_DIR="%path%"
if [ ! -d "$BACKUP_DIR" ]; then
    log "warn" "Backup directory does not exist. Creating: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    if [ $? -ne 0 ]; then
        log "err" "Failed to create backup directory: $BACKUP_DIR"
        exit 1
    fi
fi
if [ ! -w "$BACKUP_DIR" ]; then
    log "err" "Backup directory is not writable: $BACKUP_DIR"
    exit 1
fi
TIMESTAMP=$(date +"%F_%T" | tr ':' '_')
BACKUP_FILE="$BACKUP_DIR/redis-dump-$TIMESTAMP.rdb"
COMPRESSED_FILE="$BACKUP_FILE.gz"

log "info" "Starting Redis backup from $REDIS_URI"
redis-cli -u "$REDIS_URI" --rdb "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    log "err" "Failed to create Redis dump file: $BACKUP_FILE"
    exit 1
fi
log "info" "Redis dump created: $BACKUP_FILE"
gzip "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    log "err" "Failed to compress Redis dump file: $BACKUP_FILE"
    exit 1
fi
log "info" "Compressed Redis dump created: $COMPRESSED_FILE"

log "info" "Redis backup completed successfully"
