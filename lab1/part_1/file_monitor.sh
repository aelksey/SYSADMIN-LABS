# Проверка наличия параметра (каталога для проверки)

# $# - number of arguments
# test $# -ne 1
# [] - test

if [ $# -ne 1 ]; then
    echo "Использование: $0 <каталог_для_проверки>"
    exit 1
fi

CHECK_DIR="$1"

# Проверка существования каталога
# test ! -d $CHECK_DIR
if [ ! -d "$CHECK_DIR" ]; then
    echo "Ошибка: Каталог $CHECK_DIR не существует"
    exit 1
fi

# Получаем имя пользователя
USER_NAME=$(whoami)

# Формируем имя файла отчета: имя пользователя + дата и время + .txt
REPORT_FILE="/tmp/${USER_NAME}_$(date +%Y%m%d_%H%M%S).txt"

# Файл для сохранения времени последней проверки в домашнем каталоге
LAST_CHECK_FILE="$HOME/.last_check_time"

# Получаем время последней проверки (если файл существует)
if [ -f "$LAST_CHECK_FILE" ]; then
    LAST_CHECK_TIME=$(cat "$LAST_CHECK_FILE")
else
    # Если проверка выполняется впервые, берем время 1 января 1970 года
    LAST_CHECK_TIME=0
fi

# Текущее время в секундах с эпохи Unix
# %s число секунд, истекших с 1970-01-01 00:00:00 UTC 
CURRENT_TIME=$(date +%s)

# Создаем файл отчета
touch "$REPORT_FILE"

# Рекурсивно ищем измененные файлы
# date -d строка
echo "Поиск файлов, измененных после $(date -d @$LAST_CHECK_TIME)" > "$REPORT_FILE"
echo "================================================" >> "$REPORT_FILE"

# Используем find для поиска файлов, измененных после LAST_CHECK_TIME
# -type f - ищем только файлы (не каталоги)
# -newerXt - сравнивает время модификации с указанной датой
find "$CHECK_DIR" -type f -newer "$LAST_CHECK_FILE" 2>/dev/null >> "$REPORT_FILE"

# Проверяем количество найденных файлов
# wc -l print the newline counts
FOUND_FILES=$(wc -l < "$REPORT_FILE")
FOUND_FILES=$((FOUND_FILES - 2))  # Вычитаем две строки заголовка


# test
# ЦЕЛОЕ1 -gt ЦЕЛОЕ2 ЦЕЛОЕ1 больше ЦЕЛОЕ2 
if [ $FOUND_FILES -gt 0 ]; then
    echo "================================================" >> "$REPORT_FILE"
    echo "Всего измененных файлов: $FOUND_FILES" >> "$REPORT_FILE"
    
    # Отправляем отчет по почте локальному пользователю
    mail -s "Отчет об измененных файлах в каталоге $CHECK_DIR" "$USER_NAME" < "$REPORT_FILE"
    
    # $? Returns status of last executed command 
    if [ $? -eq 0 ]; then
        echo "Отчет отправлен пользователю $USER_NAME"
    else
        echo "Ошибка при отправке отчета"
    fi
else
    echo "Измененных файлов не найдено"
fi

# Сохраняем время текущей проверки
echo "$CURRENT_TIME" > "$LAST_CHECK_FILE"

# Удаляем временный файл отчета
rm -f "$REPORT_FILE"

exit 0
