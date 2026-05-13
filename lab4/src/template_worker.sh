#!/bin/bash

SCRIPT_NAME=$(basename "$0")
WORK_DIR="/tmp/workers"
RUN_DIR="$WORK_DIR/run"
REPORT_FILE="$WORK_DIR/report_${SCRIPT_NAME}.log"

mkdir -p "$RUN_DIR"

PID=$$
echo "[$PID] $(date '+%Y-%m-%d %H:%M:%S') К работе приступил" >> "$REPORT_FILE"

FIFO="$RUN_DIR/$PID.pid"
rm -f "$FIFO"
mkfifo "$FIFO"

TOTAL_TIME=$(( RANDOM % 541 + 60 )) 
REMAINING=$TOTAL_TIME
START_TIME=$(date +%s) 

log_msg() {
    echo "[$PID] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$REPORT_FILE"
}

exec 3<> "$FIFO"

while true; do
    if read -r cmd <&3; then
        cmd=$(echo "$cmd" | tr -d '\r')
        
        case "$cmd" in
            "how much?")
                echo "$TOTAL_TIME $REMAINING" >&3 &
                ;;
            "work twice!")
                REMAINING=$(( REMAINING * 2 ))
                log_msg "Да когда ж меня отпустят, я уже заполнил контрольные недели!"
                ;;
        esac
    fi
done &
READER_PID=$!

while [ $REMAINING -gt 0 ]; do
    sleep 1
    REMAINING=$(( REMAINING - 1 ))
done

kill $READER_PID 2>/dev/null
exec 3>&-

rm -f "$FIFO"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

MIN=$(( ELAPSED / 60 ))
SEC=$(( ELAPSED % 60 ))

log_msg "На сегодня работа завершена, работал $MIN минут и $SEC секунд"
