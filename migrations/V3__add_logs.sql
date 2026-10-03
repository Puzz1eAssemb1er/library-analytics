-- Миграция V3: таблицы для логирования работы автоматизации
-- notifications_log — журнал отправленных уведомлений
-- error_log — журнал ошибок workflow n8n

CREATE TABLE notifications_log (
    id SERIAL PRIMARY KEY,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT
);

CREATE TABLE error_log (
    id SERIAL PRIMARY KEY,
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    workflow_name TEXT,
    error_message TEXT
);