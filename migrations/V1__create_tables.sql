-- Миграция V1: создание базовых таблиц
-- Таблицы: authors, books, readers, loans

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