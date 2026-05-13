#!/bin/bash

WORK_DIR="/tmp/workers"
RUN_DIR="$WORK_DIR/run"
CONF_FILE="$WORK_DIR/kafedra.conf"
LOG_FILE="$WORK_DIR/yakimenko.log"
OBSERVER_LOG="$WORK_DIR/observer.log"


handle_signal() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') СИГНАЛ_$2 ($1) - Попрошу не беспокоить, работа еще не сделана!" >> "$OBSERVER_LOG"
}

trap 'handle_signal SIGINT 2' SIGINT
trap 'handle_signal SIGQUIT 3' SIGQUIT

mkdir -p "$WORK_DIR" "$RUN_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

if [ ! -f "$CONF_FILE" ]; then
    log "Критическая ошибка: Файл конфигурации $CONF_FILE не найден."
    exit 1
fi

while IFS= read -r worker_path || [ -n "$worker_path" ]; do
    # Игнорируем пустые строки и комментарии
    [[ -z "$worker_path" || "$worker_path" =~ ^# ]] && continue
    
    worker_name=$(basename "$worker_path")
    pid=""

    for proc in /proc/[0-9]*; do
        if [ -f "$proc/cmdline" ]; then
            cmd=$(tr '\0' ' ' < "$proc/cmdline" 2>/dev/null)
            current_pid=$(basename "$proc")
            
            if [[ "$cmd" == *"$worker_name"* && "$current_pid" -ne $$ ]]; then
                pid="$current_pid"
                break
            fi
        fi
    done

    if [ -z "$pid" ]; then
        log "Перезапуск: Процесс $worker_name не найден в системе."
        
        nohup "$worker_path" >/dev/null 2>&1 &
        
        log "Успешно запущен $worker_name с новым PID $!"
    else
        # Процесс найден и работает
        log "Анализ: Процесс $worker_name (PID $pid) активен."
        
        fifo="$RUN_DIR/$pid.pid"
        
        if [ -p "$fifo" ]; then
            exec 4<>"$fifo"
            
            echo "how much?" >&4
            
            if read -t 2 total remaining <&4; then
                log "Статус $worker_name: исходное=$total сек., осталось=$remaining сек."
                
                threshold=$(( total * 70 / 100 ))
                
                if [ "$remaining" -lt "$threshold" ]; then
                    if [ "$(awk -v p=0.3 'BEGIN{srand(); print (rand() < p) ? 1 : 0}')" -eq 1 ]; then
                        
                        echo "work twice!" >&4
                        
                        log "ОТПРАВЛЕНО 'work twice!' -> Процесс: $worker_name, ID: $pid (Остаток: $remaining из $total)"
                    else
                        log "Условие < 70% выполнено, но вероятность 0.3 не выпала для $worker_name ($pid)."
                    fi
                else
                    log "Процесс $worker_name ($pid) выполнил меньше 30% работы. Коррекция не требуется."
                fi
            else
                log "Ошибка: Не удалось прочитать ответ из канала процесса $worker_name (PID $pid) - Таймаут."
            fi
            
            exec 4>&-
        else
            log "Предупреждение: Файл канала $fifo отсутствует на диске."
        fi
    fi
done < "$CONF_FILE"

Добавь комментарии в данный код чтобы программист новичок или студент могли обьяснить этот скрипт преподавателю