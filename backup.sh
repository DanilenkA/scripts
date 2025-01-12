#!/bin/bash

LOG_TAG="DB_BACKUP_SCRIPT"

log() {
    local LEVEL="$1"
    local MESSAGE="$2"
    logger -t "$LOG_TAG" -p "user.$LEVEL" "$MESSAGE"
    echo "$(date +"%F %T") [$LEVEL] $MESSAGE"
}

# Check if sqlcmd is in the PATH
if ! command -v sqlcmd &> /dev/null; then
    log "err" "sqlcmd could not be found, please install it and ensure it's in your PATH."
    exit 1
fi

# Connection parameters
SERVER="%servername%"
USER="%username%"
PASSWORD="%password%"

# Directory for storing backups
BACKUP_DIR="%path%"

# Check available disk space
SPACE=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')
log "info" "Available space on backup directory: $SPACE"

# Verify if the backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    log "err" "Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

# Verify write permissions on the backup directory
if [ ! -w "$BACKUP_DIR" ]; then
    log "err" "Backup directory is not writable: $BACKUP_DIR"
    exit 1
fi

# Retrieve the list of databases, excluding system databases
DATABASES=$(sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -Q "SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')" -h -1 -W)

if [ -z "$DATABASES" ]; then
    log "warn" "No user databases found to back up."
    exit 0
fi

# Iterate over each database and create a backup
for DB in $DATABASES; do
    log "info" "Starting backup for database: $DB"

    # Directory for the current database
    DB_DIR="$BACKUP_DIR/$DB"

    # Create directory if it doesn't exist
    mkdir -p "$DB_DIR"

    # Path to the backup file
    BACKUP_FILE="$DB_DIR/${DB}_$(date +"%F_%T").bak"

    # Create the backup
    sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -Q "BACKUP DATABASE [$DB] TO DISK = N'$BACKUP_FILE' WITH NOFORMAT, NOINIT, COMPRESSION, NAME = '${DB}-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

    # Check the backup command status
    if [ $? -ne 0 ]; then
        log "err" "Backup failed for database: $DB"
        continue
    fi

    # Delete old backups, keeping only the three most recent
    ls -1t "$DB_DIR"/*.bak | tail -n +4 | xargs rm -f

    log "info" "Backup completed for database: $DB"
done

log "info" "All backups completed successfully."
