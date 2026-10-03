-- Миграция V2: индексы для внешних ключей
-- Ускоряют JOIN-запросы между books, loans, readers

CREATE INDEX idx_books_author_id ON books(author_id);
CREATE INDEX idx_loans_book_id ON loans(book_id);
CREATE INDEX idx_loans_reader_id ON loans(reader_id);