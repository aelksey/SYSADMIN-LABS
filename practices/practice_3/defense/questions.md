# Вопросы для защиты лабораторной работы №3
## Установка iSCSI Target на Ubuntu 22.04 LTS

Ниже представлены вопросы для защиты с подробными ответами. Рекомендуется выучить или понять основные концепции.

---

## 1. Теоретические вопросы

### Вопрос 1.1: Что такое iSCSI и для чего он используется?

**Ответ:**
iSCSI (Internet Small Computer System Interface) — это протокол транспортного уровня, который позволяет передавать команды SCSI по TCP/IP сетям.

**Назначение:**
- Предоставление блочного доступа к хранилищам данных по сети
- Создание SAN (Storage Area Network) на основе Ethernet
- Виртуализация хранилищ (один физический диск может быть доступен множеству серверов)
- Резервное копирование и репликация данных

**Основные компоненты:**
- **Target (Цель)** — сервер, который предоставляет доступ к дискам (в вашей работе — сервер 172.16.8.169)
- **Initiator (Инициатор)** — клиент, который подключается к target (в вашей работе — клиент 217.71.138.1)

---

### Вопрос 1.2: Объясните архитектуру iSCSI: Target, Initiator, LUN, IQN.

**Ответ:**

| Компонент | Описание | Пример из работы |
|-----------|----------|------------------|
| **Target** | Сервер, экспортирующий блочные устройства | `172.16.8.169` |
| **Initiator** | Клиент, подключающийся к target | `217.71.138.1` |
| **LUN** (Logical Unit Number) | Номер логического устройства, идентификатор экспортируемого диска | LUN 0, LUN 1 (по 512 МБ) |
| **IQN** (iSCSI Qualified Name) | Уникальное имя target в формате iqn.гггг-мм.домен:устройство | `iqn.2026-04.local.lab:storage.target1` |

**Формат IQN:**
```
iqn.2026-04.local.lab:storage.target1
│   │    │        │           │
│   │    │        │           └─── Имя устройства
│   │    │        └─────────────── Обратный домен
│   │    └──────────────────────── Месяц
│   └───────────────────────────── Год
└───────────────────────────────── Префикс (iSCSI Qualified Name)
```

---

### Вопрос 1.3: Какой порт использует iSCSI?

**Ответ:**
- **Основной порт:** TCP 3260
- Порт зарегистрирован IANA (Internet Assigned Numbers Authority)
- Может быть изменен в конфигурации, но это не рекомендуется

**В вашей работе:**
```bash
sudo ufw allow from 217.71.138.1 to any port 3260 proto tcp
```

---

### Вопрос 1.4: Что такое CHAP-аутентификация и как она работает?

**Ответ:**
CHAP (Challenge-Handshake Authentication Protocol) — протокол аутентификации, использующий трехэтапное рукопожатие.

**Принцип работы:**
```
1. Initiator → Target: "Хочу подключиться"
2. Target → Initiator: "Challenge" (случайное значение)
3. Initiator → Target: Response = Hash(Challenge + Password)
4. Target проверяет Response (Hash должен совпасть)
```

**Типы CHAP:**
- **Однонаправленный:** Target аутентифицирует Initiator (использовали в работе)
- **Взаимный:** Оба устройства аутентифицируют друг друга

**В вашей конфигурации:**
```bash
incominguser iscsi-user StrongPass123
# где iscsi-user — имя пользователя, StrongPass123 — пароль из ЛР №1
```

---

### Вопрос 1.5: В чем отличие между file, block и RAM LUN?

**Ответ:**
| Тип | Способ создания | Преимущества | Недостатки |
|-----|----------------|--------------|-------------|
| **File** | Файл-образ на существующей ФС | Простота, гибкость | Низкая производительность |
| **Block** | Отдельный LVM том или диск | Высокая производительность | Сложность управления |
| **RAM** | Хранение в tmpfs (оперативной памяти) | Максимальная скорость | Данные теряются при перезагрузке |

**Определение вашего варианта:**
```bash
# Остаток от деления номера бригады на 3
remainder = (№ бригады) % 3
# 0 → RAM, 1 → Block, 2 → File
```

**Команды создания для каждого типа:**
```bash
# RAM (tmpfs)
sudo mount -t tmpfs -o size=1024M tmpfs /mnt/ram_iscsi

# Block (LVM)
sudo lvcreate -L 512M -n iscsi_lun0 ubuntu-vg

# File
sudo dd if=/dev/zero of=/srv/iscsi/lun0.img bs=1M count=512
```

---

## 2. Практические вопросы

### Вопрос 2.1: Опишите процесс установки и настройки iSCSI Target на Ubuntu.

**Ответ:**

**Шаг 1: Установка пакета**
```bash
sudo apt update
sudo apt install -y tgt
```

**Шаг 2: Создание блочных устройств (LUN)**
```bash
# Блок для LVM (вариант 1)
sudo lvcreate -L 512M -n iscsi_lun0 ubuntu-vg
sudo lvcreate -L 512M -n iscsi_lun1 ubuntu-vg
```

**Шаг 3: Создание конфигурации**
```bash
sudo nano /etc/tgt/targets.conf
```

**Шаг 4: Конфигурация target**
```bash
<target iqn.2026-04.local.lab:storage.target1>
    incominguser iscsi-user StrongPass123
    initiator-address 217.71.138.1
    backing-store /dev/ubuntu-vg/iscsi_lun0
    backing-store /dev/ubuntu-vg/iscsi_lun1
</target>
```

**Шаг 5: Запуск и проверка**
```bash
sudo systemctl restart tgt
sudo tgt-admin --show
```

---

### Вопрос 2.2: Какие команды используются для просмотра состояния target?

**Ответ:**

| Команда | Назначение |
|---------|------------|
| `sudo systemctl status tgt` | Статус службы tgt |
| `sudo tgt-admin --show` | Показать все target и LUN |
| `sudo tgtadm --mode target --op show` | Альтернативный способ просмотра |
| `sudo tgtadm --mode target --op show --tid 1` | Показать конкретный target по ID |
| `sudo journalctl -u tgt.service -n 50` | Логи службы |

**Пример вывода:**
```
Target 1: iqn.2026-04.local.lab:storage.target1
    LUN: 1
        Size: 536 MB
        Backing store path: /dev/ubuntu-vg/iscsi_lun0
    LUN: 2
        Size: 536 MB
        Backing store path: /dev/ubuntu-vg/iscsi_lun1
    Account information:
        iscsi-user
    ACL information:
        217.71.138.1
```

---

### Вопрос 2.3: Как настроить firewall для iSCSI?

**Ответ:**

**Для ufw (Ubuntu):**
```bash
# Разрешить доступ только с конкретного IP
sudo ufw allow from 217.71.138.1 to any port 3260 proto tcp

# Проверка правил
sudo ufw status numbered

# Для отладки (временно отключить)
sudo ufw disable
```

**Для iptables:**
```bash
sudo iptables -A INPUT -p tcp -s 217.71.138.1 --dport 3260 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3260 -j DROP
```

**Проверка доступности порта:**
```bash
# С клиента
telnet 172.16.8.169 3260
nmap -p 3260 172.16.8.169
```

---

### Вопрос 2.4: Как подключиться к iSCSI Target с клиента (CentOS)?

**Ответ:**

**Шаг 1: Установка инициатора**
```bash
sudo yum install -y iscsi-initiator-utils
```

**Шаг 2: Обнаружение target**
```bash
sudo iscsiadm -m discovery -t sendtargets -p 172.16.8.169
```

**Шаг 3: Настройка CHAP-аутентификации**
```bash
sudo iscsiadm -m node -o update -n node.session.auth.username -v iscsi-user
sudo iscsiadm -m node -o update -n node.session.auth.password -v StrongPass123
```

**Шаг 4: Подключение**
```bash
sudo iscsiadm -m node --login
```

**Шаг 5: Проверка подключения**
```bash
sudo iscsiadm -m session -o show
lsblk
sudo lsscsi
```

---

### Вопрос 2.5: Как проверить, что LUN'ы видны на клиенте?

**Ответ:**

```bash
# 1. Активные iSCSI сессии
sudo iscsiadm -m session -o show

# 2. Блочные устройства (должны появиться sdb, sdc...)
lsblk | grep -v loop

# 3. SCSI устройства
sudo lsscsi | grep IET

# 4. Размеры дисков
sudo fdisk -l | grep "^Disk /dev/sd"

# 5. Детальная информация о сессии с LUN'ами
sudo iscsiadm -m session -P 3 | grep -A 5 "Attached SCSI"

# 6. Проверка записи/чтения
sudo dd if=/dev/zero of=/dev/sdb bs=1M count=10 oflag=direct
```

**Признаки успеха:**
- Появление `/dev/sdb` и `/dev/sdc` (или других sdX)
- Размер каждого диска 536870912 байт (512 МБ)
- В выводе `lsscsi` присутствует `IET VIRTUAL-DISK`

---

### Вопрос 2.6: Какие могут возникнуть проблемы и как их решить?

**Ответ:**

| Проблема | Симптомы | Решение |
|----------|----------|---------|
| **TGT не стартует** | `systemctl status tgt` показывает ошибку | Проверить синтаксис конфигурации, удалить лишние теги |
| **Ошибка CHAP** | Authentication failed | Проверить имя пользователя и пароль на обеих сторонах |
| **Firewall блокирует** | Connection timeout | Добавить правило для порта 3260: `ufw allow from IP to port 3260` |
| **LUN не отображаются** | `lsblk` не показывает новые диски | Выполнить `iscsiadm -m node --rescan` |
| **LUN уже существует** | "device already exists" | Удалить существующий target: `tgt-admin --delete ALL` |
| **Конфигурация не применяется** | Изменения не видны после перезагрузки | Проверить, что конфиг в `/etc/tgt/targets.conf` или `/etc/tgt/conf.d/` |

**Конкретно из вашей работы:**
```bash
# Ошибка синтаксиса конфигурации
Config::General: EndBlock "</target>" has no StartBlock statement

# Решение: убедиться, что открывающий и закрывающий теги совпадают
<target ...>
    ...
</target>  # ← не должно быть лишних пробелов перед закрывающим тегом
```

---

## 3. Вопросы по конкретной реализации

### Вопрос 3.1: Какие IP-адреса использовались в работе и их роль?

**Ответ:**
| IP-адрес | Роль | Назначение |
|----------|------|------------|
| `172.16.8.169` | Сервер (Target) | Ubuntu 22.04, экспортирует LUN'ы |
| `217.71.138.1` | Клиент (Initiator) | Первая практика, подключается к target |

**Почему разные подсети:**
- `172.16.8.0/24` — внутренняя лабораторная сеть (вторая практика)
- `217.71.138.0/24` — внешняя сеть, возможно NAT (первая практика)

---

### Вопрос 3.2: Какой тип LUN был использован и почему?

**Ответ:**
Тип определяется остатком от деления номера бригады на 3:

```bash
case $((бригада % 3)) in
    0) echo "RAM (tmpfs)";;
    1) echo "Block (LVM)";;
    2) echo "File";;
esac
```

**Для вашего варианта** (бригада 9, 9 % 2 = 1, но в задании деление на 2?):
- По заданию: разделить номер бригады на 2 и найти остаток
- Остаток 0 → RAM
- Остаток 1 → Block (LVM)

**В вашей работе использован Block (LVM):**
```bash
sudo lvcreate -L 512M -n iscsi_lun0 ubuntu-vg
sudo lvcreate -L 512M -n iscsi_lun1 ubuntu-vg
```

**Преимущества LVM:**
- Постоянное хранение (не теряется при перезагрузке)
- Высокая производительность
- Возможность расширения (lvextend)

---

### Вопрос 3.3: В чем отличие между tgt и istgt?

**Ответ:**

| Характеристика | tgt | istgt |
|----------------|-----|-------|
| **Статус** | Активно поддерживается | Устаревший |
| **Доступность** | В официальных репозиториях Ubuntu 22.04 | Удален |
| **Конфигурация** | `/etc/tgt/targets.conf` | `/etc/istgt/istgt.conf` |
| **Поддержка iSCSI** | Полная | Базовая |
| **Поддержка ядра** | Совместим с новыми ядрами | Проблемы с ядром 5.x+ |

**Почему используется tgt вместо istgt:**
- `istgt` отсутствует в репозиториях Ubuntu 22.04
- `istgt` не обновлялся с 2017 года
- `tgt` является современной заменой

---

### Вопрос 3.4: Как проверить сохранность данных после перезагрузки?

**Ответ:**

**На клиенте:**
```bash
# 1. Записать тестовые данные до перезагрузки
sudo mkfs.ext4 /dev/sdb
sudo mount /dev/sdb /mnt
echo "Test data $(date)" | sudo tee /mnt/test.txt
sudo umount /mnt

# 2. Отключиться
sudo iscsiadm -m node --logoutall=all

# 3. Перезагрузить сервер
ssh tech@172.16.8.169 "sudo reboot"

# 4. Дождаться загрузки (30-60 секунд)
sleep 60

# 5. Переподключиться
sudo iscsiadm -m discovery -t sendtargets -p 172.16.8.169
sudo iscsiadm -m node --login

# 6. Проверить данные
sudo mount /dev/sdb /mnt
cat /mnt/test.txt  # Должен быть тот же текст
```

**Автоматическое переподключение:**
```bash
# Настроить автоподключение при загрузке клиента
sudo systemctl enable iscsid
sudo systemctl enable iscsi

# На сервере настроить автозапуск tgt
sudo systemctl enable tgt
```

---

## 4. Вопросы для отчета

### Вопрос 4.1: Какие скриншоты необходимо включить в отчет?

**Ответ:**
1. **На сервере (Ubuntu):**
   - `sudo lvdisplay` или `lsblk` — создание LUN
   - Содержимое `/etc/tgt/targets.conf`
   - `sudo ufw status verbose` — правила firewall
   - `sudo tgt-admin --show` — запущенный target

2. **На клиенте (CentOS):**
   - `sudo iscsiadm -m discovery` — обнаружение target
   - `sudo iscsiadm -m session -o show` — активная сессия
   - `lsblk` или `sudo lsscsi` — отображение LUN
   - Результат монтирования и записи файла
   - Проверка данных после перезагрузки

---

### Вопрос 4.2: Какие команды используются для отладки?

**Ответ:**

```bash
# Просмотр логов службы
sudo journalctl -u tgt.service -n 50 -f

# Проверка синтаксиса конфигурации
sudo tgt-admin --dump

# Проверка доступности порта с клиента
nc -zv 172.16.8.169 3260
telnet 172.16.8.169 3260

# Отладка CHAP-аутентификации
sudo iscsiadm -m node -o show | grep -E "auth|password"

# Просмотр SCSI команд в реальном времени
sudo tcpdump -i eth0 port 3260

# Проверка блокировки firewall
sudo ufw status verbose
sudo iptables -L -n -v | grep 3260
```

---

## 5. Типичные вопросы преподавателя

### Вопрос 5.1: Может ли один LUN быть доступен нескольким инициаторам?

**Ответ:**
Да, но с ограничениями:
- **Без кластеризации:** только чтение, запись повредит данные
- **С кластеризацией (OCFS2, GFS2):** да, несколько инициаторов могут писать одновременно
- **В вашей работе:** используется `initiator-address 217.71.138.1` — доступ только с одного IP

**Для множественного доступа:**
```bash
initiator-address ALL  # или перечислить IP через запятую
# Но требуется файловая система с поддержкой кластеризации!
```

---

### Вопрос 5.2: Как увеличить размер LUN без потери данных?

**Ответ:**

**На сервере:**
```bash
# 1. Увеличить LVM том (например, с 512M до 1G)
sudo lvextend -L +512M /dev/ubuntu-vg/iscsi_lun0

# 2. Обновить target
sudo tgt-admin --update ALL
```

**На клиенте:**
```bash
# 3. Пересканировать SCSI устройства
sudo iscsiadm -m node --rescan

# 4. Увеличить файловую систему (если ext4)
sudo resize2fs /dev/sdb
```

---

### Вопрос 5.3: Как защитить iSCSI трафик?

**Ответ:**

| Метод защиты | Уровень | Сложность |
|--------------|---------|-----------|
| **CHAP** | Аутентификация | Легкий |
| **IP ACL** | Сетевой (firewall) | Легкий |
| **iSCSI over IPSec** | Шифрование | Средний |
| **VLAN изоляция** | Сетевой | Средний |
| **Выделенная сеть хранения** | Физический | Высокий |

**В вашей работе реализовано:**
1. CHAP-аутентификация
2. Ограничение доступа по IP через firewall
3. ACL в конфигурации target (`initiator-address`)

---

## Шпаргалка для быстрой подготовки

```bash
# Основные понятия
iSCSI = SCSI over TCP/IP
Target = сервер (172.16.8.169)
Initiator = клиент (217.71.138.1)
LUN = номер логического устройства (0, 1)
IQN = iqn.2026-04.local.lab:storage.target1
CHAP = аутентификация по паролю
Порт = 3260/tcp

# Главные команды
# На сервере:
sudo tgt-admin --show
sudo systemctl restart tgt
sudo ufw allow from IP to any port 3260

# На клиенте:
sudo iscsiadm -m discovery -t st -p IP
sudo iscsiadm -m node --login
sudo iscsiadm -m session -o show
lsblk

# Диагностика
tail -f /var/log/syslog | grep tgt
sudo journalctl -u tgt.service -f
```

Удачи на защите!