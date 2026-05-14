1) Подключимся к серверу для 4-ой лабораторной работы:

```ssh avt341-v9@217.71.138.1 -p 55777```
```k5ioyyAO8cR6```

```ssh tech@172.16.8.169```
```rebustubus```

```mkdir -p ~/lab4```
```cd ~/lab4```


2) Сменим пользователя на root

```su -```
```rebustubus```

2) Создадим скрипт на языке bash с именем ```template_worker.sh```:

```touch template_worker.sh```
```vi template_worker.sh```
```chmod +x template_worker.sh```

3) Создадим скрипт на языке bash с именем ```yakimenko.sh```:


```touch yakimenko.sh```
```vi yakimenko.sh```
```chmod +x yakimenko.sh```

4) Настройте запуск yakimenko.sh посредством cron по расписанию – 1 раз в минуту, если работа сделана менее чем за 59 секунд – оставшееся время спите. 

```crontab -e```
```* * * * * ~/lab4/yakimenko.sh```
``` crontab -l```

5)	Скопируйте template_task.sh несколько раз с разными именами с префиксом worker_, добавьте их имена, указав полный путь до файла, в файл конфигурации kafedra.conf.

```
for i in 1 2 3 4 5; do
    cp template_worker.sh worker_$i.sh
    chmod +x worker_$i.sh
done
```

```
# cat > /tmp/workers/kafedra.conf — перенаправляет поток вывода команды cat прямо в указанный файл. Если файл существовал, он будет полностью перезаписан.
# <<EOF — указывает интерпретатору Bash, что нужно считывать весь последующий текст как входные данные для cat до тех пор, пока не встретится строка, состоящая только из слова EOF (End Of File).

cat > /tmp/workers/kafedra.conf <<EOF
/root/lab4/worker_1.sh
/root/lab4/worker_2.sh
/root/lab4/worker_3.sh
/root/lab4/worker_4.sh
/root/lab4/worker_5.sh
EOF
```

6.	Запустите процесс и соберите статистику работы (включая попытки отправить SIGINT и SIGQUIT)  в виде набора файлов report_*.log, yakimenko.log, kafedra.conf, приложите их вместе с исходными текстами скриптов в качестве отчета в виде сжатого архива ИМЯ_БРИГАДЫ-lab4.tar.gz и загрузите его в DiSpace3, запаковав в zip. Не забудьте остановить процесс, удалив задачу в cron!

Для проверки обработчиков сигналов найдите PID процесса yakimenko.sh:

``` pgrep -f yakimenko.sh ```

Отправьте ему SIGINT или SIGQUIT:

```
kill -INT <PID>
kill -QUIT <PID>
```

kill -INT 858590

kill -QUIT 855754


Reset all:

pkill -f worker_
rm -rf /tmp/workers
mkdir -p /tmp/workers

cat > /tmp/workers/kafedra.conf <<EOF
/root/lab4/worker_1.sh
/root/lab4/worker_2.sh
/root/lab4/worker_3.sh
/root/lab4/worker_4.sh
/root/lab4/worker_5.sh
EOF




for i in 1 2 3 4 5; do
    cp template_worker.sh worker_$i.sh
done
chmod +x worker_*.sh