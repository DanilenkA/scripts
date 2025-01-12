#!/bin/bash

LOG_TAG="MONGO_BACKUP_SCRIPT"

log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    logger -t "$LOG_TAG" -p "user.$LEVEL" "$MESSAGE"
    echo "$(date +"%F %T") [$LEVEL] $MESSAGE"
}
if ! command -v mongodump &> /dev/null; then
    log "err" "mongodump is not installed or not in PATH. Please install it."
    exit 1
fi
if ! command -v gzip &> /dev/null; then
    log "err" "gzip is not installed or not in PATH. Please install it."
    exit 1
fi
MONGO_HOST="%mongo_host%"
MONGO_PORT="27017"
MONGO_USER="%mongo_user%"
MONGO_PASSWORD="%mongo_password%"
MONGO_AUTH_DB="admin"
BACKUP_DIR="%backup_path%"
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
BACKUP_FILE="$BACKUP_DIR/mongo-backup-$TIMESTAMP.archive"
COMPRESSED_FILE="$BACKUP_FILE.gz"

log "info" "Starting MongoDB backup from $MONGO_HOST:$MONGO_PORT"

mongodump --host="$MONGO_HOST" --port="$MONGO_PORT" --username="$MONGO_USER" --password="$MONGO_PASSWORD" --authenticationDatabase="$MONGO_AUTH_DB" --archive="$BACKUP_FILE"
if [ $? -ne 0 ]; then
    log "err" "Failed to create MongoDB backup: $BACKUP_FILE"
    exit 1
fi
log "info" "MongoDB backup created: $BACKUP_FILE"

gzip "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    log "err" "Failed to compress MongoDB backup: $BACKUP_FILE"
    exit 1
fi
log "info" "Backup compressed: $COMPRESSED_FILE"

log "info" "MongoDB backup completed successfully"
