-- Тесты бизнес-логики
-- Проверяют, что SQL-запросы возвращают ожидаемые результаты

-- ТЕСТ 5: RFM-сегментация возвращает корректные категории
DO $$
DECLARE
    unknown_segments INT;
BEGIN
    WITH reader_stats AS (
        SELECT 
            r.id,
            COUNT(l.id) AS total_loans,
            COALESCE(CURRENT_DATE - MAX(l.loan_date), 9999) AS days_since_last_loan
        FROM readers r
        LEFT JOIN loans l ON r.id = l.reader_id
        GROUP BY r.id
    )
    SELECT COUNT(*) INTO unknown_segments
    FROM reader_stats
    WHERE CASE 
        WHEN days_since_last_loan = 9999 THEN 'Никогда не брал'
        WHEN days_since_last_loan <= 30 AND total_loans >= 2 THEN 'Активный'
        WHEN days_since_last_loan <= 60 THEN 'Затухающий'
        WHEN days_since_last_loan <= 90 THEN 'Спящий'
        ELSE 'Потерянный'
    END IS NULL;
    
    IF unknown_segments > 0 THEN
        RAISE EXCEPTION 'FAIL: % читателей не попали ни в один сегмент', unknown_segments;
    END IF;
    
    RAISE NOTICE 'PASS: все читатели корректно классифицированы по RFM';
END $$;

-- ТЕСТ 6: Количество читателей в сегментах равно общему числу читателей
DO $$
DECLARE
    total_readers INT;
    segmented_readers INT;
BEGIN
    SELECT COUNT(*) INTO total_readers FROM readers;
    
    WITH reader_stats AS (
        SELECT 
            r.id,
            COUNT(l.id) AS total_loans,
            COALESCE(CURRENT_DATE - MAX(l.loan_date), 9999) AS days_since_last_loan
        FROM readers r
        LEFT JOIN loans l ON r.id = l.reader_id
        GROUP BY r.id
    ),
    segmented AS (
        SELECT 
            CASE 
                WHEN days_since_last_loan = 9999 THEN 'Никогда не брал'
                WHEN days_since_last_loan <= 30 AND total_loans >= 2 THEN 'Активный'
                WHEN days_since_last_loan <= 60 THEN 'Затухающий'
                WHEN days_since_last_loan <= 90 THEN 'Спящий'
                ELSE 'Потерянный'
            END AS segment
        FROM reader_stats
    )
    SELECT COUNT(*) INTO segmented_readers FROM segmented;
    
    IF total_readers != segmented_readers THEN
        RAISE EXCEPTION 'FAIL: сегментировано % из % читателей', segmented_readers, total_readers;
    END IF;
    
    RAISE NOTICE 'PASS: все % читателей попали в сегментацию', total_readers;
END $$;

-- ТЕСТ 7: Расчёт просрочки не даёт отрицательных значений
DO $$
DECLARE
    negative_overdue INT;
BEGIN
    SELECT COUNT(*) INTO negative_overdue
    FROM loans
    WHERE return_date IS NULL 
      AND (CURRENT_DATE - loan_date) < 0;
    
    IF negative_overdue > 0 THEN
        RAISE EXCEPTION 'FAIL: найдено % выдач с отрицательной просрочкой', negative_overdue;
    END IF;
    
    RAISE NOTICE 'PASS: расчёт просрочки не даёт отрицательных значений';
END $$;

-- ТЕСТ 8: Средний срок возврата вычисляется только для возвращённых книг
DO $$
DECLARE
    avg_days NUMERIC;
BEGIN
    SELECT ROUND(AVG(return_date - loan_date), 1) INTO avg_days
    FROM loans
    WHERE return_date IS NOT NULL;
    
    IF avg_days IS NULL THEN
        RAISE EXCEPTION 'FAIL: средний срок возврата не вычислен';
    END IF;
    
    IF avg_days < 0 THEN
        RAISE EXCEPTION 'FAIL: средний срок возврата отрицательный: %', avg_days;
    END IF;
    
    RAISE NOTICE 'PASS: средний срок возврата книг = % дней', avg_days;
END $$;

-- ТЕСТ 9: Запрос «Популярность книг» включает книги с нулём выдач
DO $$
DECLARE
    books_in_report INT;
    books_total INT;
BEGIN
    SELECT COUNT(DISTINCT b.id) INTO books_in_report
    FROM books b
    LEFT JOIN loans l ON b.id = l.book_id;
    
    SELECT COUNT(*) INTO books_total FROM books;
    
    IF books_in_report != books_total THEN
        RAISE EXCEPTION 'FAIL: отчёт популярности содержит % книг вместо %', books_in_report, books_total;
    END IF;
    
    RAISE NOTICE 'PASS: отчёт популярности включает все % книг (в том числе с нулём выдач)', books_total;
END $$;