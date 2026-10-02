-- Аналитические запросы для проекта "Библиотека под контролем"
-- Эти запросы используются в отчётах Metabase и в автоматизации n8n

-- 1. Топ авторов по количеству книг
-- Используется в дашборде Metabase
SELECT 
    a.last_name AS "Фамилия",
    a.first_name AS "Имя",
    COUNT(b.id) AS "Количество книг"
FROM authors a
JOIN books b ON a.id = b.author_id
GROUP BY a.id, a.last_name, a.first_name
ORDER BY COUNT(b.id) DESC;

-- 2. Популярность книг (сколько раз брали)
-- Используется в дашборде Metabase
SELECT 
    b.title AS "Книга",
    COUNT(l.id) AS "Количество выдач"
FROM books b
LEFT JOIN loans l ON b.id = l.book_id
GROUP BY b.id, b.title
ORDER BY COUNT(l.id) DESC;

-- 3. Просроченные выдачи
-- Используется в дашборде Metabase и в workflow n8n
SELECT 
    r.last_name || ' ' || r.first_name AS reader_name,
    b.title AS book_title,
    (CURRENT_DATE - l.loan_date) AS days_overdue
FROM loans l
JOIN readers r ON l.reader_id = r.id
JOIN books b ON l.book_id = b.id
WHERE l.return_date IS NULL
    AND (CURRENT_DATE - l.loan_date) > 5
ORDER BY days_overdue DESC;

-- 4. Читатели без единой выдачи (для отдела продвижения)
SELECT 
    r.last_name AS "Фамилия",
    r.first_name AS "Имя",
    r.email AS "Email"
FROM readers r
LEFT JOIN loans l ON r.id = l.reader_id
WHERE l.id IS NULL
ORDER BY r.last_name;

-- 5. Средний срок возврата книги (метрика качества обслуживания)
SELECT 
    ROUND(AVG(return_date - loan_date), 1) AS "Средний срок возврата, дней"
FROM loans
WHERE return_date IS NOT NULL;