#!/bin/bash

trap 'echo "$(date "+%Y-%m-%d %H:%M:%S") SIGINT - Попрошу не беспокоить, работа еще не сделана!" >> /tmp/workers/observer.log;' SIGINT
trap 'echo "$(date "+%Y-%m-%d %H:%M:%S") SIGQUIT - Попрошу не беспокоить, работа еще не сделана!" >> /tmp/workers/observer.log;' SIGQUIT

WORK_DIR="/tmp/workers"
RUN_DIR="$WORK_DIR/run"
CONF_FILE="$WORK_DIR/kafedra.conf"
LOG_FILE="$WORK_DIR/yakimenko.log"

mkdir -p "$WORK_DIR" "$RUN_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

find_pid_by_script() {
    local script_name="$1"
    for proc in /proc/[0-9]*; do
        if [ -f "$proc/cmdline" ]; then
            cmd=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null)
            for word in $cmd; do
                if [[ "$word" == *"$script_name" ]]; then
                    basename "$proc"
                    return 0
                fi
            done
        fi
    done
    return 1
}

if [ ! -f "$CONF_FILE" ]; then
    log "Критическая ошибка: Файл конфигурации $CONF_FILE не найден."
    exit 1
fi

START_TIME=$(date +%s)

while IFS= read -r worker_path; do
    [ -z "$worker_path" ] && continue
    worker_name=$(basename "$worker_path")
    
    pid=$(find_pid_by_script "$worker_name")
    
    if [ -z "$pid" ]; then
        log "Перезапуск: Процесс $worker_name не найден в системе."
        nohup "$worker_path" >/dev/null 2>&1 &
        log "Успешно запущен $worker_name с новым PID $!"
    else
        log "Процесс $worker_name (PID $pid) активен. Отправляем 'how much?'"
        fifo="$RUN_DIR/$pid.pid"
        reply_fifo="$RUN_DIR/${pid}_reply.pid"
        
        if [ -p "$fifo" ]; then
            echo "how much?" > "$fifo"
            if read -t 2 total remaining < "$reply_fifo" 2>/dev/null; then
                log "Ответ от $worker_name: исходное=$total, осталось=$remaining"
                threshold=$(( total * 70 / 100 ))
                if [ $remaining -lt $threshold ]; then
                    if [ $(( RANDOM % 10 )) -lt 3 ]; then
                        echo "work twice!" > "$fifo"
                        log "Отправлена команда 'work twice!' процессу $worker_name (PID $pid)"
                    else
                        log "Условие выполнено, но вероятность не сработала."
                    fi
                else
                    log "Оставшееся время ($remaining) >= 70% от исходного ($total)."
                fi
            else
                log "Не удалось получить ответ от $worker_name (таймаут или нет канала ответа)."
            fi
        else
            log "Канал процесса $worker_name ($fifo) не существует."
        fi
    fi
done < "$CONF_FILE"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))
if [ $ELAPSED -lt 59 ]; then
    SLEEP_TIME=$(( 59 - ELAPSED ))
    log "Скрипт выполнился за $ELAPSED сек. Сон на $SLEEP_TIME сек."
    sleep $SLEEP_TIME
else
    log "Скрипт выполнился за $ELAPSED сек."
fi

добавь коментарии в данный код чтобы студент или программист новичок могли обьяснить данный скрипт