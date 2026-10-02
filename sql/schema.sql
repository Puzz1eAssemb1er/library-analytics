-- Схема базы данных "Библиотека"
-- Проект: Библиотека под контролем

CREATE TABLE authors (
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    birth_year INT
);

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT NOT NULL REFERENCES authors(id),
    published_year INT,
    price NUMERIC(10, 2)
);

CREATE TABLE readers (
    id SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT
);

CREATE TABLE loans (
    id SERIAL PRIMARY KEY,
    book_id INT NOT NULL REFERENCES books(id),
    reader_id INT NOT NULL REFERENCES readers(id),
    loan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    return_date DATE
);

CREATE TABLE notifications_log (
    id SERIAL PRIMARY KEY,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT
);

CREATE INDEX idx_books_author_id ON books(author_id);
CREATE INDEX idx_loans_book_id ON loans(book_id);
CREATE INDEX idx_loans_reader_id ON loans(reader_id);