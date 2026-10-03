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

-- 6. Ранжирование читателей внутри сегмента
-- Демонстрирует оконную функцию RANK() OVER (PARTITION BY ...)
WITH reader_stats AS (
    SELECT 
        r.id,
        r.last_name || ' ' || r.first_name AS reader_name,
        COUNT(l.id) AS total_loans,
        COALESCE(CURRENT_DATE - MAX(l.loan_date), 9999) AS days_since_last_loan
    FROM readers r
    LEFT JOIN loans l ON r.id = l.reader_id
    GROUP BY r.id, r.last_name, r.first_name
),
segmented AS (
    SELECT 
        reader_name,
        total_loans,
        days_since_last_loan,
        CASE 
            WHEN days_since_last_loan = 9999 THEN 'Никогда не брал'
            WHEN days_since_last_loan <= 30 AND total_loans >= 2 THEN 'Активный'
            WHEN days_since_last_loan <= 60 THEN 'Затухающий'
            WHEN days_since_last_loan <= 90 THEN 'Спящий'
            ELSE 'Потерянный'
        END AS segment
    FROM reader_stats
)
SELECT 
    segment AS "Сегмент",
    RANK() OVER (PARTITION BY segment ORDER BY total_loans DESC) AS "Место в сегменте",
    reader_name AS "Читатель",
    total_loans AS "Всего выдач",
    days_since_last_loan AS "Дней с последней выдачи"
FROM segmented
ORDER BY segment, total_loans DESC;

-- 7. Динамика выдач по неделям с накопительным итогом
-- Демонстрирует оконные функции SUM() OVER и AVG() OVER с окном ROWS BETWEEN
WITH weekly_stats AS (
    SELECT 
        DATE_TRUNC('week', loan_date)::DATE AS week_start,
        COUNT(*) AS loans_in_week
    FROM loans
    WHERE loan_date >= CURRENT_DATE - INTERVAL '8 weeks'
    GROUP BY DATE_TRUNC('week', loan_date)
)
SELECT 
    week_start AS "Начало недели",
    loans_in_week AS "Выдач за неделю",
    SUM(loans_in_week) OVER (ORDER BY week_start) AS "Накопительно",
    ROUND(
        AVG(loans_in_week) OVER (ORDER BY week_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
        1
    ) AS "Скользящее среднее (3 недели)"
FROM weekly_stats
ORDER BY week_start;