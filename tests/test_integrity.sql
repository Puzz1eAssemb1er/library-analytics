-- Тесты целостности данных
-- Проверяют, что база находится в консистентном состоянии

-- ТЕСТ 1: Все книги имеют существующего автора
DO $$
DECLARE
    orphan_count INT;
BEGIN
    SELECT COUNT(*) INTO orphan_count
    FROM books b
    LEFT JOIN authors a ON b.author_id = a.id
    WHERE a.id IS NULL;
    
    IF orphan_count > 0 THEN
        RAISE EXCEPTION 'FAIL: найдено % книг без автора', orphan_count;
    END IF;
    
    RAISE NOTICE 'PASS: все книги имеют валидного автора';
END $$;

-- ТЕСТ 2: Все выдачи ссылаются на существующие книги и читателей
DO $$
DECLARE
    bad_loans INT;
BEGIN
    SELECT COUNT(*) INTO bad_loans
    FROM loans l
    LEFT JOIN books b ON l.book_id = b.id
    LEFT JOIN readers r ON l.reader_id = r.id
    WHERE b.id IS NULL OR r.id IS NULL;
    
    IF bad_loans > 0 THEN
        RAISE EXCEPTION 'FAIL: найдено % выдач с несуществующими связями', bad_loans;
    END IF;
    
    RAISE NOTICE 'PASS: все выдачи ссылаются на существующие книги и читателей';
END $$;

-- ТЕСТ 3: Дата возврата всегда позже даты выдачи
DO $$
DECLARE
    bad_dates INT;
BEGIN
    SELECT COUNT(*) INTO bad_dates
    FROM loans
    WHERE return_date IS NOT NULL AND return_date < loan_date;
    
    IF bad_dates > 0 THEN
        RAISE EXCEPTION 'FAIL: найдено % выдач с датой возврата раньше выдачи', bad_dates;
    END IF;
    
    RAISE NOTICE 'PASS: даты возврата корректны';
END $$;

-- ТЕСТ 4: Email читателей уникальны (когда заполнены)
DO $$
DECLARE
    dup_emails INT;
BEGIN
    SELECT COUNT(*) INTO dup_emails
    FROM (
        SELECT email FROM readers 
        WHERE email IS NOT NULL 
        GROUP BY email 
        HAVING COUNT(*) > 1
    ) dups;
    
    IF dup_emails > 0 THEN
        RAISE EXCEPTION 'FAIL: найдено % дублирующихся email', dup_emails;
    END IF;
    
    RAISE NOTICE 'PASS: email читателей уникальны';
END $$;