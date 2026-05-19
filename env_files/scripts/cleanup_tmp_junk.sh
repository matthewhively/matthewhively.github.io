#!/bin/bash

set -euo pipefail

LOG_FILE="$HOME/cron_log/cleanup_tmp_junk.log"
touch $LOG_FILE

date '+%Y-%m-%d %H:%M:%S' >> $LOG_FILE

# Find files older than 24 hours and iterate safely
find -L /tmp -maxdepth 1 -type s -name 'zeb_def_ipc_*' -mtime +1 -print0 |
while IFS= read -r -d '' file; do
  # Skip if currently in use
  if lsof -- "$file" >/dev/null 2>&1; then
    echo "SKIP in use: $file" >> $LOG_FILE
    continue
  fi

  rm -f -- "$file"
  echo "DELETE $file" >> $LOG_FILE
done

echo >> $LOG_FILE
echo >> $LOG_FILE
