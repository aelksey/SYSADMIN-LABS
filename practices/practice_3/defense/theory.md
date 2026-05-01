# Теория для защиты лабораторной работы №3
## iSCSI Target на Ubuntu 22.04 LTS

Полный теоретический материал для успешной защиты. Структурирован по темам с определениями, схемами и типичными вопросами.

---

## 1. Основы iSCSI

### 1.1 Определение и назначение

**iSCSI (Internet Small Computer System Interface)** — протокол транспортного уровня, инкапсулирующий команды SCSI в TCP/IP пакеты.

**Ключевые характеристики:**
- Позволяет передавать команды SCSI по Ethernet/IP сетям
- Работает поверх TCP (обычно порт 3260)
- Обеспечивает блочный доступ к удаленным хранилищам
- Является альтернативой Fibre Channel (более дешевое решение)

**Области применения:**
- **SAN (Storage Area Network)** — создание сети хранения данных
- **Виртуализация хранилищ** — один физический диск для множества серверов
- **Резервное копирование** — удаленное бэкапирование на уровне блоков
- **Hypervisor хранилища** — datastore для VMware, Hyper-V, KVM

### 1.2 Архитектура и компоненты

```
┌─────────────────────────────────────────────────────────────────┐
│                         iSCSI Архитектура                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────────────┐                    ┌──────────────────┐  │
│   │    INITIATOR     │    TCP/IP сеть     │     TARGET       │  │
│   │    (Клиент)      │◄──────────────────►│    (Сервер)      │  │
│   │                  │    Порт 3260       │                  │  │
│   │  ┌────────────┐  │                    │  ┌────────────┐  │  │
│   │  │  Приложение │  │                    │  │    LUN 0   │  │  │
│   │  └──────┬─────┘  │                    │  │   512 МБ   │  │  │
│   │         │        │                    │  ├────────────┤  │  │
│   │  ┌──────▼─────┐  │    SCSI команды    │  │    LUN 1   │  │  │
│   │  │  iSCSI     │  │    инкапсулированные│  │   512 МБ   │  │  │
│   │  │  Driver    │  │    в TCP/IP        │  └────────────┘  │  │
│   │  └──────┬─────┘  │                    │                  │  │
│   │         │        │                    │  ┌────────────┐  │  │
│   │  ┌──────▼─────┐  │                    │  │   tgt      │  │  │
│   │  │  TCP/IP    │  │                    │  │  (демон)   │  │  │
│   │  │  Stack     │  │                    │  └────────────┘  │  │
│   │  └────────────┘  │                    │                  │  │
│   └──────────────────┘                    └──────────────────┘  │
│                                                                  │
│   217.71.138.1                              172.16.8.169        │
│   (Первая практика)                         (Вторая практика)   │
└─────────────────────────────────────────────────────────────────┘
```

**Основные компоненты:**

| Компонент | Описание | Пример |
|-----------|----------|--------|
| **Initiator** | Клиент, инициирующий подключение к storage | `217.71.138.1` |
| **Target** | Сервер, предоставляющий блочные устройства | `172.16.8.169` |
| **LUN** (Logical Unit Number) | Номер логического устройства (диска) | LUN 0, LUN 1 |
| **IQN** (iSCSI Qualified Name) | Уникальное имя target | `iqn.2026-04.local.lab:storage.target1` |
| **Portal** | Сетевой эндпоинт (IP:порт) | `172.16.8.169:3260` |
| **Session** | Соединение между initiator и target | Сессия после login |

### 1.3 Формат IQN

```
iqn.2026-04.local.lab:storage.target1
│   │    │       │            │
│   │    │       │            └─── Имя устройства (произвольное)
│   │    │       └──────────────── Обратный домен (ваша организация)
│   │    └──────────────────────── Месяц создания
│   └───────────────────────────── Год создания
└───────────────────────────────── Тип: iqn (iSCSI Qualified Name)

Другие форматы:
- iqn.YYYY-MM.reverse.domain:unique-string
- eui.EUI-64-address (например, eui.02004567A425678D)
- naa.NAA-address (например, naa.6001405fdca5d6b7)
```

---

## 2. Протокол iSCSI

### 2.1 Как работает iSCSI

**Этапы установки соединения:**

```
Initiator (клиент)                      Target (сервер)
      │                                       │
      │  1. Discovery (Обнаружение)           │
      │  ─────────────────────────────────────►│
      │     "Есть ли у тебя target?"          │
      │                                        │
      │  2. Target Response                   │
      │  ◄─────────────────────────────────────│
      │     "Да, вот список target"           │
      │                                        │
      │  3. CHAP Authentication               │
      │  ─────────────────────────────────────►│
      │     "Мой логин и пароль"              │
      │                                        │
      │  4. Login                             │
      │  ─────────────────────────────────────►│
      │     "Хочу подключиться"               │
      │                                        │
      │  5. Session Established               │
      │  ◄─────────────────────────────────────│
      │     "Подключение установлено"         │
      │                                        │
      │  6. SCSI Commands                     │
      │  ─────────────────────────────────────►│
      │  ◄─────────────────────────────────────│
      │     READ/WRITE данные                 │
      │                                        │
      │  7. Logout                            │
      │  ─────────────────────────────────────►│
      │     "Отключаюсь"                      │
```

### 2.2 Инкапсуляция iSCSI

```
┌─────────────────────────────────────────────────────────────┐
│                    OSI Model vs iSCSI                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Уровень 7:   Application (Приложение)                     │
│                ┌─────────────────────────────────────┐       │
│                │      SCSI Command Descriptor Block  │       │
│                └─────────────────────────────────────┘       │
│                         ▼                                    │
│   Уровень 6-5:  Presentation/Session                        │
│                ┌─────────────────────────────────────┐       │
│                │      iSCSI Protocol Data Unit (PDU)  │       │
│                └─────────────────────────────────────┘       │
│                         ▼                                    │
│   Уровень 4:   Transport (TCP)                              │
│                ┌─────────────────────────────────────┐       │
│                │      TCP Segment (порт 3260)         │       │
│                └─────────────────────────────────────┘       │
│                         ▼                                    │
│   Уровень 3:   Network (IP)                                 │
│                ┌─────────────────────────────────────┐       │
│                │      IP Packet                      │       │
│                └─────────────────────────────────────┘       │
│                         ▼                                    │
│   Уровень 2:   Data Link (Ethernet)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Типы PDU (Protocol Data Units)

| Тип PDU | Назначение | Инициатор |
|---------|------------|-----------|
| **SCSI Command** | Выполнение SCSI команды (READ, WRITE) | Initiator |
| **SCSI Response** | Результат выполнения команды | Target |
| **Task Management** | Управление задачами (отмена, сброс) | Initiator |
| **Login** | Установка сессии | Initiator |
| **Logout** | Завершение сессии | Initiator |
| **Text** | Передача текстовой информации | Оба |
| **NOP-Out/NOP-In** | Keep-alive проверка | Оба |

---

## 3. Аутентификация и безопасность

### 3.1 CHAP (Challenge-Handshake Authentication Protocol)

**Принцип работы CHAP:**

```
┌──────────────┐                                          ┌──────────────┐
│  INITIATOR   │                                          │   TARGET     │
│  (Клиент)    │                                          │  (Сервер)    │
└──────┬───────┘                                          └──────┬───────┘
       │                                                       │
       │  1. "Я хочу подключиться"                             │
       │  ─────────────────────────────────────────────────────►│
       │                                                       │
       │  2. Challenge (случайное число)                       │
       │  ◄─────────────────────────────────────────────────────│
       │     Challenge = 0x4A8F2C3B                           │
       │                                                       │
       │  3. Response = Hash(Challenge + Secret)              │
       │  ─────────────────────────────────────────────────────►│
       │     Response = SHA1(0x4A8F2C3B + "password123")      │
       │                                                       │
       │  4. Target вычисляет свой Hash и сравнивает          │
       │                                                       │
       │  5. Success/Failure                                  │
       │  ◄─────────────────────────────────────────────────────│
       │     "Access Granted" или "Access Denied"             │
       │                                                       │
```

**Преимущества CHAP:**
- Пароль не передается по сети в открытом виде
- Устойчив к replay-атакам (из-за случайного Challenge)
- Поддерживается всеми iSCSI устройствами

**Недостатки CHAP:**
- Не шифрует сами данные
- Требует синхронизации времени? (нет, CHAP не зависит от времени)

### 3.2 Виды CHAP

| Тип | Описание | Уровень защиты |
|-----|----------|----------------|
| **Unidirectional CHAP** | Target аутентифицирует Initiator | Средний |
| **Mutual CHAP** | Взаимная аутентификация (оба проверяют друг друга) | Высокий |
| **SRP (SRP-CHAP)** | Использует криптографию с открытым ключом | Очень высокий |

**Конфигурация Mutual CHAP:**
```bash
# На сервере
<target iqn.2026-04.local.lab:storage.target1>
    incominguser iscsi-user StrongPass123
    outgoinguser target-user targetPass456   # Обратная аутентификация
</target>

# На клиенте
sudo iscsiadm -m node -o update -n node.session.auth.username -v iscsi-user
sudo iscsiadm -m node -o update -n node.session.auth.password -v StrongPass123
sudo iscsiadm -m node -o update -n node.session.auth.username_in -v target-user
sudo iscsiadm -m node -o update -n node.session.auth.password_in -v targetPass456
```

### 3.3 Альтернативные методы защиты

| Метод | Описание | Уровень |
|-------|----------|---------|
| **IP ACL** | Ограничение доступа по IP адресам | Базовый |
| **iSCSI over IPSec** | Шифрование всего трафика IPsec | Высокий |
| **VLAN Isolation** | Выделенная VLAN для storage трафика | Средний |
| **Dedicated Network** | Физически выделенная сеть хранения | Максимальный |

---

## 4. LUN (Logical Unit Number)

### 4.1 Определение LUN

**LUN (Logical Unit Number)** — это уникальный идентификатор, который присваивается логическому устройству хранения в рамках target. В iSCSI контексте LUN представляет собой блочное устройство (диск, раздел, файл-образ), экспортируемое клиенту.

**Нумерация LUN:**
- **LUN 0** — обычно зарезервирован для контроллера (не используется для данных)
- **LUN 1, 2, 3...** — пользовательские устройства

### 4.2 Типы Backing Store

```
┌─────────────────────────────────────────────────────────────────┐
│                    Типы Backing Store в tgt                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Block Device (блочное устройство)                          │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  backing-store /dev/sdb                             │     │
│     │  backing-store /dev/ubuntu-vg/iscsi_lun0            │     │
│     └─────────────────────────────────────────────────────┘     │
│     • Высокая производительность                                │
│     • Поддержка TRIM/UNMAP                                      │
│     • Требует выделенного раздела или LVM                        │
│                                                                  │
│  2. File-backed (файловый образ)                               │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  backing-store /srv/iscsi/lun0.img                   │     │
│     └─────────────────────────────────────────────────────┘     │
│     • Простота создания (dd)                                    │
│     • Легко переносить (один файл)                              │
│     • Ниже производительность из-за файловой системы            │
│                                                                  │
│  3. RAM-backed (временное хранилище)                           │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  mount -t tmpfs tmpfs /mnt/ram_iscsi                │     │
│     │  backing-store /mnt/ram_iscsi/lun0.img              │     │
│     └─────────────────────────────────────────────────────┘     │
│     • Максимальная скорость (оперативная память)                │
│     • Данные теряются при перезагрузке                          │
│     • Ограничен объемом RAM                                     │
│                                                                  │
│  4. Null-backed (тестовый)                                     │
│     ┌─────────────────────────────────────────────────────┐     │
│     │  backing-store null0                                │     │
│     └─────────────────────────────────────────────────────┘     │
│     • Для тестирования (реальные данные не сохраняются)         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Сравнение типов LUN

| Характеристика | Block | File | RAM |
|----------------|-------|------|-----|
| **Производительность** | Высокая | Средняя | Максимальная |
| **Постоянство данных** | Да | Да | Нет (после reboot) |
| **Сложность создания** | Средняя | Низкая | Низкая |
| **Расширение онлайн** | Да (lvextend) | Нет (нужен новый файл) | Нет |
| **Snapshot поддержка** | Да (LVM snapshot) | Нет | Нет |
| **Использование кэша** | ОС кэш | ОС кэш + FS кэш | Нет |
| **Рекомендуемое применение** | Production | Тестирование | Высокая производительность, кэш |

---

## 5. TGT (Linux SCSI Target Framework)

### 5.1 Что такое TGT

**TGT** (Linux SCSI Target Framework) — это реализация iSCSI target для Linux, работающая в пользовательском пространстве.

**Особенности TGT:**
- Работает как демон `tgtd`
- Поддерживает iSCSI, iSER (iSCSI over RDMA), FCoE
- Входит в состав ядра Linux (модуль `target_core_mod`)
- Использует конфигурационные файлы `/etc/tgt/targets.conf`

**Сравнение с другими target:**
| Решение | Пространство | Сложность | Производительность |
|---------|--------------|-----------|---------------------|
| **tgt** | User-space | Низкая | Хорошая |
| **LIO (targetcli)** | Kernel-space | Средняя | Отличная |
| **SCST** | Kernel-space | Высокая | Отличная |
| **Istgt** | User-space | Низкая | Средняя (устаревший) |

### 5.2 Структура конфигурации TGT

```bash
/etc/tgt/targets.conf
    │
    ├── <target ...>          # Определение target
    │   ├── incominguser      # CHAP аутентификация
    │   ├── initiator-address # ACL по IP
    │   ├── backing-store     # LUN определение (упрощенный синтаксис)
    │   ├── <backing-store>   # Расширенное определение LUN
    │   │   ├── lun 0         # Номер LUN
    │   │   ├── device-type   # Тип (disk, tape, cdrom)
    │   │   ├── blocksize     # Размер блока
    │   │   └── scsi_sn       # Серийный номер
    │   ├── write-cache       # Включение кэша записи
    │   ├── MaxConnections    # Максимум соединений
    │   └── timeout           # Таймауты
    │
    ├── <include>             # Подключение файлов
    └── <default>             # Значения по умолчанию
```

### 5.3 Примеры конфигурации

**Минимальная конфигурация:**
```bash
<target iqn.2026-04.local.lab:storage.target1>
    backing-store /dev/sdb
</target>
```

**Расширенная конфигурация (ваша работа):**
```bash
<target iqn.2026-04.local.lab:storage.target1>
    # Авторизация CHAP
    incominguser iscsi-user StrongPass123
    
    # Ограничение доступа по IP
    initiator-address 217.71.138.1
    
    # LUN 0
    backing-store /dev/ubuntu-vg/iscsi_lun0
    
    # LUN 1
    backing-store /dev/ubuntu-vg/iscsi_lun1
    
    # Настройки производительности
    write-cache on
    max_sectors 8192
</target>
```

**Конфигурация с детальными параметрами LUN:**
```bash
<target iqn.2026-04.local.lab:storage.target1>
    incominguser iscsi-user StrongPass123
    
    <backing-store /dev/ubuntu-vg/iscsi_lun0>
        lun 1
        device-type disk
        blocksize 4096
        scsi_sn LUN001ABC
        vendor_id TGT
        product_id VIRTUAL_DISK
        product_rev 1.0
    </backing-store>
    
    <backing-store /dev/ubuntu-vg/iscsi_lun1>
        lun 2
        device-type disk
        blocksize 4096
        scsi_sn LUN002DEF
    </backing-store>
</target>
```

### 5.4 Управление TGT

```bash
# Системные команды
sudo systemctl start tgt      # Запуск службы
sudo systemctl stop tgt       # Остановка
sudo systemctl restart tgt    # Перезапуск
sudo systemctl status tgt     # Статус
sudo systemctl enable tgt     # Автозапуск

# Администрирование через tgtadm
tgtadm --mode target --op show                    # Список target
tgtadm --mode target --op new --tid 1 -T NAME     # Создать target
tgtadm --mode target --op delete --tid 1          # Удалить target
tgtadm --mode logicalunit --op new --tid 1 --lun 1 -b DEVICE  # Добавить LUN
tgtadm --mode account --op new --user USER --pass PASS        # Добавить пользователя

# Администрирование через tgt-admin
sudo tgt-admin --show                             # Показать конфигурацию
sudo tgt-admin --update ALL                       # Применить изменения
sudo tgt-admin --dump > backup.conf               # Сохранить конфигурацию
```

---

## 6. Команды для защиты

### 6.1 Команды на сервере (Target - Ubuntu 172.16.8.169)

```bash
# Просмотр статуса службы
sudo systemctl status tgt

# Просмотр target и LUN
sudo tgt-admin --show
sudo tgtadm --mode target --op show

# Просмотр LVM (если используется block тип)
sudo lvdisplay
sudo lvs
sudo vgs

# Просмотр созданных LUN
ls -la /dev/ubuntu-vg/
lsblk

# Firewall
sudo ufw status verbose
sudo ufw allow from 217.71.138.1 to any port 3260 proto tcp

# Логи
sudo journalctl -u tgt.service -f
tail -f /var/log/syslog | grep tgt
```

### 6.2 Команды на клиенте (Initiator - CentOS 217.71.138.1)

```bash
# Установка iscsi-initiator-utils
sudo yum install -y iscsi-initiator-utils

# Обнаружение target
sudo iscsiadm -m discovery -t sendtargets -p 172.16.8.169
# или с дополнительными параметрами
sudo iscsiadm -m discovery -t sendtargets -p 172.16.8.169 --discover -o update \
    -n node.session.auth.username -v iscsi-user \
    -n node.session.auth.password -v StrongPass123

# Настройка CHAP (альтернативный способ)
sudo iscsiadm -m node -o update -n node.session.auth.username -v iscsi-user
sudo iscsiadm -m node -o update -n node.session.auth.password -v StrongPass123

# Подключение
sudo iscsiadm -m node --login
sudo iscsiadm -m node --login -p 172.16.8.169

# Отключение
sudo iscsiadm -m node --logout
sudo iscsiadm -m node --logoutall=all

# Просмотр сессий
sudo iscsiadm -m session -o show
sudo iscsiadm -m session -P 3    # Детальная информация

# Просмотр дисков
lsblk
sudo lsscsi
sudo fdisk -l | grep "^Disk /dev/sd"

# Пересканирование
sudo iscsiadm -m node --rescan

# Автозапуск
sudo systemctl enable iscsid
sudo systemctl enable iscsi
```

---

## 7. Типичные ошибки и их решение

### 7.1 Ошибки запуска TGT

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Failed to initialize RDMA` | Модули RDMA не загружены | Игнорировать (не критично для TCP) |
| `device already exists` | LUN уже зарегистрирован | `sudo tgt-admin --delete ALL` |
| `EndBlock has no StartBlock` | Синтаксическая ошибка в конфиге | Проверить скобки `<target>` и `</target>` |
| `Transport endpoint is not connected` | Демон не запущен | `sudo systemctl start tgt` |

### 7.2 Ошибки подключения клиента

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `Connection timed out` | Firewall блокирует порт 3260 | `sudo ufw allow from IP to port 3260` |
| `Connection refused` | TGT не слушает порт | Проверить `netstat -tlnp \| grep 3260` |
| `Authentication failed` | Неправильный CHAP пароль | Проверить `incominguser` в конфиге |
| `No route to host` | Сеть недоступна | Проверить IP и маршрутизацию |

### 7.3 Ошибки LUN

| Проблема | Причина | Решение |
|----------|---------|---------|
| LUN не отображаются | Нет rescan | `iscsiadm -m node --rescan` |
| LUN отображаются как 0 байт | Backing store недоступен | Проверить права доступа к устройству |
| LUN пропадают после reboot | Автозагрузка не настроена | `systemctl enable tgt` |

---

## 8. Сценарии для защиты

### 8.1 Объясните, что выводит эта команда:

```bash
sudo tgt-admin --show
```

**Ожидаемый ответ:**
- Список всех target
- Для каждого target: IQN, состояние, LUN'ы
- Для каждого LUN: номер, тип, размер, путь к backing store
- Информацию об авторизации (CHAP user)
- ACL (разрешенные IP)

### 8.2 Что произойдет, если изменить конфигурацию без перезапуска?

**Ответ:**
Изменения не вступят в силу. Необходимо выполнить:
```bash
sudo tgt-admin --update ALL   # Применить изменения без перезапуска
# или
sudo systemctl restart tgt    # Полный перезапуск
```

### 8.3 Как добавить третий LUN без остановки службы?

**Ответ:**
```bash
# Добавить в конфигурацию
echo 'backing-store /dev/ubuntu-vg/iscsi_lun2' | sudo tee -a /etc/tgt/targets.conf

# Применить без перезапуска
sudo tgt-admin --update ALL

# Или через tgtadm
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 3 -b /dev/ubuntu-vg/iscsi_lun2
```

### 8.4 Почему после перезагрузки пропали LUN в RAM?

**Ответ:**
RAM LUN хранятся в tmpfs, которая монтируется в оперативной памяти. При перезагрузке:
1. Вся оперативная память очищается
2. tmpfs размонтируется
3. Данные теряются безвозвратно

**Решение:** Добавить tmpfs в `/etc/fstab`:
```bash
echo 'tmpfs /mnt/ram_iscsi tmpfs defaults,size=1024M 0 0' | sudo tee -a /etc/fstab
```

---

## 9. Контрольные вопросы для проверки

### Базовый уровень
1. Что означает аббревиатура iSCSI?
2. Какой порт использует iSCSI по умолчанию?
3. Чем отличается Target от Initiator?
4. Что такое LUN?
5. Какой протокол используется для аутентификации iSCSI?

### Средний уровень
6. В чем разница между CHAP и Mutual CHAP?
7. Какие типы backing store существуют в tgt?
8. Как проверить, что iSCSI LUN'ы видны на клиенте?
9. Что такое IQN и из каких частей он состоит?
10. Почему TGT используется вместо istgt в Ubuntu 22.04?

### Продвинутый уровень
11. Как увеличить размер LUN без потери данных?
12. Как обеспечить автоматическое переподключение после перезагрузки?
13. Какие методы защиты iSCSI трафика существуют?
14. В чем отличие работы tgt в userspace от LIO в kernel?
15. Как диагностировать проблему "Transport endpoint is not connected"?

---

## 10. Шпаргалка для защиты (быстро запомнить)

```
iSCSI = SCSI over TCP/IP
Target = сервер (отдает диски)
Initiator = клиент (подключается)
LUN = номер диска (0,1,2...)
IQN = уникальное имя target
CHAP = аутентификация по паролю
Порт = 3260/tcp

Команды:
сервер: tgt-admin --show, systemctl status tgt
клиент: iscsiadm -m session -o show, lsblk
firewall: ufw allow from IP to any port 3260

Типы LUN:
0 → RAM (tmpfs)      - быстро, но данные теряются
1 → Block (LVM)      - надежно, высокая скорость
2 → File (файл)      - просто, но медленнее

Конфигурация target:
<target iqn.год-месяц.домен:имя>
    incominguser логин пароль
    initiator-address IP_клиента
    backing-store /путь/к/устройству
</target>
```

---

**Удачи на защите! Основное — понимать разницу между Target/Initiator, знать команды для проверки и уметь объяснить что такое LUN, IQN и CHAP.**