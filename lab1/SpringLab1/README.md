# Конфигурация CDC с Debezium и ElasticSearch

Данная лабораторная работа демонстрирует применение Change Data Capture (CDC) с использованием Debezium для отслеживания изменений в PostgreSQL и передачи этих изменений в ElasticSearch.

## Компоненты системы

1. **PostgreSQL** - источник данных с включенной логической репликацией
2. **Kafka** - брокер сообщений для передачи событий изменения данных
3. **Kafka Connect** - платформа для связи Kafka с другими системами
4. **Debezium PostgreSQL Connector** - отслеживает изменения в PostgreSQL
5. **ElasticSearch Sink Connector** - передает данные из Kafka в ElasticSearch
6. **ElasticSearch** - хранилище для индексации и поиска данных

## Как запустить

```bash
# Запуск всей инфраструктуры
docker-compose up -d

# Проверка статуса контейнеров
docker-compose ps

# Проверка логов Kafka Connect для диагностики
docker-compose logs kafka-connect

# Проверка логов коннекторов
docker-compose logs connector-setup
docker-compose logs elasticsearch-connector
```

## Проверка работы CDC

После запуска и настройки коннекторов можно проверить работу CDC, выполнив операции CRUD в PostgreSQL:

1. **CREATE**: Вставка новых записей в таблицы PostgreSQL
   ```sql
   INSERT INTO your_table (column1, column2) VALUES ('value1', 'value2');
   ```

2. **READ**: Проверка данных в ElasticSearch
   ```bash
   # Запуск скрипта проверки
   ./check-elasticsearch.sh
   ```

3. **UPDATE**: Обновление записей в PostgreSQL
   ```sql
   UPDATE your_table SET column1 = 'new_value' WHERE id = 1;
   ```

4. **DELETE**: Удаление записей в PostgreSQL
   ```sql
   DELETE FROM your_table WHERE id = 1;
   ```

После каждой операции можно проверить, что изменения отразились в ElasticSearch, запустив скрипт проверки.

## Конфигурация коннекторов

### PostgreSQL Connector (Debezium)
Коннектор настроен на отслеживание всех изменений в схеме `public`.

### ElasticSearch Sink Connector
Коннектор настроен на передачу данных из всех топиков PostgreSQL в ElasticSearch с префиксом `cdc-`.

## Полезные URL

- PostgreSQL: jdbc:postgresql://localhost:5433/mydb
- Kafka: localhost:9092
- Kafka Connect REST API: http://localhost:8085
- ElasticSearch: http://localhost:9200
- ElasticSearch API для проверки индексов: http://localhost:9200/_cat/indices
- Kibana (если установлена): http://localhost:5601 