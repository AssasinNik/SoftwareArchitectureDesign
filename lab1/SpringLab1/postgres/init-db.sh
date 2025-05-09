#!/bin/bash
set -e

echo "Настройка PostgreSQL для логической репликации с wal2json..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Создаем схему, если ее еще нет
    CREATE SCHEMA IF NOT EXISTS public;
    
    -- Проверяем установку wal2json
    SELECT name, setting FROM pg_settings WHERE name LIKE 'wal%';
    SELECT * FROM pg_extension;
    SELECT extname FROM pg_extension WHERE extname = 'wal2json';
    
    -- Устанавливаем необходимые параметры для логической репликации
    ALTER SYSTEM SET wal_level = 'logical';
    ALTER SYSTEM SET max_wal_senders = '10';
    ALTER SYSTEM SET max_replication_slots = '10';
    ALTER SYSTEM SET track_commit_timestamp = 'on';
    
    -- Перезагружаем конфигурацию
    SELECT pg_reload_conf();
EOSQL

# Даем время PostgreSQL на применение настроек
sleep 5

# Создаем публикацию и слот репликации
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Создаем публикацию для всех таблиц
    DROP PUBLICATION IF EXISTS pub;
    CREATE PUBLICATION pub FOR ALL TABLES;
    
    -- Удаляем слот, если он уже существует
    SELECT pg_drop_replication_slot(slot_name) 
    FROM pg_replication_slots 
    WHERE slot_name = 'test_slot' AND NOT active;
    
    -- Создаем новый слот репликации с wal2json
    SELECT pg_create_logical_replication_slot('test_slot', 'wal2json') 
    WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'test_slot');
    
    -- Проверяем созданные ресурсы
    SELECT * FROM pg_publication;
    SELECT * FROM pg_replication_slots;
EOSQL

echo "Инициализация базы данных PostgreSQL для репликации успешно завершена!"
echo "Слот репликации 'test_slot' с wal2json и публикация 'pub' созданы." 