# vps-tools

Scripts de administración para VPS Ubuntu/Debian.

## Instalación rápida

```bash
sudo bash install.sh
```

El instalador solicita el email de destino, cuenta Gmail y App Password, y configura todo automáticamente.

## Scripts

### `install.sh`

Instala y configura todos los componentes de una vez:

1. Instala dependencias (`msmtp`, `mailutils`, `ca-certificates`)
2. Configura msmtp con Gmail (`/root/.msmtprc`)
3. Instala el script de actualización en `/usr/local/lib/vps-update/`
4. Crea la regla de logrotate en `/etc/logrotate.d/vps_update`
5. Registra el cron job (domingos a las 2:00 AM)
6. Envía un email de prueba opcional

---

### `update_vps.sh`

Actualiza el sistema y notifica por email al terminar.

```bash
sudo bash update_vps.sh
```

Ejecuta `apt-get update`, `upgrade`, `autoremove` y `autoclean`. Envía un email con el log completo al finalizar. El asunto indica el resultado:

| Asunto | Significado |
|---|---|
| `[OK]` | Actualización exitosa |
| `[OK + REINICIO]` | Exitosa, pero requiere reinicio |
| `[FALLO]` | Un comando falló — incluye el log hasta el error |

Tras la instalación se ejecuta automáticamente cada domingo a las 2:00 AM vía cron.

---

### `large_files.py`

Lista los archivos más grandes de un directorio.

```bash
python3 large_files.py [directorio] [cantidad] [--sort-by size|name]
```

| Argumento | Default | Descripción |
|---|---|---|
| `directorio` | `/var/log` | Directorio a analizar |
| `cantidad` | `20` | Número de archivos a mostrar |
| `--sort-by` | `size` | Ordenar por `size` o `name` |

**Ejemplos:**

```bash
python3 large_files.py
python3 large_files.py /var/log 10 --sort-by size
python3 large_files.py /var/log 10 --sort-by name
```

---

### `msmtp_setup.sh`

Configura msmtp con Gmail de forma interactiva (incluido en `install.sh`).

```bash
sudo bash msmtp_setup.sh
```

Requiere un [App Password de Google](https://myaccount.google.com/apppasswords) — no acepta la contraseña normal de la cuenta.

---

## Archivos instalados

| Ruta | Descripción |
|---|---|
| `/usr/local/lib/vps-update/update_vps.sh` | Script de actualización |
| `/root/.msmtprc` | Credenciales Gmail (modo `600`) |
| `/etc/logrotate.d/vps_update` | Rotación semanal, 12 semanas de historial |
| `/var/log/vps_update.log` | Log de actualizaciones |
| `/var/log/msmtp.log` | Log de emails enviados |

## Requisitos

- Ubuntu / Debian
- Root o sudo
- Cuenta Gmail con [App Password](https://myaccount.google.com/apppasswords) habilitado (requiere 2FA activo)
