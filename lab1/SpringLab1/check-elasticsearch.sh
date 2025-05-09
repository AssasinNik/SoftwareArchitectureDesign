#!/bin/bash
set -e

echo "Проверка данных в ElasticSearch..."

# Проверка состояния кластера
echo "1. Проверка здоровья кластера ElasticSearch:"
curl -s http://localhost:9200/_cluster/health | jq

# Список всех индексов с префиксом cdc-
echo -e "\n2. Список индексов CDC:"
curl -s http://localhost:9200/_cat/indices/cdc-* | column -t

# Проверка количества документов в каждом индексе
echo -e "\n3. Количество документов в каждом индексе:"
for index in $(curl -s http://localhost:9200/_cat/indices/cdc-* | awk '{print $3}'); do
    echo "Индекс $index:"
    curl -s "http://localhost:9200/$index/_count" | jq .count
done

# Демонстрация CRUD операций на примере одной из таблиц
echo -e "\n4. Демонстрация CRUD операций:"

# Получить название первого индекса для демонстрации
first_index=$(curl -s http://localhost:9200/_cat/indices/cdc-* | head -1 | awk '{print $3}')

if [ -n "$first_index" ]; then
    echo "Используем индекс: $first_index"
    
    # Показать несколько записей из индекса (CREATE)
    echo -e "\n4.1. Существующие данные (CREATE):"
    curl -s "http://localhost:9200/$first_index/_search?pretty" -H 'Content-Type: application/json' -d '
    {
      "size": 5,
      "sort": [
        {
          "_id": "asc"
        }
      ]
    }' | jq '.hits.hits'
    
    # Примечание: в реальной системе здесь можно было бы выполнить SQL-запрос в PostgreSQL 
    # для модификации данных, и затем наблюдать, как изменения попадают в ElasticSearch через CDC.
    
    echo -e "\n4.2. Для демонстрации UPDATE и DELETE:"
    echo "Выполните в PostgreSQL следующие запросы:"
    echo "UPDATE таблица SET поле = 'новое значение' WHERE условие;"
    echo "DELETE FROM таблица WHERE условие;"
    echo "И затем запустите этот скрипт снова для проверки изменений."
else
    echo "Индексы CDC не найдены. Возможно, нет данных или коннектор не настроен."
fi

echo -e "\n5. Мониторинг статуса коннекторов:"
curl -s http://localhost:8085/connectors | jq

echo -e "\n6. Детальный статус ElasticSearch коннектора:"
curl -s http://localhost:8085/connectors/elasticsearch-sink/status | jq

echo -e "\nПроверка завершена!" 