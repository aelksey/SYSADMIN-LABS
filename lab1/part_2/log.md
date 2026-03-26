
1) Создать в домашнем каталоге каталог sysadm_lab_1_2, все результаты сохранять в данном каталоге, включая файл command.list со строками команд для каждого последующего пункта задания, файл должен быть исполняемым

```
mkdir ~/sysadm_lab_1_2
cd ~/sysadm_lab_1_2
touch command.list
chmod +x command.list
```

2) Найти в файле количество запросов, поступивших от агента поискового робота Yandex

```
grep -c "YandexBot" /opt/access.log
```

```
108
```

3) Найти в файле все запросы  к страницам, расположенным в домашнем каталоге Малявко А.А. (начинающихся с /~malyavko) и завершившихся с кодом, отличным от 2XX, где X – произвольная цифра. Результат сохранить в файл malyavko_miss.log

```
grep "/~malyavko" /opt/access.log | grep -v " HTTP/[0-9.]\" [2][0-9][0-9] " > malyavko_miss.log
```

```
cat malyavko_miss.log
```

4) Для запросов к страницам, расположенным в домашнем каталоге Малявко А.А., завершившихся с кодом 200 найти все уникальные URL запросов, отсортировать их по убыванию длины ответа и сохранить первые 10 в файл  malyavko_top.log в формате: "запрос" длина

```
grep "/~malyavko" /opt/access.log | grep " 200 " | while read line; do
    # Извлекаем URL (поле 7)
    url=$(echo "$line" | awk '{print $7}')
    
    # Извлекаем длину (поле 10, потому что код ответа в поле 9)
    length=$(echo "$line" | awk '{print $10}')
    
    # Проверяем, что длина - число
    if [[ "$length" =~ ^[0-9]+$ ]]; then
        echo "$url $length"
    fi
done | sort -k2 -rn | head -10 > malyavko_top.log
```

```
cat malyavko_top.log
```

5) Найти в файле все запросы, выполненные в диапазоне времени от 21:00 до 8:29 включительно с понедельника по субботу и сохранить их в файле request_night.log

```
# Используем grep для предварительной фильтрации по датам
grep -E "10/Feb/2025|11/Feb/2025|12/Feb/2025|13/Feb/2025|14/Feb/2025|15/Feb/2025" /opt/access.log | while read line; do
    # Извлекаем время
    hour=$(echo "$line" | awk '{print $5}' | cut -d':' -f1 | tr -d ']')
    min=$(echo "$line" | awk '{print $5}' | cut -d':' -f2)
    
    # Проверяем время
    if [ "$hour" -ge 21 ] 2>/dev/null || [ "$hour" -le 8 ] 2>/dev/null; then
        if [ "$hour" -eq 8 ] 2>/dev/null; then
            if [ "$min" -le 29 ] 2>/dev/null; then
                echo "$line" >> request_night.log
            fi
        elif [ "$hour" -ge 21 ] 2>/dev/null || [ "$hour" -le 7 ] 2>/dev/null; then
            echo "$line" >> request_night.log
        fi
    fi
done
```

```
cat request_night.log
```

6) Найти в файле все уникальные адреса, от которых поступили запросы, подсчитать для каждого адреса количество повторений и сохранить их в файле fromhosts.log, заменив, где это возможно, ip-адрес на соответствующее ему dns-имя (команда host) в формате: {количество_повторений} – {адрес или dns-имя}, список упорядочить в первую очередь по 1, затем по 3 столбцу. {} – не включаются в отчёт

```
# Очищаем выходной файл перед началом
> fromhosts.log

# Получаем уникальные IP с подсчетом
awk '{print $1}' /opt/access.log | sort | uniq -c | sort -rn | while read count ip; do
    # Получаем DNS имя
    dns=$(getent hosts $ip 2>/dev/null | awk '{print $2}' | head -1)
    
    # Сразу записываем результат в файл
    if [ -n "$dns" ]; then
        echo "$count -- $dns" >> fromhosts.log
    else
        echo "$count -- $ip" >> fromhosts.log
    fi
    
    # Показываем прогресс
    echo "Обработан: $ip -> ${dns:-$ip}"
done

# Финальная сортировка 
sort -k1 -rn -k3 -o fromhosts.log fromhosts.log

echo "Готово. Результат в fromhosts.log"
```


7) Найти в фале все уникальные URL запросов, завершившихся с кодом 4XX, записать в файл fail.log, отсортированном в обратном порядке

```
awk '{
    # Проверяем, что код ответа (9-е поле) начинается с 4
    if ($9 ~ /^4[0-9][0-9]$/) {
        # Выводим URL (7-е поле)
        print $7
    }
}' /opt/access.log | sort -u | sort -r > fail.log
```

# Упаковка результатов
echo "=================================="
echo "Упаковка результатов..."
cd ~
tar -cf "$USER-lab-1-2.tar" ~/sysadm_lab_1_2 && gzip "$USER-lab-1-2.tar"
echo "Архив создан: $USER-lab-1-2.tar.gz"

echo "Лабораторная работа выполнена!"