#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/local/lib/vps-update"
UPDATE_SCRIPT="$INSTALL_DIR/update_vps.sh"
LOGROTATE_CONF="/etc/logrotate.d/vps_update"
MSMTP_CONFIG="/root/.msmtprc"
CRON_ENTRY="0 2 * * 0 $UPDATE_SCRIPT >> /var/log/vps_update.log 2>&1"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

[ "$EUID" -eq 0 ] || die "Ejecuta este script como root."

echo "========================================"
echo "  Instalador de actualización automática"
echo "========================================"
echo

# --- Datos del usuario ---
read -p "Email destino para notificaciones: " NOTIFY_EMAIL
read -p "Gmail remitente (cuenta de envío):  " GMAIL_USER
read -s -p "App Password de Google:             " GMAIL_PASSWORD
echo
echo

# --- Dependencias ---
echo "Instalando dependencias..."
apt-get update -q
apt-get install -y -q msmtp msmtp-mta mailutils ca-certificates
ok "Dependencias instaladas."

# --- msmtp ---
cat > "$MSMTP_CONFIG" <<EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           $GMAIL_USER
user           $GMAIL_USER
password       $GMAIL_PASSWORD

account default: gmail
EOF
chmod 600 "$MSMTP_CONFIG"
ok "msmtp configurado en $MSMTP_CONFIG."

# --- Script de actualización ---
mkdir -p "$INSTALL_DIR"
cat > "$UPDATE_SCRIPT" <<SCRIPT
#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/vps_update.log"
EMAIL="$NOTIFY_EMAIL"
HOSTNAME=\$(hostname)
DATE=\$(date '+%Y-%m-%d %H:%M:%S')
TEMP_LOG=\$(mktemp)

log() {
    echo "[\$DATE] \$*" | tee -a "\$LOG_FILE" >> "\$TEMP_LOG"
}

send_email() {
    echo "\$2" | mail -s "\$1" "\$EMAIL"
}

trap 'send_email "[FALLO] Actualización de \$HOSTNAME" "\$(cat \$TEMP_LOG)"; rm -f "\$TEMP_LOG"' ERR

log "=== Inicio de actualización ==="

apt-get update -q 2>&1 | tee -a "\$LOG_FILE" >> "\$TEMP_LOG"
apt-get upgrade -y -q 2>&1 | tee -a "\$LOG_FILE" >> "\$TEMP_LOG"
apt-get autoremove -y -q 2>&1 | tee -a "\$LOG_FILE" >> "\$TEMP_LOG"
apt-get autoclean -q 2>&1 | tee -a "\$LOG_FILE" >> "\$TEMP_LOG"

REBOOT_MSG=""
if [ -f /var/run/reboot-required ]; then
    REBOOT_MSG="AVISO: Se requiere reinicio para completar las actualizaciones."
    log "\$REBOOT_MSG"
fi

log "=== Actualización completada ==="

SUBJECT="[OK] Actualización de \$HOSTNAME — \$DATE"
[ -n "\$REBOOT_MSG" ] && SUBJECT="[OK + REINICIO] Actualización de \$HOSTNAME — \$DATE"

send_email "\$SUBJECT" "\$(cat \$TEMP_LOG)"
rm -f "\$TEMP_LOG"
SCRIPT
chmod 750 "$UPDATE_SCRIPT"
ok "Script de actualización instalado en $UPDATE_SCRIPT."

# --- Logrotate ---
cat > "$LOGROTATE_CONF" <<EOF
/var/log/vps_update.log {
    su root root
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
EOF
ok "Logrotate configurado en $LOGROTATE_CONF."

# --- Cron job ---
if crontab -l 2>/dev/null | grep -qF "$UPDATE_SCRIPT"; then
    warn "El cron job ya existía, se omite."
else
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    ok "Cron job registrado (domingos a las 2:00 AM)."
fi

# --- Email de prueba ---
echo
read -p "¿Enviar email de prueba ahora? [s/N]: " TEST_EMAIL
if [[ "${TEST_EMAIL,,}" == "s" ]]; then
    echo "Instalación completada en $(hostname)." \
        | mail -s "[TEST] vps-update instalado correctamente" "$NOTIFY_EMAIL"
    ok "Email de prueba enviado a $NOTIFY_EMAIL."
fi

echo
echo "========================================"
ok "Instalación completada."
echo "  Script:    $UPDATE_SCRIPT"
echo "  Logs:      /var/log/vps_update.log"
echo "  Cron:      domingos 02:00 AM"
echo "  Email:     $NOTIFY_EMAIL"
echo "========================================"
