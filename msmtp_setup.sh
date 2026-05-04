#!/bin/bash
# Instala y configura msmtp para enviar emails via Gmail
set -euo pipefail

MSMTP_CONFIG="/root/.msmtprc"

read -p "Gmail (remitente): " GMAIL_USER
read -s -p "App Password de Google: " GMAIL_PASSWORD
echo

apt-get install -y -q msmtp msmtp-mta mailutils ca-certificates

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

echo "Enviando email de prueba..."
echo "msmtp configurado correctamente en $(hostname)." \
    | mail -s "[TEST] Configuración msmtp OK" quetzalx@gmail.com

echo "Listo. Revisa tu bandeja de entrada para confirmar."
