#!/bin/bash
set -euo pipefail

THRESHOLD=${1:-80}
EMAIL="quetzalx@gmail.com"
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
ALERT=0
REPORT=""

while IFS= read -r line; do
    USE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')

    if [ "$USE" -ge "$THRESHOLD" ]; then
        ALERT=1
        REPORT+="  [ALERTA] $MOUNT — ${USE}% usado\n"
    else
        REPORT+="  [OK]     $MOUNT — ${USE}% usado\n"
    fi
done < <(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x overlay | tail -n +2)

FULL_REPORT="[$DATE] Uso de disco en $HOSTNAME:\n\n$REPORT"

echo -e "$FULL_REPORT"

if [ "$ALERT" -eq 1 ]; then
    echo -e "$FULL_REPORT" | mail -s "[ALERTA] Disco al ${THRESHOLD}%+ en $HOSTNAME" "$EMAIL"
fi
