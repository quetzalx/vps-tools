#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/vps_update.log"
EMAIL="quetzalx@gmail.com"
HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')
TEMP_LOG=$(mktemp)

log() {
    echo "[$DATE] $*" | tee -a "$LOG_FILE" >> "$TEMP_LOG"
}

send_email() {
    local subject="$1"
    local body="$2"
    echo "$body" | mail -s "$subject" "$EMAIL"
}

trap 'send_email "[FALLO] Actualización de $HOSTNAME" "$(cat $TEMP_LOG)"; rm -f "$TEMP_LOG"' ERR

log "=== Inicio de actualización ==="

apt-get update -q 2>&1 | tee -a "$LOG_FILE" >> "$TEMP_LOG"
apt-get upgrade -y -q 2>&1 | tee -a "$LOG_FILE" >> "$TEMP_LOG"
apt-get autoremove -y -q 2>&1 | tee -a "$LOG_FILE" >> "$TEMP_LOG"
apt-get autoclean -q 2>&1 | tee -a "$LOG_FILE" >> "$TEMP_LOG"

REBOOT_MSG=""
if [ -f /var/run/reboot-required ]; then
    REBOOT_MSG="AVISO: Se requiere reinicio para completar las actualizaciones."
    log "$REBOOT_MSG"
fi

log "=== Actualización completada ==="

SUBJECT="[OK] Actualización de $HOSTNAME — $DATE"
[ -n "$REBOOT_MSG" ] && SUBJECT="[OK + REINICIO] Actualización de $HOSTNAME — $DATE"

send_email "$SUBJECT" "$(cat $TEMP_LOG)"
rm -f "$TEMP_LOG"
