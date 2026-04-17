### Part I

1) Подключится к серверу для 3-ей лабы:

```ssh tech@172.16.8.169```
```rebustubus```

2) сменить текущего пользователя на root:

```sudo su -```

3) Создать файл отчета /root/sysadm-lab3-{группа}-{вариант}.log, выполнив команду:
		 
```{группа}=avt341```
```{вариант}=v9```

```echo $(date) > /root/sysadm-lab3-avt341-v9.log```

### Part II

4) Установить пакет open-iscsi при помощи утилиты apt

```apt install -y open-iscsi | tee -a /root/sysadm-lab3-avt341-v9.log```

5) Изменить файл /etc/iscsi/initiatorname.iscsi:

```echo "InitiatorName=iqn.2025-04.ru.nstu.cs.vt:avt341.v9" > /etc/iscsi/initiatorname.iscsi```

6) Изменить файл /etc/iscsi/iscsid.conf, модифицировав следующие строки:

vi /etc/iscsi/iscsid.conf

```
node.session.auth.authmethod = CHAP
node.session.auth.username = avt341-v9
node.session.auth.password = k5ioyyAO8cR6
```

7) Не забыть выполнить перезапуск сервисов iscsid и open-iscsi: 

```systemctl restart iscsid open-iscsi | tee -a /root/sysadm-lab3-avt341-v9.log```

8) Выполнить команду ```iscsiadm -m discovery -t sendtargets -p {портал}```,  где ```{портал}``` - это адрес портала п.2 исходных данных. 
Если предыдущие шаги выполенны правильно, то должен появиться список, содержащий множество тагретов вида ```iqn.2025-04.ru.nstu.cs.vt:...```, 
среди которых необходимо найти свой по номеру группы и бригады.
Результат выполнения этой команды необходимо записать в файл отчета.

TODO: add awk parsing so it only displays target name

```iscsiadm -m discovery -t sendtargets -p 172.16.6.15 | grep avt341.v9 | awk '{print $2}' | tee -a /root/sysadm-lab3-avt341-v9.log```

{таргет бригады} = iqn.2025-04.ru.nstu.cs.vt:avt341.v9

9) Сохранить содержимое файла /proc/partitions в файл /root/before.txt

```cat /proc/partitions > /root/before.txt```

10) Выполнить команду iscsiadm --mode node --targetname {таргет бригады} --login, 
результаты вывода этой команды и команды ```iscsiadm -m session -o show``` записать в файл отчета. 

{таргет бригады} = iqn.2025-04.ru.nstu.cs.vt:avt341.v9

``` iscsiadm --mode node --targetname "iqn.2025-04.ru.nstu.cs.vt:avt341.v9" --login | tee -a /root/sysadm-lab3-avt341-v9.log```

``` iscsiadm -m session -o show | tee -a /root/sysadm-lab3-avt341-v9.log ```

11) Выполнить команду ```diff /root/before.txt /proc/partitions``` и сохранить результат ее работы в файл отчета.
Это позволит определить, какие новые устройства и с какими именами были добавлены в систему.
Файл /root/before.txt больше не нужен, его можно удалить.

```diff /root/before.txt /proc/partitions | tee -a /root/sysadm-lab3-avt341-v9.log```

```rm /root/before.txt```

Если предыдущие шаги выполнены правильно, то в распоряжении группы теперь имеется два блочных устройства
по 512 МБ каждое и можно переходить к следующему шагу.

sdb
sdc

### Part III - Создание программного raid-массива

12) С помощью утилиты parted создать на полученных в п.2 задания блочных устройствах по одному первичному разделу с типом fd (Linux raid)

Нужно знать имена двух дисковых устройств созданных в пункте 11

parted /dev/sdb --script mklabel gpt | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script mkpart primary 0% 100% | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script set 1 raid on | tee -a /root/sysadm-lab3-avt341-v9.log

parted /dev/sdc --script mklabel gpt | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdc --script mkpart primary 0% 100% | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdc --script set 1 raid on | tee -a /root/sysadm-lab3-avt341-v9.log

13) Сохранить в файл отчета результат работы ```parted /dev/{имя блочного устройства} print``` для каждого из устройств

```
parted /dev/sdb print | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdc print | tee -a /root/sysadm-lab3-avt341-v9.log
```

14) Установить пакет mdadm (software RAID)

``` apt install -y mdadm | tee -a /root/sysadm-lab3-avt341-v9.log ```

15) Выполнить команду mdadm --detail --scan и определить доступное имя для raid-массива. 
Имена имеют вид /dev/mdX, где X - номер raid-массива, начиная с 0, если список пуст, то можно использовать 0, иначе необходимо найти не занятое имя.

``` mdadm --detail --scan | tee -a /root/sysadm-lab3-avt341-v9.log ```

Вывод пустой, будем использовать /dev/md0

16) Создать программный raid-массив 1 уровня (зеркало) при помощи команды mdadm --create --verbose /dev/{имя raid-масива} --level=1 --raid-devices=2 /dev/{раздел1} /dev/{раздел2}

Где {раздел1} и {раздел2} - это разделы, созданные на предыдущем шаге при помощи parted.

``` mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc | tee -a /root/sysadm-lab3-avt341-v9.log ```

17) Сохранить содержимое файла /proc/mdstat и результат вывода команды mdadm --detail --scan в файл отчета

``` cat /proc/mdstat | tee -a /root/sysadm-lab3-avt341-v9.log ```

``` mdadm --detail --scan | tee -a /root/sysadm-lab3-avt341-v9.log ```

### Part IV - Использование LVM

-> You are here

18) Разметить полученный в п.3 задания raild-массив как физический том lvm при помощи команды pvcreate

``` pvcreate /dev/md0 | tee -a /root/sysadm-lab3-avt341-v9.log ```

19) При помощи команды vgcreate создать группу томов с именем vg-{группа}-{вариант} и включить в нее свой физический том.

```{группа}=avt341```
```{вариант}=v9```

``` vgcreate vg-avt341-v9 /dev/md0 | tee -a /root/sysadm-lab3-avt341-v9.log ```

20) При помощи команды lvcreate создать логический том с произвольным именем (ЛТсПИ) в группе томов vg-{группа}-{вариант} размером 70% от всего доступного места в группе томов.

``` lvcreate -l 70%FREE -n mydata vg-avt341-v9 | tee -a /root/sysadm-lab3-avt341-v9.log ```

21) Создать на /dev/vg-{группа}-{вариант}/{ЛТсПИ} файловую систему ext4 при помощи команды mkfs

```
# Форматирование в ext4
mkfs.ext4 /dev/vg-avt341-v9/mydata | tee -a /root/sysadm-lab3-avt341-v9.log
```

22) Сохранить результат работы команд pvdisplay, vgdisplay, lvdisplay и blkid /dev/vg-{группа}-{вариант}/{ЛТсПИ} в файл отчета.

```
pvdisplay | tee -a /root/sysadm-lab3-avt341-v9.log
vgdisplay | tee -a /root/sysadm-lab3-avt341-v9.log
lvdisplay | tee -a /root/sysadm-lab3-avt341-v9.log
blkid /dev/vg-avt341-v9/mydata | tee -a /root/sysadm-lab3-avt341-v9.log
```

23) Создать в каталоге /mnt подкаталог для монтирования созданной файловой системе, названный по принципу /mnt/{ЛТсПИ}_base (точку монтирования) и смонтировать его при помощи команды mount.

```
# Создание точки монтирования
mkdir /mnt/mydata_base
# Монтирование
mount /dev/vg-avt341-v9/mydata /mnt/mydata_base
```

24) При помощи утилиты dd создать в каталоге /mnt/{ЛТсПИ}_base файл test.bin размером 100МБ из источника /dev/random и вычислить для полученного файла контрольную сумму при помощи программы md5sum, сохранить это значение в файле журнала

```
# Создаем файл test.bin размером 100 МБ
dd if=/dev/random of=/mnt/mydata_base/test.bin bs=1M count=100 status=progress | tee -a /root/sysadm-lab3-avt341-v9.log
# Вычисляем его MD5
md5sum /mnt/mydata_base/test.bin | tee -a /root/sysadm-lab3-avt341-v9.log
```

25) При помощи команды lvcreate cоздать для {ЛТсПИ} снимок (snapshot) размером со все свободное место на группе томов и именем {ЛТсПИ}_snap, создать для него точку монтирования /mnt/{ЛТсПИ}_snap и выполнить монтирование

```
# Создание snapshot (снимка)
lvcreate -l 100%FREE -s -n mydata_snap /dev/vg-avt341-v9/mydata | tee -a /root/sysadm-lab3-avt341-v9.log
# Создание точки монтирования
mkdir /mnt/mydata_snap
# Монтирование
mount /dev/vg-avt341-v9/mydata_snap /mnt/mydata_snap
```

26) При помощи утилиты dd заменить в каталоге /mnt/{ЛТсПИ}_base файл test.bin размером 100МБ из источника /dev/random, вычислить контрольные суммы md5 для файлов /mnt/{ЛТсПИ}_base/test.bin и /mnt/{ЛТсПИ}_snap/test.bin и сохранить эти значения в файле журнала.

```
# Генерируем новый файл поверх старого
dd if=/dev/random of=/mnt/mydata_base/test.bin bs=1M count=100 status=progress
# Вычисляем MD5 нового файла в исходной ФС
md5sum /mnt/mydata_base/test.bin | tee -a /root/sysadm-lab3-avt341-v9.log
# Вычисляем MD5 файла в снимке (он должен остаться старым)
md5sum /mnt/mydata_snap/test.bin | tee -a /root/sysadm-lab3-avt341-v9.log
```

27) Сохранить в файле отчета результат работы lvdisplay, размонтировать каталог /mnt/{ЛТсПИ}_snap при помощи umount и удалить снимок логического тома {ЛТсПИ}_snap при помощи команды lvremove

```
# Сохраняем итоговую информацию о томах
lvdisplay | tee -a /root/sysadm-lab3-avt341-v9.log
# Размонтируем снимок
umount /mnt/mydata_snap
# Удаляем снимок
lvremove -f /dev/vg-avt341-v9/mydata_snap
```