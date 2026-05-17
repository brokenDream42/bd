# Семестровая работа: Учет товарооборота розничных торговых предприятий

## Структура проекта

```
semestr/
├── 01_schema.sql          -- Базовая схема БД + данные (из 1-й части)
├── 02_audit.sql           -- Таблица аудита (audit_log)
├── 03_triggers.sql        -- Триггеры для SELLERS, CUSTOMERS, SALES
├── 04_pkg_entity_crud.sql -- Пакет CRUD-процедур
├── 05_pkg_audit.sql       -- Пакет работы с логом (просмотр, откат, отчет)
├── 06_tests.sql           -- Тестовые сценарии
├── gui.py                 -- Графическое приложение (Python + tkinter + cx_Oracle)
├── report.doc             -- Отчет 1-й части (исходный)
└── semestrovaya.doc       -- Задание на семестровую (исходное)
```

## Выбранные 3 таблицы

1. **SELLERS** (продавцы)
2. **CUSTOMERS** (покупатели)
3. **SALES** (продажи)

## Что реализовано

| Требование | Реализация |
|---|---|
| Пакет CRUD (3 б.) | `pkg_entity_crud` — INSERT/UPDATE/DELETE для 3 таблиц |
| Структура аудита (1 б.) | Таблица `audit_log` с JSON-хранением старых/новых данных |
| Триггеры (6 б.) | `trg_sellers_audit`, `trg_customers_audit`, `trg_sales_audit` |
| Просмотр лога (2 б.) | `pkg_audit.view_log` с фильтрами по дате и типу |
| Откат операции (3 б.) | `pkg_audit.rollback_operation` восстанавливает старое значение |
| Сводный отчет (5 б.) | `pkg_audit.get_report` с 3 флагами сортировки |
| GUI (10 б.) | `gui.py` — вкладки CRUD, журнал аудита, отчеты |

## Установка и запуск

### 1. Подготовка базы данных (Oracle)

Выполните скрипты в SQL*Plus или SQL Developer в строгом порядке:

```sql
@01_schema.sql
@02_audit.sql
@03_triggers.sql
@04_pkg_entity_crud.sql
@05_pkg_audit.sql
```

### 2. Тестирование

```sql
@06_tests.sql
```

### 3. Установка зависимостей для GUI

```bash
pip install cx_Oracle
```

> **Важно:** на Windows может потребоваться установка Oracle Instant Client. Скачайте с [oracle.com](https://www.oracle.com/database/technologies/instant-client/downloads.html) и добавьте в `PATH`.

### 4. Запуск GUI

```bash
python gui.py
```

Или в проводнике — двойной клик по `gui.py`.

### 5. Подключение в GUI

В верхней панели введите:
- **User** / **Password** — учетные данные Oracle
- **Host** — адрес сервера (например, `localhost`)
- **Port** — обычно `1521`
- **Service** — имя сервиса (например, `XE` или `ORCLPDB1`)

Нажмите **"Подключиться"**.

## Вкладки приложения

| Вкладка | Описание |
|---|---|
| 👤 Продавцы | CRUD для таблицы `SELLERS` |
| 🛒 Покупатели | CRUD для таблицы `CUSTOMERS` |
| 💰 Продажи | CRUD для таблицы `SALES` |
| 📋 Журнал аудита | Просмотр `audit_log` с фильтрами + кнопка отката |
| 📊 Отчет | Сводный отчет с чекбоксами флагов сортировки |

## Примечания

- Все триггеры типа `AFTER INSERT OR UPDATE OR DELETE` — это гарантирует корректное считывание `GENERATED ALWAYS AS IDENTITY` первичного ключа.
- Данные до/после операции хранятся в формате JSON (`JSON_OBJECT`), что позволяет легко восстанавливать состояние процедурой `rollback_operation`.
- При откате операции используется `JSON_VALUE` с указанием типов (`RETURNING NUMBER`).
