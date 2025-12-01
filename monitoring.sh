#!/usr/bin/bash

set -o pipefail
set -u

CONFIG_FILE="/m_app/monitoring.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "$(date -Is) конфигфайл $CONFIG_FILE не найден" 
  exit 1
fi
source "$CONFIG_FILE"

# функция для лога всего
log() {
  local level="$1"; shift
  local msg="$*"
  echo "$(date -Is) [${level}] ${msg}" >> "$LOG_FILE"
  logger -t monitoring "${level}: ${msg}"
}

if ! command -v curl >/dev/null 2>&1; then
  log "ERROR" "curl не найден Установите curl!!!"
  exit 2
fi

#Основной скрипт моноиторинга
while true; do

    http_code=""
    err=0
    # тут попытка продумать все возможные сценарии поведения сервиса веб приложения и попытки самовостановления,возможно чересчур
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$CURL_TIMEOUT" "$URL") || err=$?

    if (( err != 0 )); then

        log "WARN" "Ошибка при curl - exitcode: ${err} URL: ${URL}"
        log "INFO" "Авторестрат сервиса"
        systemctl restart http_app.service

        sleep 5

        tries=0
        success=false
        while (( tries < RETRY_AFTER_RESTART )); do
            tries=$((tries+1))
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$CURL_TIMEOUT" "$URL") || err=$?
            if [[ "$http_code" =~ ^2[0-9]{2}$ ]] || [[ "$http_code" =~ ^3[0-9]{2}$ ]]; then
                success=true
                break
            fi
        done
        if $success; then
            log "INFO" "После рестарта сервис отвечает (HTTP ${http_code})."
        else
            log "ERROR" "После рестарта сервис всё ещё недоступен ГГ, го некст\("
        fi

    elif [[ "$http_code" =~ ^2[0-9]{2}$ ]] || [[ "$http_code" =~ ^3[0-9]{2}$ ]]; then
        log "INFO" "${URL} returned HTTP ${http_code}"
    else
    
        log "INFO" "${URL} returned HTTP ${http_code}"
        log "INFO" "Авторестрат сервиса"
        systemctl restart http_app.service

        sleep 5

        tries=0
        success=false
        while (( tries < RETRY_AFTER_RESTART )); do
            tries=$((tries+1))
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$CURL_TIMEOUT" "$URL") || err=$?
            if [[ "$http_code" =~ ^2[0-9]{2}$ ]] || [[ "$http_code" =~ ^3[0-9]{2}$ ]]; then
                success=true
                break
            fi
        done
        if $success; then
            log "INFO" "После рестарта сервис отвечает (HTTP ${http_code})."
        else
            log "ERROR" "После рестарта сервис всё ещё недоступен ГГ, го некст\("
        fi
    fi

  sleep "$INTERVAL"
done
