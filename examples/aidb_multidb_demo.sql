-- ============================================================================
-- EDB Postgres AI (AIDB) Multi-Database Fraud Detection Demo
-- ============================================================================
-- This demo showcases EDB Postgres AI capabilities for fraud detection across
-- multiple databases using both structured and unstructured data.
-- 
-- Features demonstrated:
-- 1. Multi-database setup (customerdb and transactiondb)
-- 2. Structured data with customer and transaction information
-- 3. Unstructured data (customer feedback, transaction notes)
-- 4. AIDB embedding generation for vector similarity search
-- 5. Foreign Data Wrappers for cross-database operations
-- 6. Advanced queries for fraud detection patterns
--
-- Prerequisites:
-- - EDB Postgres AI (AIDB) installed and configured
-- - pgvector extension available
-- - Foreign Data Wrapper (postgres_fdw) extension
-- ============================================================================

-- ============================================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================================

-- Create the customer database
DROP DATABASE IF EXISTS customerdb;
CREATE DATABASE customerdb;

-- Create the transaction database
DROP DATABASE IF EXISTS transactiondb;
CREATE DATABASE transactiondb;

-- ============================================================================
-- SECTION 2: CUSTOMERDB SETUP
-- ============================================================================

\c customerdb;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create customers table with structured data
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'USA',
    date_of_birth DATE,
    account_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    risk_score DECIMAL(3,2) DEFAULT 0.00,
    is_verified BOOLEAN DEFAULT FALSE,
    account_status VARCHAR(20) DEFAULT 'active'
);

-- Create customer feedback table with unstructured data
CREATE TABLE customer_feedback (
    feedback_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    feedback_text TEXT NOT NULL,
    sentiment_score DECIMAL(3,2),
    feedback_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    channel VARCHAR(20) DEFAULT 'web',
    -- Vector embedding for similarity search
    feedback_embedding vector(384)
);

-- Create customer behavior patterns table
CREATE TABLE customer_behavior (
    behavior_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    login_frequency INTEGER DEFAULT 0,
    avg_transaction_amount DECIMAL(10,2) DEFAULT 0.00,
    preferred_transaction_time TIME,
    device_fingerprint TEXT,
    ip_address INET,
    behavior_notes TEXT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    behavior_embedding vector(384)
);

-- ============================================================================
-- SECTION 3: POPULATE CUSTOMERDB WITH SAMPLE DATA (100+ ROWS)
-- ============================================================================

-- Insert 120 sample customers
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth, risk_score, is_verified) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001', '1985-03-15', 0.15, TRUE),
('Emily', 'Johnson', 'emily.johnson@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210', '1990-07-22', 0.08, TRUE),
('Michael', 'Brown', 'michael.brown@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601', '1982-11-30', 0.45, FALSE),
('Sarah', 'Davis', 'sarah.davis@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001', '1988-05-12', 0.22, TRUE),
('David', 'Wilson', 'david.wilson@email.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001', '1992-09-08', 0.67, FALSE),
('Jessica', 'Miller', 'jessica.miller@email.com', '555-0106', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', '1987-01-25', 0.12, TRUE),
('James', 'Anderson', 'james.anderson@email.com', '555-0107', '147 Birch Ave', 'San Antonio', 'TX', '78201', '1983-12-03', 0.33, TRUE),
('Ashley', 'Taylor', 'ashley.taylor@email.com', '555-0108', '258 Walnut St', 'San Diego', 'CA', '92101', '1991-04-17', 0.19, TRUE),
('Christopher', 'Thomas', 'chris.thomas@email.com', '555-0109', '369 Spruce Rd', 'Dallas', 'TX', '75201', '1986-08-14', 0.41, FALSE),
('Amanda', 'Jackson', 'amanda.jackson@email.com', '555-0110', '741 Poplar Dr', 'San Jose', 'CA', '95101', '1989-06-21', 0.28, TRUE),
('Matthew', 'White', 'matthew.white@email.com', '555-0111', '852 Hickory Ln', 'Austin', 'TX', '73301', '1984-10-09', 0.55, FALSE),
('Jennifer', 'Harris', 'jennifer.harris@email.com', '555-0112', '963 Ash Ave', 'Jacksonville', 'FL', '32099', '1993-02-28', 0.11, TRUE),
('Daniel', 'Martin', 'daniel.martin@email.com', '555-0113', '159 Beech St', 'Fort Worth', 'TX', '76101', '1981-07-16', 0.38, TRUE),
('Michelle', 'Thompson', 'michelle.thompson@email.com', '555-0114', '357 Sycamore Rd', 'Columbus', 'OH', '43085', '1990-11-05', 0.24, TRUE),
('Robert', 'Garcia', 'robert.garcia@email.com', '555-0115', '486 Willow Dr', 'Charlotte', 'NC', '28201', '1987-03-12', 0.47, FALSE),
('Lisa', 'Martinez', 'lisa.martinez@email.com', '555-0116', '579 Cherry Ln', 'San Francisco', 'CA', '94101', '1988-09-23', 0.16, TRUE),
('William', 'Robinson', 'william.robinson@email.com', '555-0117', '684 Magnolia Ave', 'Indianapolis', 'IN', '46201', '1985-12-07', 0.29, TRUE),
('Karen', 'Clark', 'karen.clark@email.com', '555-0118', '791 Dogwood St', 'Seattle', 'WA', '98101', '1992-04-14', 0.13, TRUE),
('Joseph', 'Rodriguez', 'joseph.rodriguez@email.com', '555-0119', '846 Redwood Rd', 'Denver', 'CO', '80201', '1983-08-30', 0.52, FALSE),
('Nancy', 'Lewis', 'nancy.lewis@email.com', '555-0120', '913 Fir Dr', 'Washington', 'DC', '20001', '1989-01-18', 0.21, TRUE);

-- Continue inserting more customers to reach 120 total
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth, risk_score, is_verified) VALUES
('Thomas', 'Lee', 'thomas.lee@email.com', '555-0121', '124 Grove St', 'Boston', 'MA', '02101', '1986-05-25', 0.34, TRUE),
('Maria', 'Walker', 'maria.walker@email.com', '555-0122', '235 Park Ave', 'El Paso', 'TX', '79901', '1991-09-12', 0.18, TRUE),
('Charles', 'Hall', 'charles.hall@email.com', '555-0123', '346 River Rd', 'Detroit', 'MI', '48201', '1984-02-08', 0.43, FALSE),
('Patricia', 'Allen', 'patricia.allen@email.com', '555-0124', '457 Lake Dr', 'Nashville', 'TN', '37201', '1988-06-19', 0.26, TRUE),
('Richard', 'Young', 'richard.young@email.com', '555-0125', '568 Hill Ln', 'Memphis', 'TN', '38101', '1990-10-03', 0.37, TRUE),
('Linda', 'Hernandez', 'linda.hernandez@email.com', '555-0126', '679 Valley Ave', 'Portland', 'OR', '97201', '1987-03-27', 0.14, TRUE),
('Mark', 'King', 'mark.king@email.com', '555-0127', '781 Mountain St', 'Oklahoma City', 'OK', '73101', '1985-07-11', 0.49, FALSE),
('Susan', 'Wright', 'susan.wright@email.com', '555-0128', '892 Forest Rd', 'Las Vegas', 'NV', '89101', '1992-11-24', 0.23, TRUE),
('Steven', 'Lopez', 'steven.lopez@email.com', '555-0129', '934 Meadow Dr', 'Louisville', 'KY', '40201', '1983-04-15', 0.41, TRUE),
('Betty', 'Scott', 'betty.scott@email.com', '555-0130', '145 Garden Ln', 'Baltimore', 'MD', '21201', '1989-08-02', 0.17, TRUE),
('Kenneth', 'Green', 'kenneth.green@email.com', '555-0131', '256 Spring Ave', 'Milwaukee', 'WI', '53201', '1986-12-18', 0.32, TRUE),
('Helen', 'Adams', 'helen.adams@email.com', '555-0132', '367 Summer St', 'Albuquerque', 'NM', '87101', '1988-01-06', 0.25, TRUE),
('Paul', 'Baker', 'paul.baker@email.com', '555-0133', '478 Winter Rd', 'Tucson', 'AZ', '85701', '1991-05-22', 0.39, FALSE),
('Dorothy', 'Gonzalez', 'dorothy.gonzalez@email.com', '555-0134', '589 Autumn Dr', 'Fresno', 'CA', '93701', '1984-09-13', 0.44, FALSE),
('Edward', 'Nelson', 'edward.nelson@email.com', '555-0135', '691 Peace Ln', 'Sacramento', 'CA', '94201', '1987-02-28', 0.20, TRUE),
('Sandra', 'Carter', 'sandra.carter@email.com', '555-0136', '712 Hope Ave', 'Long Beach', 'CA', '90801', '1990-06-07', 0.31, TRUE),
('Brian', 'Mitchell', 'brian.mitchell@email.com', '555-0137', '823 Faith St', 'Kansas City', 'MO', '64101', '1985-10-21', 0.46, FALSE),
('Donna', 'Perez', 'donna.perez@email.com', '555-0138', '934 Joy Rd', 'Mesa', 'AZ', '85201', '1988-03-14', 0.27, TRUE),
('Donald', 'Roberts', 'donald.roberts@email.com', '555-0139', '145 Love Dr', 'Virginia Beach', 'VA', '23451', '1992-07-29', 0.35, TRUE),
('Carol', 'Turner', 'carol.turner@email.com', '555-0140', '256 Grace Ln', 'Atlanta', 'GA', '30301', '1983-11-16', 0.42, FALSE);

-- Insert additional customers to reach 120 total
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, date_of_birth, risk_score, is_verified)
SELECT 
    'Customer' || generate_series(41, 120),
    'Lastname' || generate_series(41, 120),
    'customer' || generate_series(41, 120) || '@email.com',
    '555-' || LPAD(generate_series(141, 220)::text, 4, '0'),
    generate_series(41, 120) || ' Test Street',
    CASE (generate_series(41, 120) % 10)
        WHEN 0 THEN 'Miami'
        WHEN 1 THEN 'Tampa'
        WHEN 2 THEN 'Orlando'
        WHEN 3 THEN 'Cleveland'
        WHEN 4 THEN 'Cincinnati'
        WHEN 5 THEN 'Pittsburgh'
        WHEN 6 THEN 'St. Louis'
        WHEN 7 THEN 'New Orleans'
        WHEN 8 THEN 'Buffalo'
        ELSE 'Raleigh'
    END,
    CASE (generate_series(41, 120) % 10)
        WHEN 0 THEN 'FL'
        WHEN 1 THEN 'FL'
        WHEN 2 THEN 'FL'
        WHEN 3 THEN 'OH'
        WHEN 4 THEN 'OH'
        WHEN 5 THEN 'PA'
        WHEN 6 THEN 'MO'
        WHEN 7 THEN 'LA'
        WHEN 8 THEN 'NY'
        ELSE 'NC'
    END,
    LPAD((33000 + generate_series(41, 120))::text, 5, '0'),
    '1980-01-01'::date + (generate_series(41, 120) * 50 || ' days')::interval,
    ROUND((random() * 0.8)::numeric, 2),
    (generate_series(41, 120) % 3) = 0;

-- Insert customer feedback with unstructured data
INSERT INTO customer_feedback (customer_id, feedback_text, sentiment_score, channel) VALUES
(1, 'Great service! Very satisfied with the transaction process. The interface is user-friendly and secure.', 0.85, 'web'),
(2, 'Had some issues with payment processing. The system seemed slow and unreliable at times.', -0.32, 'mobile'),
(3, 'Excellent customer support. They helped me resolve my account issues quickly and professionally.', 0.78, 'phone'),
(4, 'The fraud detection system blocked my legitimate transaction. Very frustrating experience.', -0.65, 'web'),
(5, 'Love the new features! The security measures give me confidence in using this platform.', 0.72, 'mobile'),
(6, 'Transaction failed multiple times. Customer service was not helpful and seemed inexperienced.', -0.58, 'phone'),
(7, 'Quick and easy transactions. The mobile app works perfectly and is very intuitive.', 0.81, 'mobile'),
(8, 'Concerned about recent security breach reports. Need better communication about security measures.', -0.41, 'web'),
(9, 'Outstanding fraud protection! Caught suspicious activity on my account before I even noticed.', 0.89, 'email'),
(10, 'Website crashes frequently during peak hours. Very poor user experience and reliability.', -0.73, 'web'),
(11, 'Helpful fraud alerts via SMS. Appreciate the proactive approach to account security.', 0.67, 'sms'),
(12, 'Transaction limits are too restrictive. Need more flexibility for business accounts.', -0.28, 'web'),
(13, 'Impressed with the AI-powered recommendations. They actually understand my spending patterns.', 0.74, 'mobile'),
(14, 'Account was frozen without proper notification. Poor customer communication and service.', -0.69, 'phone'),
(15, 'Best fraud detection in the industry! Never had any issues with unauthorized transactions.', 0.92, 'web'),
(16, 'The verification process is too complicated and time-consuming. Needs simplification.', -0.45, 'mobile'),
(17, 'Real-time transaction notifications are very helpful. Great security feature implementation.', 0.79, 'email'),
(18, 'Had a false positive on fraud detection. But appreciate the cautious approach to security.', 0.23, 'web'),
(19, 'Customer service resolved my issue in minutes. Very professional and knowledgeable staff.', 0.86, 'phone'),
(20, 'System downtime during important transaction. Lost money due to delayed processing.', -0.81, 'web');

-- Insert more feedback to have sufficient data for analysis
INSERT INTO customer_feedback (customer_id, feedback_text, sentiment_score, channel)
SELECT 
    (random() * 120 + 1)::integer,
    CASE (random() * 10)::integer
        WHEN 0 THEN 'Transaction was processed smoothly without any issues. Very satisfied with the service quality.'
        WHEN 1 THEN 'Experienced delays in payment processing. The system needs performance improvements.'
        WHEN 2 THEN 'Excellent fraud detection capabilities. Prevented unauthorized access to my account.'
        WHEN 3 THEN 'Customer support was unhelpful and could not resolve my transaction dispute.'
        WHEN 4 THEN 'The mobile application interface is intuitive and easy to navigate.'
        WHEN 5 THEN 'Security features are comprehensive but sometimes overly restrictive for legitimate use.'
        WHEN 6 THEN 'Fast transaction processing and reliable service. Highly recommend to others.'
        WHEN 7 THEN 'Account verification process is cumbersome and takes too long to complete.'
        WHEN 8 THEN 'AI-powered insights help me understand my spending patterns better.'
        ELSE 'Overall good experience but there is room for improvement in customer communication.'
    END,
    (random() * 2 - 1)::numeric(3,2),
    CASE (random() * 4)::integer
        WHEN 0 THEN 'web'
        WHEN 1 THEN 'mobile'
        WHEN 2 THEN 'phone'
        ELSE 'email'
    END
FROM generate_series(1, 100);

-- Insert customer behavior data
INSERT INTO customer_behavior (customer_id, login_frequency, avg_transaction_amount, preferred_transaction_time, device_fingerprint, ip_address, behavior_notes)
SELECT 
    customer_id,
    (random() * 30 + 1)::integer,
    (random() * 5000 + 100)::numeric(10,2),
    (random() * 24)::integer || ':' || (random() * 59)::integer || ':00',
    md5(random()::text),
    ('192.168.' || (random() * 255)::integer || '.' || (random() * 255)::integer)::inet,
    CASE (random() * 5)::integer
        WHEN 0 THEN 'Regular user with consistent patterns'
        WHEN 1 THEN 'Occasional high-value transactions'
        WHEN 2 THEN 'Frequent small transactions'
        WHEN 3 THEN 'Irregular login patterns'
        ELSE 'Normal behavior profile'
    END
FROM customers;

-- ============================================================================
-- SECTION 4: TRANSACTIONDB SETUP
-- ============================================================================

\c transactiondb;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create transactions table
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    transaction_type VARCHAR(20) NOT NULL,
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    location_country VARCHAR(50),
    location_city VARCHAR(50),
    payment_method VARCHAR(20),
    card_last_four VARCHAR(4),
    is_fraudulent BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(3,2) DEFAULT 0.00,
    transaction_notes TEXT,
    -- Vector embedding for transaction pattern analysis
    transaction_embedding vector(384)
);

-- Create merchant information table
CREATE TABLE merchants (
    merchant_id SERIAL PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    merchant_category VARCHAR(50),
    risk_rating DECIMAL(3,2) DEFAULT 0.00,
    location_country VARCHAR(50),
    location_city VARCHAR(50),
    merchant_description TEXT,
    is_verified BOOLEAN DEFAULT TRUE
);

-- Create fraud patterns table with unstructured analysis
CREATE TABLE fraud_patterns (
    pattern_id SERIAL PRIMARY KEY,
    pattern_name VARCHAR(100) NOT NULL,
    pattern_description TEXT,
    detection_rules TEXT,
    risk_weight DECIMAL(3,2),
    pattern_embedding vector(384),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SECTION 5: POPULATE TRANSACTIONDB WITH SAMPLE DATA (100+ ROWS)
-- ============================================================================

-- Insert merchant data
INSERT INTO merchants (merchant_name, merchant_category, risk_rating, location_country, location_city, merchant_description) VALUES
('Amazon', 'E-commerce', 0.15, 'USA', 'Seattle', 'Online retail marketplace'),
('Walmart', 'Retail', 0.12, 'USA', 'Bentonville', 'Physical and online retail'),
('Shell Gas Station', 'Gas Station', 0.25, 'USA', 'Houston', 'Fuel and convenience store'),
('Starbucks', 'Restaurant', 0.08, 'USA', 'Seattle', 'Coffee shop chain'),
('Unknown Merchant XYZ', 'Unknown', 0.85, 'Unknown', 'Unknown', 'Suspicious merchant with limited verification'),
('Apple Store', 'Electronics', 0.10, 'USA', 'Cupertino', 'Technology products retailer'),
('Target', 'Retail', 0.14, 'USA', 'Minneapolis', 'General merchandise retailer'),
('McDonald''s', 'Restaurant', 0.09, 'USA', 'Chicago', 'Fast food restaurant chain'),
('CVS Pharmacy', 'Pharmacy', 0.11, 'USA', 'Woonsocket', 'Pharmacy and health products'),
('Sketchy Online Store', 'E-commerce', 0.92, 'Unknown', 'Unknown', 'High-risk online merchant with poor reputation');

-- Insert 150+ transaction records
INSERT INTO transactions (customer_id, amount, transaction_type, merchant_name, merchant_category, location_country, location_city, payment_method, card_last_four, is_fraudulent, fraud_score, transaction_notes) VALUES
-- Normal transactions
(1, 45.67, 'purchase', 'Amazon', 'E-commerce', 'USA', 'Seattle', 'credit_card', '1234', FALSE, 0.12, 'Regular online purchase for household items'),
(1, 89.23, 'purchase', 'Walmart', 'Retail', 'USA', 'Bentonville', 'debit_card', '1234', FALSE, 0.08, 'Weekly grocery shopping'),
(2, 156.78, 'purchase', 'Apple Store', 'Electronics', 'USA', 'Cupertino', 'credit_card', '5678', FALSE, 0.15, 'Purchase of phone accessories'),
(2, 25.50, 'purchase', 'Starbucks', 'Restaurant', 'USA', 'Seattle', 'mobile_pay', '5678', FALSE, 0.05, 'Daily coffee purchase'),
(3, 78.90, 'purchase', 'Target', 'Retail', 'USA', 'Minneapolis', 'credit_card', '9012', FALSE, 0.10, 'Clothing and personal items'),
-- Fraudulent transactions
(4, 2500.00, 'purchase', 'Unknown Merchant XYZ', 'Unknown', 'Unknown', 'Unknown', 'credit_card', '3456', TRUE, 0.95, 'Suspicious high-value transaction from unverified merchant'),
(5, 1200.00, 'withdrawal', 'ATM Location Unknown', 'ATM', 'Foreign', 'Unknown', 'atm_card', '7890', TRUE, 0.87, 'Large cash withdrawal from foreign location at unusual time'),
(3, 3500.00, 'purchase', 'Sketchy Online Store', 'E-commerce', 'Unknown', 'Unknown', 'credit_card', '9012', TRUE, 0.98, 'High-risk merchant transaction with unusual amount pattern'),
-- More normal transactions
(6, 34.56, 'purchase', 'McDonald''s', 'Restaurant', 'USA', 'Chicago', 'credit_card', '2345', FALSE, 0.06, 'Fast food purchase during lunch time'),
(7, 67.89, 'purchase', 'CVS Pharmacy', 'Pharmacy', 'USA', 'Woonsocket', 'debit_card', '6789', FALSE, 0.09, 'Prescription and health products'),
(8, 123.45, 'purchase', 'Shell Gas Station', 'Gas Station', 'USA', 'Houston', 'credit_card', '0123', FALSE, 0.18, 'Fuel purchase and convenience items'),
(9, 45.00, 'purchase', 'Starbucks', 'Restaurant', 'USA', 'Seattle', 'mobile_pay', '4567', FALSE, 0.04, 'Coffee and breakfast items'),
(10, 234.67, 'purchase', 'Amazon', 'E-commerce', 'USA', 'Seattle', 'credit_card', '8901', FALSE, 0.13, 'Electronics and home improvement items'),
-- Additional fraudulent patterns
(11, 999.99, 'purchase', 'Unknown Merchant XYZ', 'Unknown', 'Unknown', 'Unknown', 'credit_card', '2346', TRUE, 0.91, 'Repeated pattern from high-risk merchant'),
(12, 50.00, 'purchase', 'Starbucks', 'Restaurant', 'USA', 'Seattle', 'credit_card', '5679', FALSE, 0.07, 'Normal coffee shop transaction'),
(12, 4500.00, 'purchase', 'Unknown Merchant XYZ', 'Unknown', 'Unknown', 'Unknown', 'credit_card', '5679', TRUE, 0.96, 'Immediate high-value suspicious transaction after normal purchase'),
(13, 175.50, 'purchase', 'Target', 'Retail', 'USA', 'Minneapolis', 'debit_card', '9013', FALSE, 0.11, 'Regular retail shopping'),
(14, 89.99, 'purchase', 'Apple Store', 'Electronics', 'USA', 'Cupertino', 'credit_card', '3457', FALSE, 0.14, 'Technology accessories purchase'),
(15, 2100.00, 'withdrawal', 'ATM Location Unknown', 'ATM', 'Foreign', 'Unknown', 'atm_card', '7891', TRUE, 0.89, 'Large foreign ATM withdrawal unusual for customer profile'),
(16, 28.75, 'purchase', 'McDonald''s', 'Restaurant', 'USA', 'Chicago', 'mobile_pay', '1235', FALSE, 0.05, 'Quick service restaurant transaction'),
(17, 145.30, 'purchase', 'CVS Pharmacy', 'Pharmacy', 'USA', 'Woonsocket', 'credit_card', '4568', FALSE, 0.10, 'Health and wellness products'),
(18, 65.80, 'purchase', 'Shell Gas Station', 'Gas Station', 'USA', 'Houston', 'debit_card', '8902', FALSE, 0.19, 'Fuel and travel convenience items');

-- Generate additional transactions to reach 150+ total
INSERT INTO transactions (customer_id, amount, transaction_type, merchant_name, merchant_category, location_country, location_city, payment_method, card_last_four, is_fraudulent, fraud_score, transaction_notes)
SELECT 
    (random() * 120 + 1)::integer,
    CASE 
        WHEN random() < 0.1 THEN (random() * 4000 + 1000)::numeric(12,2)  -- 10% high-value transactions
        ELSE (random() * 500 + 10)::numeric(12,2)  -- 90% normal transactions
    END,
    CASE (random() * 4)::integer
        WHEN 0 THEN 'purchase'
        WHEN 1 THEN 'withdrawal'
        WHEN 2 THEN 'transfer'
        ELSE 'payment'
    END,
    CASE (random() * 10)::integer
        WHEN 0 THEN 'Amazon'
        WHEN 1 THEN 'Walmart'
        WHEN 2 THEN 'Starbucks'
        WHEN 3 THEN 'Target'
        WHEN 4 THEN 'Apple Store'
        WHEN 5 THEN 'McDonald''s'
        WHEN 6 THEN 'CVS Pharmacy'
        WHEN 7 THEN 'Shell Gas Station'
        WHEN 8 THEN 'Unknown Merchant XYZ'
        ELSE 'Sketchy Online Store'
    END,
    CASE (random() * 6)::integer
        WHEN 0 THEN 'E-commerce'
        WHEN 1 THEN 'Retail'
        WHEN 2 THEN 'Restaurant'
        WHEN 3 THEN 'Gas Station'
        WHEN 4 THEN 'Electronics'
        ELSE 'Unknown'
    END,
    'USA',
    CASE (random() * 5)::integer
        WHEN 0 THEN 'Seattle'
        WHEN 1 THEN 'Chicago'
        WHEN 2 THEN 'Houston'
        WHEN 3 THEN 'Minneapolis'
        ELSE 'Cupertino'
    END,
    CASE (random() * 4)::integer
        WHEN 0 THEN 'credit_card'
        WHEN 1 THEN 'debit_card'
        WHEN 2 THEN 'mobile_pay'
        ELSE 'atm_card'
    END,
    LPAD((random() * 9999)::integer::text, 4, '0'),
    CASE 
        WHEN random() < 0.05 THEN TRUE  -- 5% fraudulent
        ELSE FALSE
    END,
    CASE 
        WHEN random() < 0.05 THEN (random() * 0.4 + 0.6)::numeric(3,2)  -- High fraud score for fraudulent
        ELSE (random() * 0.3)::numeric(3,2)  -- Low fraud score for normal
    END,
    CASE (random() * 8)::integer
        WHEN 0 THEN 'Regular transaction with normal spending pattern'
        WHEN 1 THEN 'Typical purchase for this customer profile'
        WHEN 2 THEN 'Transaction matches historical behavior'
        WHEN 3 THEN 'Standard payment processing completed'
        WHEN 4 THEN 'Routine transaction without anomalies'
        WHEN 5 THEN 'Expected purchase based on customer habits'
        WHEN 6 THEN 'Normal transaction timing and amount'
        ELSE 'Standard purchase within expected parameters'
    END
FROM generate_series(1, 130);

-- Insert fraud pattern definitions
INSERT INTO fraud_patterns (pattern_name, pattern_description, detection_rules, risk_weight) VALUES
('High-Value Foreign Transaction', 'Large transactions from foreign or unknown locations', 'amount > 1000 AND (location_country != ''USA'' OR location_country = ''Unknown'')', 0.85),
('Rapid Transaction Sequence', 'Multiple transactions in short time window', 'Multiple transactions within 5 minutes with different merchants', 0.75),
('Unknown Merchant Risk', 'Transactions with unverified or high-risk merchants', 'merchant_category = ''Unknown'' OR merchant_name LIKE ''%Unknown%'' OR merchant_name LIKE ''%Sketchy%''', 0.90),
('Unusual Time Pattern', 'Transactions outside normal customer behavior time', 'Transaction time significantly different from customer''s typical pattern', 0.60),
('Geographic Anomaly', 'Transactions from locations inconsistent with customer profile', 'Location differs significantly from customer''s registered address and recent history', 0.70),
('Amount Anomaly', 'Transaction amounts significantly different from customer baseline', 'Amount is 3+ standard deviations from customer''s average transaction amount', 0.65),
('Payment Method Switch', 'Sudden change in preferred payment method', 'Different payment method used compared to recent transaction history', 0.45),
('Velocity Check Failure', 'Too many transactions in short time period', 'More than 5 transactions within 1 hour', 0.80);

-- ============================================================================
-- SECTION 6: AIDB EMBEDDING GENERATION
-- ============================================================================

-- Note: The following functions demonstrate how to use AIDB for embedding generation
-- In a real implementation, replace these with actual aidb_generate_embedding calls

-- Function to simulate AIDB embedding generation (replace with actual AIDB function)
CREATE OR REPLACE FUNCTION simulate_aidb_embedding(input_text TEXT) 
RETURNS vector(384) AS $$
BEGIN
    -- This is a simulation. In real AIDB, use: SELECT aidb_generate_embedding(input_text, 'text-embedding-model')
    -- For demo purposes, we generate a pseudo-random vector based on text hash
    RETURN (
        SELECT ARRAY(
            SELECT (hashtext(input_text || i::text) % 2000 - 1000) / 1000.0
            FROM generate_series(1, 384) i
        )::vector(384)
    );
END;
$$ LANGUAGE plpgsql;

-- Update customer feedback with embeddings
\c customerdb;

UPDATE customer_feedback 
SET feedback_embedding = simulate_aidb_embedding(feedback_text)
WHERE feedback_embedding IS NULL;

-- Update customer behavior with embeddings
UPDATE customer_behavior 
SET behavior_embedding = simulate_aidb_embedding(behavior_notes)
WHERE behavior_embedding IS NULL;

-- Update transaction data with embeddings
\c transactiondb;

UPDATE transactions 
SET transaction_embedding = simulate_aidb_embedding(
    COALESCE(transaction_notes, '') || ' ' || 
    COALESCE(merchant_name, '') || ' ' || 
    COALESCE(merchant_category, '') || ' ' ||
    amount::text
)
WHERE transaction_embedding IS NULL;

-- Update fraud patterns with embeddings
UPDATE fraud_patterns 
SET pattern_embedding = simulate_aidb_embedding(pattern_description || ' ' || detection_rules)
WHERE pattern_embedding IS NULL;

-- ============================================================================
-- SECTION 7: FOREIGN DATA WRAPPER SETUP
-- ============================================================================

-- Set up FDW connections from transactiondb to customerdb
\c transactiondb;

-- Create foreign server for customerdb
CREATE SERVER customerdb_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'customerdb');

-- Create user mapping (in production, use proper credentials)
CREATE USER MAPPING FOR current_user
    SERVER customerdb_server
    OPTIONS (user 'postgres', password 'postgres');

-- Create foreign tables to access customerdb data
CREATE FOREIGN TABLE foreign_customers (
    customer_id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50),
    date_of_birth DATE,
    account_created TIMESTAMP,
    risk_score DECIMAL(3,2),
    is_verified BOOLEAN,
    account_status VARCHAR(20)
)
SERVER customerdb_server
OPTIONS (schema_name 'public', table_name 'customers');

CREATE FOREIGN TABLE foreign_customer_feedback (
    feedback_id INTEGER,
    customer_id INTEGER,
    feedback_text TEXT,
    sentiment_score DECIMAL(3,2),
    feedback_date TIMESTAMP,
    channel VARCHAR(20),
    feedback_embedding vector(384)
)
SERVER customerdb_server
OPTIONS (schema_name 'public', table_name 'customer_feedback');

CREATE FOREIGN TABLE foreign_customer_behavior (
    behavior_id INTEGER,
    customer_id INTEGER,
    login_frequency INTEGER,
    avg_transaction_amount DECIMAL(10,2),
    preferred_transaction_time TIME,
    device_fingerprint TEXT,
    ip_address INET,
    behavior_notes TEXT,
    last_updated TIMESTAMP,
    behavior_embedding vector(384)
)
SERVER customerdb_server
OPTIONS (schema_name 'public', table_name 'customer_behavior');

-- Set up FDW connections from customerdb to transactiondb
\c customerdb;

-- Create foreign server for transactiondb
CREATE SERVER transactiondb_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'transactiondb');

-- Create user mapping
CREATE USER MAPPING FOR current_user
    SERVER transactiondb_server
    OPTIONS (user 'postgres', password 'postgres');

-- Create foreign tables to access transactiondb data
CREATE FOREIGN TABLE foreign_transactions (
    transaction_id INTEGER,
    customer_id INTEGER,
    transaction_date TIMESTAMP,
    amount DECIMAL(12,2),
    currency VARCHAR(3),
    transaction_type VARCHAR(20),
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    location_country VARCHAR(50),
    location_city VARCHAR(50),
    payment_method VARCHAR(20),
    card_last_four VARCHAR(4),
    is_fraudulent BOOLEAN,
    fraud_score DECIMAL(3,2),
    transaction_notes TEXT,
    transaction_embedding vector(384)
)
SERVER transactiondb_server
OPTIONS (schema_name 'public', table_name 'transactions');

-- ============================================================================
-- SECTION 8: SAMPLE QUERIES FOR AGGREGATION AND ANALYSIS
-- ============================================================================

-- Query 1: Cross-database customer transaction summary
\c transactiondb;

SELECT 
    fc.customer_id,
    fc.first_name,
    fc.last_name,
    fc.email,
    fc.risk_score as customer_risk_score,
    fc.is_verified,
    COUNT(t.transaction_id) as total_transactions,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as avg_transaction_amount,
    MAX(t.amount) as max_transaction_amount,
    SUM(CASE WHEN t.is_fraudulent THEN 1 ELSE 0 END) as fraudulent_transactions,
    AVG(t.fraud_score) as avg_fraud_score,
    MAX(t.fraud_score) as max_fraud_score
FROM foreign_customers fc
JOIN transactions t ON fc.customer_id = t.customer_id
GROUP BY fc.customer_id, fc.first_name, fc.last_name, fc.email, fc.risk_score, fc.is_verified
ORDER BY fraudulent_transactions DESC, avg_fraud_score DESC
LIMIT 20;

-- Query 2: High-risk customers with negative sentiment feedback
\c customerdb;

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.risk_score,
    ft.total_transactions,
    ft.total_amount,
    ft.fraudulent_transactions,
    cf.avg_sentiment,
    cf.negative_feedback_count
FROM customers c
JOIN (
    SELECT 
        customer_id,
        COUNT(*) as total_transactions,
        SUM(amount) as total_amount,
        SUM(CASE WHEN is_fraudulent THEN 1 ELSE 0 END) as fraudulent_transactions
    FROM foreign_transactions
    GROUP BY customer_id
) ft ON c.customer_id = ft.customer_id
JOIN (
    SELECT 
        customer_id,
        AVG(sentiment_score) as avg_sentiment,
        SUM(CASE WHEN sentiment_score < -0.3 THEN 1 ELSE 0 END) as negative_feedback_count
    FROM customer_feedback
    GROUP BY customer_id
) cf ON c.customer_id = cf.customer_id
WHERE c.risk_score > 0.5 
   OR ft.fraudulent_transactions > 0 
   OR cf.avg_sentiment < -0.2
ORDER BY c.risk_score DESC, ft.fraudulent_transactions DESC;

-- ============================================================================
-- SECTION 9: VECTOR SIMILARITY SEARCH EXAMPLES
-- ============================================================================

-- Query 3: Find similar customer feedback using vector similarity
\c customerdb;

WITH target_feedback AS (
    SELECT feedback_embedding 
    FROM customer_feedback 
    WHERE feedback_text LIKE '%fraud%' 
    LIMIT 1
)
SELECT 
    cf.customer_id,
    cf.feedback_text,
    cf.sentiment_score,
    cf.channel,
    (cf.feedback_embedding <-> tf.feedback_embedding) as similarity_distance
FROM customer_feedback cf
CROSS JOIN target_feedback tf
WHERE cf.feedback_embedding <-> tf.feedback_embedding < 0.5
ORDER BY similarity_distance
LIMIT 10;

-- Query 4: Find similar transaction patterns using embeddings
\c transactiondb;

WITH suspicious_transaction AS (
    SELECT transaction_embedding 
    FROM transactions 
    WHERE is_fraudulent = TRUE 
    ORDER BY fraud_score DESC 
    LIMIT 1
)
SELECT 
    t.transaction_id,
    t.customer_id,
    t.amount,
    t.merchant_name,
    t.merchant_category,
    t.fraud_score,
    t.is_fraudulent,
    t.transaction_notes,
    (t.transaction_embedding <-> st.transaction_embedding) as similarity_distance
FROM transactions t
CROSS JOIN suspicious_transaction st
WHERE t.transaction_embedding <-> st.transaction_embedding < 0.3
ORDER BY similarity_distance
LIMIT 15;

-- Query 5: Customer behavior similarity analysis
\c customerdb;

WITH high_risk_behavior AS (
    SELECT behavior_embedding 
    FROM customer_behavior cb
    JOIN customers c ON cb.customer_id = c.customer_id
    WHERE c.risk_score > 0.7
    ORDER BY c.risk_score DESC
    LIMIT 1
)
SELECT 
    cb.customer_id,
    c.first_name,
    c.last_name,
    c.risk_score,
    cb.login_frequency,
    cb.avg_transaction_amount,
    cb.behavior_notes,
    (cb.behavior_embedding <-> hrb.behavior_embedding) as similarity_distance
FROM customer_behavior cb
JOIN customers c ON cb.customer_id = c.customer_id
CROSS JOIN high_risk_behavior hrb
WHERE cb.behavior_embedding <-> hrb.behavior_embedding < 0.4
ORDER BY similarity_distance
LIMIT 10;

-- ============================================================================
-- SECTION 10: ADVANCED FRAUD DETECTION QUERIES
-- ============================================================================

-- Query 6: Multi-dimensional fraud risk assessment
\c transactiondb;

WITH fraud_indicators AS (
    SELECT 
        t.customer_id,
        fc.risk_score as customer_risk_score,
        t.transaction_id,
        t.amount,
        t.merchant_name,
        t.merchant_category,
        t.fraud_score,
        t.is_fraudulent,
        -- Risk factors
        CASE WHEN t.amount > 1000 THEN 0.3 ELSE 0.0 END as high_amount_risk,
        CASE WHEN t.merchant_category = 'Unknown' THEN 0.4 ELSE 0.0 END as unknown_merchant_risk,
        CASE WHEN t.location_country != 'USA' THEN 0.2 ELSE 0.0 END as foreign_location_risk,
        CASE WHEN fc.is_verified = FALSE THEN 0.25 ELSE 0.0 END as unverified_customer_risk,
        -- Sentiment analysis from feedback
        COALESCE(fcf.avg_sentiment, 0) as customer_sentiment
    FROM transactions t
    JOIN foreign_customers fc ON t.customer_id = fc.customer_id
    LEFT JOIN (
        SELECT 
            customer_id, 
            AVG(sentiment_score) as avg_sentiment
        FROM foreign_customer_feedback 
        GROUP BY customer_id
    ) fcf ON t.customer_id = fcf.customer_id
)
SELECT 
    customer_id,
    transaction_id,
    amount,
    merchant_name,
    customer_risk_score,
    fraud_score,
    is_fraudulent,
    (customer_risk_score + high_amount_risk + unknown_merchant_risk + 
     foreign_location_risk + unverified_customer_risk - customer_sentiment) as combined_risk_score,
    CASE 
        WHEN (customer_risk_score + high_amount_risk + unknown_merchant_risk + 
              foreign_location_risk + unverified_customer_risk - customer_sentiment) > 1.0 
        THEN 'HIGH RISK'
        WHEN (customer_risk_score + high_amount_risk + unknown_merchant_risk + 
              foreign_location_risk + unverified_customer_risk - customer_sentiment) > 0.5 
        THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END as risk_category
FROM fraud_indicators
ORDER BY combined_risk_score DESC
LIMIT 25;

-- Query 7: Pattern-based fraud detection using vector similarity
\c transactiondb;

WITH pattern_matches AS (
    SELECT 
        t.transaction_id,
        t.customer_id,
        t.amount,
        t.merchant_name,
        t.fraud_score,
        fp.pattern_name,
        fp.risk_weight,
        (t.transaction_embedding <-> fp.pattern_embedding) as pattern_similarity
    FROM transactions t
    CROSS JOIN fraud_patterns fp
    WHERE t.transaction_embedding <-> fp.pattern_embedding < 0.6
)
SELECT 
    pm.transaction_id,
    pm.customer_id,
    fc.first_name,
    fc.last_name,
    pm.amount,
    pm.merchant_name,
    pm.fraud_score,
    STRING_AGG(pm.pattern_name, ', ') as matched_patterns,
    AVG(pm.risk_weight) as avg_pattern_risk,
    MIN(pm.pattern_similarity) as closest_pattern_match
FROM pattern_matches pm
JOIN foreign_customers fc ON pm.customer_id = fc.customer_id
GROUP BY pm.transaction_id, pm.customer_id, fc.first_name, fc.last_name, 
         pm.amount, pm.merchant_name, pm.fraud_score
HAVING AVG(pm.risk_weight) > 0.6
ORDER BY avg_pattern_risk DESC, closest_pattern_match ASC
LIMIT 20;

-- ============================================================================
-- SECTION 11: CUSTOMER INSIGHTS AND RECOMMENDATIONS
-- ============================================================================

-- Query 8: Customer segmentation based on behavior and transaction patterns
\c customerdb;

WITH customer_segments AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.risk_score,
        cb.login_frequency,
        cb.avg_transaction_amount as behavior_avg_amount,
        ft_stats.actual_avg_amount,
        ft_stats.total_transactions,
        ft_stats.fraudulent_count,
        cf_stats.avg_sentiment,
        CASE 
            WHEN ft_stats.fraudulent_count > 0 THEN 'High Risk'
            WHEN c.risk_score > 0.5 THEN 'Medium Risk'
            WHEN cf_stats.avg_sentiment < -0.3 THEN 'Dissatisfied'
            WHEN ft_stats.total_transactions > 10 AND cf_stats.avg_sentiment > 0.5 THEN 'VIP Customer'
            WHEN ft_stats.total_transactions < 3 THEN 'New Customer'
            ELSE 'Regular Customer'
        END as customer_segment
    FROM customers c
    LEFT JOIN customer_behavior cb ON c.customer_id = cb.customer_id
    LEFT JOIN (
        SELECT 
            customer_id,
            AVG(amount) as actual_avg_amount,
            COUNT(*) as total_transactions,
            SUM(CASE WHEN is_fraudulent THEN 1 ELSE 0 END) as fraudulent_count
        FROM foreign_transactions
        GROUP BY customer_id
    ) ft_stats ON c.customer_id = ft_stats.customer_id
    LEFT JOIN (
        SELECT 
            customer_id,
            AVG(sentiment_score) as avg_sentiment
        FROM customer_feedback
        GROUP BY customer_id
    ) cf_stats ON c.customer_id = cf_stats.customer_id
)
SELECT 
    customer_segment,
    COUNT(*) as segment_count,
    AVG(risk_score) as avg_risk_score,
    AVG(total_transactions) as avg_transactions,
    AVG(actual_avg_amount) as avg_transaction_amount,
    AVG(avg_sentiment) as avg_customer_sentiment
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_risk_score DESC;

-- ============================================================================
-- SECTION 12: REAL-TIME FRAUD MONITORING VIEWS
-- ============================================================================

-- Create materialized view for real-time fraud monitoring
\c transactiondb;

CREATE MATERIALIZED VIEW fraud_monitoring_dashboard AS
WITH recent_transactions AS (
    SELECT 
        t.*,
        fc.first_name,
        fc.last_name,
        fc.risk_score as customer_risk_score,
        fc.is_verified
    FROM transactions t
    JOIN foreign_customers fc ON t.customer_id = fc.customer_id
    WHERE t.transaction_date >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
),
fraud_alerts AS (
    SELECT 
        *,
        CASE 
            WHEN is_fraudulent THEN 'CONFIRMED FRAUD'
            WHEN fraud_score > 0.8 THEN 'CRITICAL ALERT'
            WHEN fraud_score > 0.6 THEN 'HIGH ALERT'
            WHEN fraud_score > 0.4 THEN 'MEDIUM ALERT'
            ELSE 'LOW RISK'
        END as alert_level
    FROM recent_transactions
)
SELECT 
    transaction_id,
    customer_id,
    first_name,
    last_name,
    amount,
    merchant_name,
    merchant_category,
    fraud_score,
    customer_risk_score,
    alert_level,
    transaction_date,
    is_verified,
    CASE 
        WHEN alert_level IN ('CONFIRMED FRAUD', 'CRITICAL ALERT') THEN 'IMMEDIATE ACTION REQUIRED'
        WHEN alert_level = 'HIGH ALERT' THEN 'REVIEW RECOMMENDED'
        ELSE 'MONITOR'
    END as recommended_action
FROM fraud_alerts
WHERE alert_level != 'LOW RISK'
ORDER BY 
    CASE alert_level
        WHEN 'CONFIRMED FRAUD' THEN 1
        WHEN 'CRITICAL ALERT' THEN 2
        WHEN 'HIGH ALERT' THEN 3
        WHEN 'MEDIUM ALERT' THEN 4
        ELSE 5
    END,
    fraud_score DESC,
    transaction_date DESC;

-- ============================================================================
-- SECTION 13: PERFORMANCE INDEXES FOR VECTOR OPERATIONS
-- ============================================================================

-- Create indexes for efficient vector similarity searches
\c customerdb;

-- Index for customer feedback embeddings
CREATE INDEX IF NOT EXISTS idx_feedback_embedding_ivfflat 
ON customer_feedback USING ivfflat (feedback_embedding vector_cosine_ops)
WITH (lists = 100);

-- Index for customer behavior embeddings
CREATE INDEX IF NOT EXISTS idx_behavior_embedding_ivfflat 
ON customer_behavior USING ivfflat (behavior_embedding vector_cosine_ops)
WITH (lists = 100);

\c transactiondb;

-- Index for transaction embeddings
CREATE INDEX IF NOT EXISTS idx_transaction_embedding_ivfflat 
ON transactions USING ivfflat (transaction_embedding vector_cosine_ops)
WITH (lists = 100);

-- Index for fraud pattern embeddings
CREATE INDEX IF NOT EXISTS idx_pattern_embedding_ivfflat 
ON fraud_patterns USING ivfflat (pattern_embedding vector_cosine_ops)
WITH (lists = 100);

-- Traditional indexes for common queries
CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_transactions_fraud_score ON transactions(fraud_score DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_amount ON transactions(amount DESC);

-- ============================================================================
-- SECTION 14: SUMMARY AND USAGE INSTRUCTIONS
-- ============================================================================

/*
SUMMARY OF DEMO COMPONENTS:

1. **Database Structure**:
   - customerdb: Customer information, feedback, and behavior data
   - transactiondb: Transaction records, merchant data, and fraud patterns

2. **Data Volume**:
   - 120+ customer records with structured data
   - 120+ customer feedback entries with unstructured text
   - 150+ transaction records with mixed structured/unstructured data
   - Fraud pattern definitions with detection rules

3. **AIDB Integration**:
   - Vector embeddings generated for unstructured text data
   - Similarity search capabilities using pgvector
   - Pattern matching for fraud detection

4. **Cross-Database Operations**:
   - Foreign Data Wrappers connecting both databases
   - Aggregation queries spanning multiple databases
   - Real-time fraud monitoring across data sources

5. **Key Features Demonstrated**:
   - Vector similarity search for fraud pattern detection
   - Customer sentiment analysis integration
   - Multi-dimensional risk scoring
   - Real-time fraud monitoring dashboard
   - Customer segmentation based on behavior patterns

USAGE INSTRUCTIONS:

1. Execute this script in PostgreSQL with AIDB extensions enabled
2. Replace simulate_aidb_embedding() calls with actual aidb_generate_embedding()
3. Adjust FDW connection parameters for your environment
4. Run the sample queries to explore fraud detection capabilities
5. Use the materialized view for real-time monitoring
6. Customize fraud patterns and risk thresholds as needed

SAMPLE QUERIES TO TRY:

-- Find customers with suspicious transaction patterns:
SELECT * FROM fraud_monitoring_dashboard 
WHERE alert_level IN ('CRITICAL ALERT', 'HIGH ALERT')
LIMIT 10;

-- Analyze customer sentiment vs fraud patterns:
\c customerdb;
SELECT 
    c.customer_id,
    AVG(cf.sentiment_score) as avg_sentiment,
    ft.fraudulent_transactions
FROM customers c
JOIN customer_feedback cf ON c.customer_id = cf.customer_id
JOIN (
    SELECT customer_id, 
           SUM(CASE WHEN is_fraudulent THEN 1 ELSE 0 END) as fraudulent_transactions
    FROM foreign_transactions 
    GROUP BY customer_id
) ft ON c.customer_id = ft.customer_id
GROUP BY c.customer_id, ft.fraudulent_transactions
HAVING ft.fraudulent_transactions > 0;

-- Vector similarity search for transaction patterns:
\c transactiondb;
SELECT t1.transaction_id, t1.merchant_name, t1.amount, t1.fraud_score,
       t2.transaction_id as similar_transaction,
       (t1.transaction_embedding <-> t2.transaction_embedding) as similarity
FROM transactions t1
JOIN transactions t2 ON t1.transaction_id != t2.transaction_id
WHERE t1.is_fraudulent = TRUE
  AND t1.transaction_embedding <-> t2.transaction_embedding < 0.3
ORDER BY similarity
LIMIT 20;

This demo provides a comprehensive example of using EDB Postgres AI for 
fraud detection across multiple databases with both structured and 
unstructured data analysis capabilities.
*/