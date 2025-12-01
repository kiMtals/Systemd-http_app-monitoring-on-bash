#!/usr/bin/bash
set -euo pipefail

CONFIG_FILE="monitoring.conf"
source "$CONFIG_FILE"

# перенос файлов в рабочие папки/пути
if [[ ! -d "$APP_DIR" ]]; then
    mkdir -p "$APP_DIR"
fi
chmod 755 "$APP_DIR"
chown root:root "$APP_DIR"
cp ./app.py "$APP_DIR/app.py"
chmod +x "$APP_DIR/app.py"
cp ./monitoring.sh "$APP_DIR/monitoring.sh"
chmod +x "$APP_DIR/monitoring.sh"
cp ./http_app.service /etc/systemd/system/http_app.service
cp ./monitoring.service /etc/systemd/system/monitoring.service

cp monitoring.conf "$APP_DIR/$CONFIG_FILE"
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# запуск сервисов
systemctl daemon-reload
systemctl enable --now http_app.service
systemctl enable --now monitoring.service

systemctl status --no-pager http_app.service
systemctl status --no-pager monitoring.service
