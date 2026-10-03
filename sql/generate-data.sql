-- Генерация тестовых данных для проекта «Библиотека под контролем»
-- Создаёт 100 читателей и ~500 выдач поверх существующих данных
-- Использует random() и generate_series() для синтетических данных

-- ШАГ 1: Добавляем 100 новых читателей
INSERT INTO readers (first_name, last_name, phone, email)
SELECT 
    (ARRAY['Иван', 'Пётр', 'Сергей', 'Алексей', 'Дмитрий', 'Андрей', 'Михаил', 'Николай',
           'Мария', 'Елена', 'Ольга', 'Татьяна', 'Анна', 'Наталья', 'Ирина', 'Светлана'])[floor(random() * 16 + 1)],
    (ARRAY['Иванов', 'Петров', 'Сидоров', 'Кузнецов', 'Смирнов', 'Волков', 'Морозов', 'Новиков',
           'Фёдоров', 'Егоров', 'Павлов', 'Семёнов', 'Голубев', 'Виноградов', 'Богданов', 'Воробьёв'])[floor(random() * 16 + 1)],
    '+7-900-' || LPAD(floor(random() * 10000000)::TEXT, 7, '0'),
    'reader' || (100 + gs) || '@example.com'
FROM generate_series(1, 100) AS gs;

-- ШАГ 2: Генерируем 500 выдач
-- Сначала фиксируем loan_date, потом на его основе считаем return_date

WITH generated_loans AS (
    SELECT 
        floor(random() * 8 + 1)::INT AS book_id,
        floor(random() * 100 + 8)::INT AS reader_id,
        (CURRENT_DATE - (floor(random() * 95 + 25))::INT)::DATE AS loan_date,
        random() AS return_chance,
        (floor(random() * 20 + 3))::INT AS loan_duration
    FROM generate_series(1, 500)
)
INSERT INTO loans (book_id, reader_id, loan_date, return_date)
SELECT 
    book_id,
    reader_id,
    loan_date,
    CASE 
        WHEN return_chance < 0.7 
        THEN loan_date + loan_duration
        ELSE NULL
    END
FROM generated_loans;