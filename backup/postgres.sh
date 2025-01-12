#!/bin/bash

LOG_TAG="POSTGRES_BACKUP_SCRIPT"

log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    logger -t "$LOG_TAG" -p "user.$LEVEL" "$MESSAGE"
    echo "$(date +"%F %T") [$LEVEL] $MESSAGE"
}
if ! command -v pg_basebackup &> /dev/null; then
    log "err" "pg_basebackup is not installed or not in PATH. Please install it."
    exit 1
fi
PG_HOST="%pg_host%"
PG_PORT="5432"
PG_USER="%user%"
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
TEMP_BACKUP_DIR="$BACKUP_DIR/temp-backup"
ARCHIVE_FILE="$BACKUP_DIR/postgres-backup-$TIMESTAMP.tar"

log "info" "Starting PostgreSQL backup from $PG_HOST:$PG_PORT"

pg_basebackup -P -R -X stream -c fast -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -D "$TEMP_BACKUP_DIR"
if [ $? -ne 0 ]; then
    log "err" "Failed to create PostgreSQL base backup at: $TEMP_BACKUP_DIR"
    exit 1
fi
log "info" "PostgreSQL base backup created: $TEMP_BACKUP_DIR"
tar -cvf "$ARCHIVE_FILE" "$TEMP_BACKUP_DIR"
if [ $? -ne 0 ]; then
    log "err" "Failed to create archive file: $ARCHIVE_FILE"
    exit 1
fi
log "info" "Backup archived: $ARCHIVE_FILE"

rm -rf "$TEMP_BACKUP_DIR"
if [ $? -ne 0 ]; then
    log "warn" "Failed to remove temporary backup directory: $TEMP_BACKUP_DIR"
else
    log "info" "Temporary backup directory removed: $TEMP_BACKUP_DIR"
fi

log "info" "PostgreSQL backup completed successfully"
