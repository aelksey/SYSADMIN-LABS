## Выполнение работы

1) Установить пакеты net-snmp-libs, net-snmp, net-snmp-utils

```yum install net-snmp-libs net-snmp net-snmp-utils```

2) Настроить доступ и community для snmpd в файле /etc/snmp/snmpd.conf

variant = avt-341-9
community name = commavt-341-9

vi /etc/snmp/snmpd.conf

Добавить строки:

com2sec		local	127.0.0.1	commavt-341-9
group	avt-341-9	any	local
view	all	included	.1
access avt-341-9 ""	any noauth	0	all	none	none

Изменить строки:

syslocation Novosibirsk
syscontact "avt-341, Vladimirov Aleksey"

3) Запустить сервис snmpd и проверить его работу

```   
service snmpd start
snmpwalk -v 2c -c commavt-341-9 127.0.0.1
```

4) Извлечь при помощи snmp только ту информацию, которая указана в варианте индивидуального задания,
    результат сохранить в файле /root/{variant}.log
        Не допускается прямое или косвенное использование утилиты snmptable, результат должен быть оформлен
        в виде "параметр: значение", имя параметра без snmp префикса, если подразумевается несколько значений,
        результат должен быть оформлен в виде таблицы


## Вариативная часть

9) Информация о дисковых устройствах, файле подкачки (swap) (всего, занято, свободно)

vi /etc/snmp/snmpd.conf

добавить строчку:

includeAllDisks 10% for all partitions and disks




5) Сохранить файл из п.4 и /etc/snmp/snmpd.conf на локальный компьютер при помощи утилиты pscp


