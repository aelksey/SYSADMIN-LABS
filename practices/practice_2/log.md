
*Check distro*

cat /etc/os-release

practice_1_os=CentOS release 6.10 (Final)
practice_2_os=Ubuntu 22.04.4 LTS

hostname=sysadm-practice2-avt341-9

I) На сервере для первого практического занятия выполнить монтирование каталогов /etc/snmp /var/log в каталоге /srv/nfs/ с использованием опции bind команды mount.

Сначала создаем структуру каталогов, которая станет "корнем" экспорта NFSv4, и подключаем в неё нужные папки с помощью mount --bind:

1) Создаём целевую директорию:

```sudo mkdir -p /srv/nfs```

2) Создаём точки монтирования для snmp и log:

```
sudo mkdir -p /srv/nfs/snmp
sudo mkdir -p /srv/nfs/log
sudo chmod 777 /srv/nfs/snmp/
```

3) Выполним ```bind mount``` для подключения системных папок в структуру /srv/nfs:

```
# Привязываем /etc/snmp (исходник) к /srv/nfs/snmp (цель)
sudo mount --bind /etc/snmp /srv/nfs/snmp
sudo mount --bind /var/log /srv/nfs/log
```

4) Чтобы каталоги оставались смонтированы после перезагрузки, добавим записи в /etc/fstab:

```
sudo vi /etc/fstab
```

```
/etc/snmp    /srv/nfs/snmp    none    bind    0 0
/var/log     /srv/nfs/log     none    bind    0 0
```

5) Проверим что каталогм смонтированы:

``` mount | grep bind ```

Вывод:

```
/etc/snmp on /srv/nfs/snmp type none (rw,bind)
/var/log on /srv/nfs/log type none (rw,bind)
```

II)	Установить службу NFS v4 на сервере для первого практического  занятия, экспортировать через протокол NFS v4  каталог /srv/nfs/snmp в режиме «чтение и запись» и каталог /srv/nfs/log в режиме «только чтение» для адреса сервера второй практики.

6) Установим пакет nfs-utils на сервере для первого практического занятия:

```
sudo yum install nfs-utils
sudo service rpcbind start
sudo service nfs start
```

7) Отредактируем файл экспорта /etc/exports:

```sudo vi /etc/exports```

Добавим следующие строки:

```
/srv/nfs        172.16.8.169(rw,sync,fsid=0,no_subtree_check,insecure)
/srv/nfs/snmp   172.16.8.169(rw,sync,no_subtree_check,insecure)
/srv/nfs/log    172.16.8.169(ro,sync,no_subtree_check,insecure)
```

Применим конфигурацию и перезапустим сервис:

```
# Применяет изменения из /etc/exports
sudo exportfs -arv     
```

III) Ограничить доступ к портам службы rpcbind на сервере для первой практики, разрешив доступ только для ip адреса сервера второй практики и запретив для прочих используя firewall (не забудьте разрешить доступ по ssh).

8) Разрешим доступ по SSH для IP-адреса второй практики:

```sudo iptables -I INPUT -s 172.16.8.169 -p tcp --dport 22 -j ACCEPT``` 

9) Разрешим rpcbind (порт 111) ТОЛЬКО для сервера второй практики:

```
# Разрешить TCP-доступ к порту 111 с IP 172.16.8.169
sudo iptables -A INPUT -s 172.16.8.169 -p tcp --dport 111 -j ACCEPT
# Разрешить UDP-доступ к порту 111 с IP 172.16.8.169
sudo iptables -A INPUT -s 172.16.8.169 -p udp --dport 111 -j ACCEPT
```

10) Разрешить NFSv4 (порт 2049) для IP-адреса второй практики:

``` sudo iptables -A INPUT -s 172.16.8.169 -p tcp --dport 2049 -j ACCEPT ```

11) Запретим rpcbind (порт 111) для ВСЕХ остальных:

```
# Запретить TCP-доступ к порту 111 для всех прочих адресов
sudo iptables -A INPUT -p tcp --dport 111 -j DROP
# Запретить UDP-доступ к порту 111 для всех прочих адресов
sudo iptables -A INPUT -p udp --dport 111 -j DROP
```

12) Сохраним правила:

``` sudo service iptables save ```

13) Перезапустим iptables:

``` sudo service iptables restart ```

14) Убедимся что правила применились:

``` sudo iptables -S ```

Вывод:

```
-P INPUT ACCEPT
-P FORWARD ACCEPT
-P OUTPUT ACCEPT
-A INPUT -s 172.16.8.169/32 -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A INPUT -s 172.16.8.169/32 -p tcp -m tcp --dport 111 -j ACCEPT
-A INPUT -s 172.16.8.169/32 -p udp -m udp --dport 111 -j ACCEPT
-A INPUT -p tcp -m tcp --dport 111 -j DROP
-A INPUT -p udp -m udp --dport 111 -j DROP
-A INPUT -s 172.16.8.169/32 -p tcp -m tcp --dport 2049 -j ACCEPT
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
```

IV)	Выполнить на сервере для второй практики с использованием клиента протокола NFS v4 монтирование в каталог /mnt/${srv_practice1}/snmp каталога /srv/nfs/snmp с сервера для первой практики, и, аналогично, в каталог /mnt/${srv_practice1}/log  выполнить монтирование каталога /srv/nfs/log. Значение переменной выше по тексту замените на имя сервера для первой практики, выяснив его при помощи команды hostname.

${srv_practice1} = sysadm-practice-avt341-9

1) Установим утилиту nfs-common:

```sudo apt install nfs-common```

2) Создаём каталоги для монтирования:

```
sudo mkdir -p /mnt/sysadm-practice-avt341-9/snmp
sudo mkdir -p /mnt/sysadm-practice-avt341-9/log
```

3) Смонтируем каталоги:

Проверим подключение к nfs-серверу:

``` nc -zv 172.16.8.149 2049 ```

```
sudo mount -t nfs4 -o vers=4.0 172.16.8.149:/snmp /mnt/sysadm-practice-avt341-9/snmp
sudo mount -t nfs4 -o vers=4.0 172.16.8.149:/log /mnt/sysadm-practice-avt341-9/log
```

4) Проверим монтирование:

```
Должны увидеть файлы из /etc/snmp на сервере
ls -la /mnt/sysadm-practice-avt341-9/snmp
Должны увидеть файлы из /var/log на сервере   
ls -la /mnt/sysadm-practice-avt341-9/log    

Проверка записи в snmp (должно быть успешно)
touch /mnt/sysadm-practice-avt341-9/snmp/test_from_ubuntu.txt

Проверка только чтения для log (должна быть ошибка)
touch /mnt/sysadm-practice-avt341-9/log/test.txt
Ожидаемый результат: touch: cannot touch '...': Read-only file system
```

5) Добавим запись в /etc/fstab чтобы монтирование восстанавливалось после ребута:

``` sudo vi /etc/fstab ```

Добавим:

```
172.16.8.149:/snmp   /mnt/sysadm-practice-avt341-9/snmp   nfs   vers=4.0,_netdev   0 0
172.16.8.149:/log    /mnt/sysadm-practice-avt341-9/log    nfs   vers=4.0,_netdev,ro   0 0
```

V) Убедиться в доступности файлов для чтения и записи в смонтированных каталогах на сервере для второй практики, в том числе после перезагрузки серверов для первой и второй практики, доступность должна восстанавливаться автоматически.

Перезагрузим оба сервера:

``` sudo reboot ```

VI) Завершить процесс документирования, дополнить документацию необходимыми комментариями и подробным описанием всех встреченных в процессе сложностей. Допустимые форматы отчета: docx, pdf. Индивидуальный отчет после защиты загрузить в DiSpace3 (1 экземпляр от бригады).