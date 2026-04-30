I) Установить и настроить iSCSI Target из пакета istgt на машине для второго практического занятия, создать и экспортировать 2 LUN по 512 МБ с доступом с паролем для пользователя c паролем из лабораторной работы №1
Для определения размещения устройств разделить номер бригады на 2 и найти остаток от деления:
		0 – RAM (в оперативной памяти, tmpfs)
		1 – block (на блочном устройстве, LVM)
		2 – file (в файле)
	При нехватке ресурсов  – запросить увеличение у преподавателя (память:  cat /proc/memory, блочные устройства: lslbk, место на дисках: df  -h)

1) Установка пакета tgt

``` sudo apt install tgt -y ```

![alt text](image.png)

2) Проверим статус сервиса

``` sudo systemctl status tgt ```

![alt text](image-1.png)

3) Создание первого LUN (512 МБ)
``` sudo lvcreate -L 512M -n iscsi_lun0 ubuntu-vg ```

![alt text](image-2.png)

4) Создание второго LUN (512 МБ)
``` sudo lvcreate -L 512M -n iscsi_lun1 ubuntu-vg ```

![alt text](image-3.png)

5) Проверим созданые LUN
``` sudo lvdisplay | grep -E "LV Name|LV Size" ```

![alt text](image-4.png)

6) Настройка Target и LUN. Редактируем файл конфигурации. В Ubuntu 22.04 tgt использует include директиву. Создадим отдельный файл для нашего target: 

``` sudo vi /etc/tgt/conf.d/iscsi-lab3.conf ```

Конфигурация:

```
# /etc/tgt/conf.d/iscsi-lab3.conf
<target iqn.2026-04.local.lab:storage.target1>
    incominguser root rebustubus
    initiator-address 172.16.8.149
    backing-store /dev/ubuntu-vg/iscsi_lun0
    backing-store /dev/ubuntu-vg/iscsi_lun1
</target>

```

7) Перезапустим службы для чтения конфигурации
``` sudo systemctl restart tgt ```

8) Проверим, что target активен
``` sudo systemctl status tgt ```

![alt text](image-5.png)

9) Просмотрим таргеты
``` tgtadm --mode target --op show ```

![alt text](image-6.png)

II) Настроить firewall для удаленного доступа к iSCSI Target на данной машине по сети.

# Выполняется на машине второй практики

1) Разрешаем iSCSI трафик с IP-адреса первой практики
``` 
sudo ufw allow from 172.16.8.149 to any port 3260 proto tcp comment 'iSCSI Target for Lab1' 
sudo ufw allow ssh
```

![alt text](image-7.png)

2) Включаем firewall on system starup

``` sudo ufw enable ```

![alt text](image-8.png)

3) Проверяем правила
``` sudo ufw status numbered ``` 

![alt text](image-9.png)

# Выполняется на машине первой практики

4) Установи iscsci на CentOS:

``` sudo yum install iscsi-initiator-utils -y ```

5) Запустим сервис iscsid

``` sudo service iscsid start ```

6) Включим автозагрузку сервиса

``` sudo chkconfig iscsid on ```

7) Проведём discovery в iscid:

``` iscsiadm -m discovery -t st -p 172.16.8.169 ```

![alt text](image-10.png)

8) Проведём login к targetу:

```
iscsiadm -m node -T iqn.2026-04.local.lab:storage.target1 -o update -n node.session.auth.authmethod -v CHAP
iscsiadm -m node -T iqn.2026-04.local.lab:storage.target1 -o update -n node.session.auth.username -v root
iscsiadm -m node -T iqn.2026-04.local.lab:storage.target1 -o update -n node.session.auth.password -v rebustubus
iscsiadm -m node -T iqn.2026-04.local.lab:storage.target1 -l
```
![alt text](image-11.png)

``` sudo iscsiadm -m session -o show ```

![alt text](image-12.png)

9) Проверим наличие блочных устройств по 512Мб

``` lsblk ```

![alt text](image-13.png)

III) Проверить работоспособность iSCSI Target из п.3, в том числе после перезагрузки машины.

1) Перезагрузим машину 

``` sudo reboot ```

2) Убедимся что LUN активны:

``` sudo lvdisplay | grep -E "LV Name|LV Size" ```

![alt text](image-14.png)

3) Проверим, что target активен
``` sudo systemctl status tgt ```

![alt text](image-15.png)

4) Просмотрим таргеты
``` tgtadm --mode target --op show ```

![alt text](image-16.png)

IV) Завершить процесс документирования, дополнить документацию необходимыми комментариями и подробным описанием всех встреченных в процессе сложностей. Допустимые форматы отчета: docx, pdf. Индивидуальный отчет после защиты загрузить в DiSpace3 (1 экземпляр от бригады).