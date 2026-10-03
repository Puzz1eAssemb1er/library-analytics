-- Генерация тестовых данных для проекта «Библиотека под контролем»
-- Создаёт 100 читателей и ~500 выдач поверх существующих данных
-- Использует random() и generate_series() для синтетических данных

-- ШАГ 1: Генерация 100 читателей с согласованными именем и фамилией
INSERT INTO readers (first_name, last_name, phone, email)
SELECT 
    CASE WHEN r.is_male 
        THEN (ARRAY['Иван','Пётр','Сергей','Алексей','Дмитрий','Андрей','Михаил','Николай'])[floor(random()*8+1)]
        ELSE (ARRAY['Мария','Елена','Ольга','Татьяна','Анна','Наталья','Ирина','Светлана'])[floor(random()*8+1)]
    END,
    CASE WHEN r.is_male
        THEN (ARRAY['Иванов','Петров','Сидоров','Кузнецов','Смирнов','Волков','Морозов','Новиков','Фёдоров','Егоров','Павлов','Семёнов','Голубев','Виноградов','Богданов','Воробьёв'])[floor(random()*16+1)]
        ELSE (ARRAY['Иванова','Петрова','Сидорова','Кузнецова','Смирнова','Волкова','Морозова','Новикова','Фёдорова','Егорова','Павлова','Семёнова','Голубева','Виноградова','Богданова','Воробьёва'])[floor(random()*16+1)]
    END,
    '+7-900-' || LPAD(floor(random() * 10000000)::TEXT, 7, '0'),
    'reader' || (100 + r.row_num) || '@example.com'
FROM (
    SELECT gs AS row_num, (random() < 0.5) AS is_male
    FROM generate_series(1, 100) AS gs
) r;

-- ШАГ 2: Генерируем 500 выдач

-- ID берутся случайной выборкой из реальных записей — работает при любых пропусках в нумерации

WITH generated_loans AS (
    SELECT 
        (SELECT id FROM books ORDER BY random() LIMIT 1) AS book_id,
        (SELECT id FROM readers ORDER BY random() LIMIT 1) AS reader_id,
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