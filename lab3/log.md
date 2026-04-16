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

```
node.session.auth.authmethod = CHAP
node.session.auth.username = avt341-v9
node.session.auth.password = k5ioyyAO8cR6
```

vi /etc/iscsi/iscsid.conf

7) Не забыть выполнить перезапуск сервисов iscsid и open-iscsi: 

```systemctl restart iscsid open-iscsi | tee -a /root/sysadm-lab3-avt341-v9.log```

8) Выполнить команду ```iscsiadm -m discovery -t sendtargets -p {портал}```,  где ```{портал}``` - это адрес портала п.2 исходных данных. 
Если предыдущие шаги выполенны правильно, то должен появиться список, содержащий множество тагретов вида ```iqn.2025-04.ru.nstu.cs.vt:...```, 
среди которых необходимо найти свой по номеру группы и бригады.
Результат выполнения этой команды необходимо записать в файл отчета.

```iscsiadm -m discovery -t sendtargets -p 172.16.6.15 | tee -a /root/sysadm-lab3-avt341-v9.log```

172.16.6.15:3260,1 iqn.2025-04.ru.nstu.cs.vt:avt341.v9

iscsiadm -m discovery -t sendtargets -p 172.16.6.15 | less

TODO: найти свой через grep

9) Сохранить содержимое файла /proc/partitions в файл /root/before.txt

```cat /proc/partitions > /root/before.txt```

10) Выполнить команду iscsiadm --mode node --targetname {таргет бригады} --login, 
результаты вывода этой команды и команды iscsiadm -m session -o show записать в файл отчета. 

найденный_таргет = таргет из пункта 8

``` iscsiadm --mode node --targetname "найденный_таргет" --login | tee -a /root/sysadm-lab3-avt341-v9.log```

11) Выполнить команду ```diff /root/before.txt /proc/partitions``` и сохранить результат ее работы в файл отчета.
Это позволит определить, какие новые устройства и с какими именами были добавлены в систему.
Файл /root/before.txt больше не нужен, его можно удалить.

```diff /root/before.txt /proc/partitions | tee -a /root/sysadm-lab3-{группа}-{вариант}.log```

```rm /root/before.txt```

Если предыдущие шаги выполнены правильно, то в распоряжении группы теперь имеется два блочных устройства
по 512 МБ каждое и можно переходить к следующему шагу.

### Part III - Создание программного raid-массива

12) С помощью утилиты parted создать на полученных в п.2 задания блочных устройствах по одному первичному разделу с типом fd (Linux raid)

Нужно знать имена двух дисковых устройств созданных в пункте 11

# Команда для /dev/sdb (для /dev/sdc повторите, заменив букву)
parted /dev/sdb --script mklabel gpt | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script mkpart primary 0% 100% | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script set 1 raid on | tee -a /root/sysadm-lab3-avt341-v9.log

# Команда для /dev/sdb (для /dev/sdc повторите, заменив букву)
parted /dev/sdb --script mklabel gpt | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script mkpart primary 0% 100% | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdb --script set 1 raid on | tee -a /root/sysadm-lab3-avt341-v9.log

13) Сохранить в файл отчета результат работы ```parted /dev/{имя блочного устройства} print``` для каждого из устройств

```
parted /dev/sdb print | tee -a /root/sysadm-lab3-avt341-v9.log
parted /dev/sdc print | tee -a /root/sysadm-lab3-avt341-v9.log
```

14) 

