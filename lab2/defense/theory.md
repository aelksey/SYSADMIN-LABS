# Теория для защиты лабораторной работы
## Тема: WMI и WQL запросы в PowerShell

---

## 1. WMI (Windows Management Instrumentation)

### 1.1 Что такое WMI?

**WMI (Windows Management Instrumentation)** - это технология Microsoft, предоставляющая унифицированный интерфейс для управления и мониторинга систем Windows.

**Ключевые понятия:**
- **Инструментарий** - набор средств для управления системой
- **Инструментирование** - процесс предоставления управляющих интерфейсов
- **Единый интерфейс** - стандартный способ доступа к разным компонентам системы

### 1.2 Архитектура WMI

```
┌─────────────────────────────────────────┐
│         Управляющие приложения          │
│     (PowerShell, WMIC, Scripts и т.д.)   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           API WMI (COM/DCOM)            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Репозиторий WMI (база данных)    │
│      Хранит классы и определения         │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Поставщики WMI (Providers)       │
│   (Registry, CIMWin32, ActiveDirectory)  │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Управляемые ресурсы              │
│   (Реестр, Службы, Диски, Процессы)      │
└─────────────────────────────────────────┘
```

### 1.3 Компоненты WMI

| Компонент | Описание |
|-----------|----------|
| **WMI Service** | Служба winmgmt, обеспечивающая работу WMI |
| **Репозиторий** | База данных объектов CIM (Common Information Model) |
| **Поставщики** | Мосты между WMI и управляемыми ресурсами |
| **WQL** | Язык запросов к WMI (аналог SQL) |
| **API** | Интерфейсы для доступа (COM, .NET, PowerShell) |

### 1.4 Основные классы WMI

| Класс | Описание | Свойства |
|-------|----------|----------|
| `Win32_ComputerSystem` | Информация о компьютере | Name, Manufacturer, Model, TotalPhysicalMemory |
| `Win32_UserAccount` | Учетные записи пользователей | Name, Domain, SID, Status |
| `Win32_NetworkAdapter` | Сетевые адаптеры | Name, MACAddress, NetEnabled, Speed |
| `Win32_StartupCommand` | Программы автозагрузки | Name, Command, Location, User |
| `Win32_Processor` | Информация о процессоре | Name, LoadPercentage, MaxClockSpeed |
| `Win32_OperatingSystem` | Информация об ОС | Name, Version, TotalVisibleMemorySize |

---

## 2. WQL (WMI Query Language)

### 2.1 Что такое WQL?

**WQL** - диалект SQL (Structured Query Language), разработанный Microsoft для выполнения запросов к WMI.

**Особенности WQL:**
- Поддерживает SELECT, FROM, WHERE
- НЕ поддерживает JOIN (объединение таблиц)
- Не поддерживает ORDER BY (сортировку)
- Регистронезависимый

### 2.2 Синтаксис WQL

```sql
SELECT <свойства> FROM <класс> [WHERE <условие>]
```

**Элементы синтаксиса:**
- `SELECT *` - выбрать все свойства
- `SELECT Name, Size` - выбрать указанные свойства
- `FROM Win32_LogicalDisk` - из указанного класса
- `WHERE Size > 1000` - с условием фильтрации

### 2.3 Операторы WQL

| Тип | Операторы | Пример |
|-----|-----------|--------|
| **Сравнения** | =, <, >, <=, >=, != | `WHERE LoadPercentage > 50` |
| **Логические** | AND, OR, NOT | `WHERE Name LIKE '%temp%' AND Size > 100` |
| **Строковые** | LIKE, IS NULL, IS NOT NULL | `WHERE Name LIKE 'Win%'` |

### 2.4 Примеры WQL запросов

```sql
-- Простой запрос
SELECT Name FROM Win32_ComputerSystem

-- С условием
SELECT Name, Command FROM Win32_StartupCommand WHERE Location LIKE '%Run%'

-- С несколькими условиями
SELECT Name, Size FROM Win32_LogicalDisk WHERE Size > 10000 AND DriveType = 3
```

---

## 3. PowerShell и WMI

### 3.1 Командлеты для работы с WMI

| Командлет | Описание | Статус |
|-----------|----------|--------|
| `Get-WmiObject` | Получение объектов WMI | Устаревший |
| `Get-CimInstance` | Получение объектов CIM | Современный |
| `Invoke-WmiMethod` | Вызов методов WMI | Устаревший |
| `Invoke-CimMethod` | Вызов методов CIM | Современный |
| `Register-WmiEvent` | Подписка на события WMI | Устаревший |
| `Register-CimIndicationEvent` | Подписка на события CIM | Современный |

### 3.2 Различия Get-WmiObject и Get-CimInstance

| Характеристика | Get-WmiObject | Get-CimInstance |
|----------------|---------------|-----------------|
| **Протокол** | DCOM | WS-Management (WinRM) |
| **Удаленные подключения** | Сложные настройки DCOM | Простая настройка WinRM |
| **Производительность** | Ниже | Выше |
| **Статус** | Устаревший | Актуальный |
| **Firewall** | Требует DCOM порты | Использует HTTP/HTTPS (5985/5986) |

### 3.3 Синтаксис запросов

```powershell
# Устаревший синтаксис (Get-WmiObject)
Get-WmiObject -Query "SELECT Name FROM Win32_ComputerSystem"
Get-WmiObject -Class Win32_ComputerSystem

# Современный синтаксис (Get-CimInstance)
Get-CimInstance -Query "SELECT Name FROM Win32_ComputerSystem"
Get-CimInstance -ClassName Win32_ComputerSystem
```

---

## 4. Разбор кода лабораторной работы

### 4.1 Часть 1: Получение имени компьютера

```powershell
$computerName = (Get-WmiObject -Query "SELECT Name FROM Win32_ComputerSystem").Name
```

**Что происходит:**
1. Выполняется WQL запрос к классу `Win32_ComputerSystem`
2. Запрашивается только свойство `Name`
3. Возвращается объект с этим свойством
4. Извлекается значение свойства `Name`

### 4.2 Часть 2: Получение списка пользователей

```powershell
$users = Get-WmiObject -Query "SELECT Name FROM Win32_UserAccount"
```

**Особенности:**
- Возвращает всех пользователей системы (локальных и доменных)
- Свойство `Name` содержит имя учетной записи

### 4.3 Часть 3: Получение сетевых адаптеров

```powershell
$networkAdapters = Get-WmiObject -Query "SELECT Name, MACAddress FROM Win32_NetworkAdapter WHERE MACAddress IS NOT NULL"
```

**Важные моменты:**
- `WHERE MACAddress IS NOT NULL` - исключает виртуальные адаптеры
- Возвращает только физические адаптеры с реальными MAC-адресами

### 4.4 Часть 4: Получение программ автозагрузки

```powershell
$startupPrograms = Get-WmiObject -Query "SELECT Name, Command, Location FROM Win32_StartupCommand"
```

**Что содержит:**
- `Name` - имя программы
- `Command` - команда запуска (путь к файлу)
- `Location` - расположение в реестре или папке автозагрузки

**Источники автозагрузки:**
```
HKLM\Software\Microsoft\Windows\CurrentVersion\Run
HKCU\Software\Microsoft\Windows\CurrentVersion\Run
HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce
HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup
```

### 4.5 Часть 5: Сохранение в файл

```powershell
$fileContent = @(
    "[users]"
    ($users | ForEach-Object { $_.Name })
    ""
    "[network]"
    ($networkAdapters | ForEach-Object { "$($_.Name), $($_.MACAddress)" })
    ""
    "[startup]"
    ($startupPrograms | ForEach-Object { "Name: $($_.Name), Command: $($_.Command), Location: $($_.Location)" })
)
```

**Структура вывода:**
- `@(...)` - оператор создания массива
- `[users]` - заголовок секции (формат INI-подобный)
- Пустые строки для разделения секций

---

## 5. Конвейер PowerShell (Pipeline)

### 5.1 Что такое конвейер?

**Конвейер** - механизм передачи объектов между командлетами через символ `|`.

```powershell
$users | ForEach-Object { Write-Host $_.Name }
```

### 5.2 Автоматические переменные конвейера

| Переменная | Описание |
|------------|----------|
| `$_` | Текущий объект в конвейере (псевдоним: `$PSItem`) |
| `$input` | Все объекты во входном потоке |

### 5.3 Скриптовые блоки

```powershell
{ Write-Host $_.Name }
```
- Фигурные скобки `{ }` - определение блока кода
- Может выполняться позже, многократно
- Используется с `ForEach-Object`, `Where-Object`

---

## 6. Работа с файлами

### 6.1 Создание каталога

```powershell
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force
}
```

| Командлет | Назначение |
|-----------|------------|
| `Test-Path` | Проверка существования пути |
| `New-Item` | Создание нового элемента |
| `-ItemType Directory` | Тип - каталог |
| `-Force` | Принудительное создание (с перезаписью) |

### 6.2 Формирование пути

```powershell
$reportFile = Join-Path $reportDir "$computerName.rep"
```

`Join-Path` - объединяет части пути с правильным разделителем (`\`)

### 6.3 Запись в файл

```powershell
$fileContent | Out-File -FilePath $reportFile -Encoding utf8
```

| Параметр | Значение |
|----------|----------|
| `-FilePath` | Путь к файлу |
| `-Encoding` | Кодировка (UTF-8, ASCII, Default) |

---

## 7. Возможные ошибки и их решение

### 7.1 "Недопустимый класс" (Invalid class)

**Причина:** Класс WMI не зарегистрирован или поврежден репозиторий

**Решение:**
```powershell
# Проверка репозитория
winmgmt /verifyrepository

# Восстановление репозитория
winmgmt /salvagerepository

# Сброс репозитория
net stop winmgmt
rmdir /s /q C:\Windows\System32\wbem\Repository
net start winmgmt
```

### 7.2 "Access denied" (Отказано в доступе)

**Причина:** Недостаточно прав

**Решение:** Запустить PowerShell от имени администратора

### 7.3 "RPC server unavailable" (Сервер RPC недоступен)

**Причина:** Остановлена служба WMI

**Решение:**
```powershell
net start winmgmt
```

---

## 8. Вопросы для защиты

### 8.1 Теоретические вопросы

1. **Что такое WMI и для чего используется?**
2. **Назовите основные компоненты архитектуры WMI**
3. **Что такое WQL и чем отличается от SQL?**
4. **Какие классы WMI использовались в работе?**
5. **В чем разница между Get-WmiObject и Get-CimInstance?**
6. **Что такое репозиторий WMI и где он хранится?**
7. **Какие источники автозагрузки существуют в Windows?**

### 8.2 Практические вопросы

8. **Как выполнить WQL запрос в PowerShell?**
9. **Что означает символ `$_` в PowerShell?**
10. **Для чего используется конструкция `@(...)`?**
11. **Как работает конвейер `|` в PowerShell?**
12. **Что делает командлет `Join-Path`?**
13. **Как задать кодировку при сохранении файла?**
14. **Как проверить существование каталога?**

### 8.3 Ситуационные вопросы

15. **Что делать, если класс Win32_StartupCommand не найден?**
16. **Почему нужно фильтровать сетевые адаптеры по `MACAddress IS NOT NULL`?**
17. **В чем преимущество UTF-8 перед другими кодировками?**
18. **Как добавить обработку ошибок в скрипт?**

---

## 9. Практические примеры для демонстрации

### 9.1 Просмотр всех доступных классов WMI

```powershell
Get-WmiObject -List | Select-Object -First 20 Name
```

### 9.2 Интерактивный просмотр свойств класса

```powershell
Get-WmiObject -Class Win32_ComputerSystem | Get-Member
```

### 9.3 Запрос с несколькими условиями

```powershell
Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk WHERE DriveType = 3 AND FreeSpace > 1000000000"
```

### 9.4 Подсчет количества объектов

```powershell
(Get-WmiObject -Class Win32_UserAccount).Count
```

### 9.5 Форматирование вывода

```powershell
Get-WmiObject -Class Win32_NetworkAdapter | 
    Where-Object {$_.MACAddress -ne $null} | 
    Select-Object Name, MACAddress |
    Format-Table -AutoSize
```

---

## 10. Памятка по основным понятиям

| Термин | Определение |
|--------|-------------|
| **WMI** | Технология управления Windows |
| **CIM** | Общая информационная модель |
| **WQL** | Язык запросов к WMI |
| **Репозиторий** | База данных классов WMI |
| **Поставщик** | Мост между WMI и ресурсом |
| **Класс** | Шаблон для описания объекта |
| **Экземпляр** | Конкретный объект класса |
| **Свойство** | Характеристика объекта |
| **Метод** | Действие над объектом |

---

## 11. Дополнительные материалы для изучения

### 11.1 Полезные команды

```powershell
# Просмотр всех классов WMI
Get-WmiObject -List

# Поиск класса по имени
Get-WmiObject -List | Where-Object {$_.Name -like "*Startup*"}

# Просмотр свойств класса
Get-WmiObject -Class Win32_StartupCommand | Get-Member -MemberType Property

# Просмотр методов класса
Get-WmiObject -Class Win32_Process | Get-Member -MemberType Method
```

### 11.2 Часто используемые классы WMI

| Класс | Назначение |
|-------|------------|
| `Win32_Service` | Управление службами |
| `Win32_Process` | Управление процессами |
| `Win32_LogicalDisk` | Информация о дисках |
| `Win32_Environment` | Переменные среды |
| `Win32_Registry` | Работа с реестром |
| `Win32_BIOS` | Информация о BIOS |
| `Win32_Product` | Установленные программы |

---

**Удачи на защите!** 🎯

Основные моменты, которые нужно запомнить:
1. WMI - это технология управления Windows
2. WQL - язык запросов, похожий на SQL
3. Get-WmiObject устарел, но используется в учебных целях
4. Конвейер `|` передает объекты между командлетами
5. `$_` - текущий объект в конвейере
6. Класс `Win32_StartupCommand` хранит информацию об автозагрузке
7. Кодировка UTF-8 нужна для корректного отображения русских символов