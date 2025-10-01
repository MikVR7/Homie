-- This script will reset the database to a known-good state for testing.

-- Delete existing data (in reverse order of creation to respect foreign keys)
DELETE FROM transactions;
DELETE FROM users;

-- Reset auto-incrementing IDs for SQLite
DELETE FROM sqlite_sequence WHERE name='transactions';
DELETE FROM sqlite_sequence WHERE name='users';

-- Insert fresh test data
INSERT INTO users (id, username, email) VALUES (1, 'testuser', 'test@example.com');
INSERT INTO users (id, username, email) VALUES (2, 'admin', 'admin@example.com');

INSERT INTO transactions (id, user_id, amount, description) VALUES (101, 1, 19.99, 'Monthly Subscription');
INSERT INTO transactions (id, user_id, amount, description) VALUES (102, 1, -5.50, 'Coffee');
INSERT INTO transactions (id, user_id, amount, description) VALUES (103, 2, 100.00, 'Paycheck');

-- You can add any other data you need for testing here.