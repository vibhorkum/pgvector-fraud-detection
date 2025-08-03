-- =====================================================================================
-- EDB Postgres AI (AIDB) Multi-Database Demonstration
-- =====================================================================================
-- This demonstration showcases AIDB capabilities for handling structured and 
-- unstructured data, embedding generation, and cross-database aggregation.
--
-- Features demonstrated:
-- 1. Two separate databases with structured and unstructured data
-- 2. Vector embeddings for unstructured text data
-- 3. Cross-database queries and joins
-- 4. Vector similarity search for fraud detection
-- 5. Realistic data generation with 100+ records
-- =====================================================================================

-- =====================================================================================
-- STEP 1: DATABASE AND EXTENSION SETUP
-- =====================================================================================

-- Create the customer database
-- Note: Run this as a superuser or database owner
CREATE DATABASE customerdb 
    WITH ENCODING 'UTF8' 
    LC_COLLATE 'en_US.UTF-8' 
    LC_CTYPE 'en_US.UTF-8';

-- Create the transaction database
CREATE DATABASE transactiondb 
    WITH ENCODING 'UTF8' 
    LC_COLLATE 'en_US.UTF-8' 
    LC_CTYPE 'en_US.UTF-8';

-- =====================================================================================
-- CUSTOMER DATABASE SETUP
-- =====================================================================================

-- Connect to customerdb
\c customerdb

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create customers table with structured data
CREATE TABLE customers (
    customer_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    account_created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'United States',
    risk_score DECIMAL(3,2) DEFAULT 0.00,
    account_status VARCHAR(20) DEFAULT 'active'
);

-- Create feedback table with unstructured text data and embeddings
CREATE TABLE customer_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES customers(customer_id),
    feedback_text TEXT NOT NULL,
    feedback_type VARCHAR(20) DEFAULT 'general', -- complaint, compliment, suggestion, general
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sentiment_score DECIMAL(3,2), -- -1.0 to 1.0
    feedback_embedding vector(1536), -- OpenAI embedding dimension
    processed BOOLEAN DEFAULT FALSE
);

-- Create index for vector similarity search
CREATE INDEX ON customer_feedback USING ivfflat (feedback_embedding vector_cosine_ops);

-- =====================================================================================
-- TRANSACTION DATABASE SETUP
-- =====================================================================================

-- Connect to transactiondb
\c transactiondb

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create transactions table with structured data and unstructured description
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL, -- Reference to customer in customerdb
    transaction_amount DECIMAL(12,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL, -- purchase, refund, transfer, withdrawal
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    transaction_description TEXT, -- Unstructured field
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    card_number_masked VARCHAR(20), -- Last 4 digits only
    location_city VARCHAR(50),
    location_state VARCHAR(50),
    location_country VARCHAR(50) DEFAULT 'United States',
    is_online BOOLEAN DEFAULT FALSE,
    fraud_flag BOOLEAN DEFAULT FALSE,
    fraud_score DECIMAL(3,2) DEFAULT 0.00,
    description_embedding vector(1536), -- Embedding for transaction description
    processed BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_amount ON transactions(transaction_amount);
CREATE INDEX ON transactions USING ivfflat (description_embedding vector_cosine_ops);

-- =====================================================================================
-- STEP 2: DATA POPULATION - CUSTOMER DATABASE
-- =====================================================================================

\c customerdb

-- Insert sample customers (100+ records)
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, address_line1, city, state, postal_code, risk_score, account_status) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '1985-03-15', '123 Main St', 'New York', 'NY', '10001', 0.15, 'active'),
('Sarah', 'Johnson', 'sarah.johnson@email.com', '555-0102', '1990-07-22', '456 Oak Ave', 'Los Angeles', 'CA', '90210', 0.25, 'active'),
('Michael', 'Brown', 'michael.brown@email.com', '555-0103', '1978-11-08', '789 Pine Rd', 'Chicago', 'IL', '60601', 0.75, 'flagged'),
('Emily', 'Davis', 'emily.davis@email.com', '555-0104', '1992-04-30', '321 Elm St', 'Houston', 'TX', '77001', 0.10, 'active'),
('David', 'Wilson', 'david.wilson@email.com', '555-0105', '1987-09-14', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 0.35, 'active'),
('Jessica', 'Miller', 'jessica.miller@email.com', '555-0106', '1995-02-18', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 0.20, 'active'),
('Robert', 'Moore', 'robert.moore@email.com', '555-0107', '1983-12-05', '147 Birch Way', 'San Antonio', 'TX', '78201', 0.45, 'active'),
('Ashley', 'Taylor', 'ashley.taylor@email.com', '555-0108', '1989-06-27', '258 Spruce St', 'San Diego', 'CA', '92101', 0.30, 'active'),
('Christopher', 'Anderson', 'chris.anderson@email.com', '555-0109', '1976-08-12', '369 Fir Ave', 'Dallas', 'TX', '75201', 0.55, 'review'),
('Amanda', 'Thomas', 'amanda.thomas@email.com', '555-0110', '1993-01-09', '741 Ash Rd', 'San Jose', 'CA', '95101', 0.15, 'active');

-- Continue with more customer records to reach 100+
INSERT INTO customers (first_name, last_name, email, phone, date_of_birth, address_line1, city, state, postal_code, risk_score, account_status) 
SELECT 
    (ARRAY['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan', 'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Christopher', 'Karen'])[floor(random() * 20 + 1)],
    (ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin'])[floor(random() * 20 + 1)],
    'user' || generate_series || '@example.com',
    '555-' || lpad((generate_series + 200)::text, 4, '0'),
    DATE '1970-01-01' + (random() * (DATE '2000-01-01' - DATE '1970-01-01'))::int,
    (generate_series * 123 % 9999) || ' ' || (ARRAY['Main St', 'Oak Ave', 'Pine Rd', 'Elm St', 'Maple Dr', 'Cedar Ln', 'Birch Way', 'Spruce St', 'Fir Ave', 'Ash Rd'])[floor(random() * 10 + 1)],
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose', 'Austin', 'Jacksonville', 'Fort Worth', 'Columbus', 'Charlotte'])[floor(random() * 15 + 1)],
    (ARRAY['NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'FL', 'OH', 'NC'])[floor(random() * 9 + 1)],
    lpad((floor(random() * 99999))::text, 5, '0'),
    round((random() * 0.8)::numeric, 2),
    (ARRAY['active', 'active', 'active', 'active', 'review', 'flagged'])[floor(random() * 6 + 1)]
FROM generate_series(11, 120);

-- Insert customer feedback with unstructured text
INSERT INTO customer_feedback (customer_id, feedback_text, feedback_type, sentiment_score) 
SELECT 
    customer_id,
    CASE floor(random() * 5)
        WHEN 0 THEN 'Great service! The transaction was processed quickly and the customer support was very helpful. I would definitely recommend this service to others.'
        WHEN 1 THEN 'I had issues with my recent transaction. The payment failed multiple times and I had to contact support. Not satisfied with the experience.'
        WHEN 2 THEN 'Average experience. The service works as expected but nothing exceptional. Could improve the user interface for better usability.'
        WHEN 3 THEN 'Excellent fraud protection! Your system caught a suspicious transaction that I did not make. Thank you for keeping my account safe.'
        ELSE 'The mobile app crashes frequently and transactions take too long to process. Please fix these technical issues soon.'
    END,
    (ARRAY['compliment', 'complaint', 'general', 'compliment', 'complaint'])[floor(random() * 5 + 1)],
    round((random() * 2 - 1)::numeric, 2) -- Random sentiment between -1 and 1
FROM customers 
ORDER BY random() 
LIMIT 150; -- More feedback than customers

-- =====================================================================================
-- STEP 3: DATA POPULATION - TRANSACTION DATABASE
-- =====================================================================================

\c transactiondb

-- Insert sample transactions (100+ records)
INSERT INTO transactions (customer_id, transaction_amount, transaction_type, merchant_name, merchant_category, transaction_description, card_number_masked, location_city, location_state, is_online, fraud_flag, fraud_score)
SELECT 
    -- Use customer_ids from customerdb (we'll use UUIDs from our known customers)
    (SELECT customer_id FROM customerdb.customers ORDER BY random() LIMIT 1),
    round((random() * 2000 + 10)::numeric, 2), -- Random amount between $10-$2010
    (ARRAY['purchase', 'purchase', 'purchase', 'refund', 'transfer', 'withdrawal'])[floor(random() * 6 + 1)],
    (ARRAY['Amazon', 'Walmart', 'Target', 'Best Buy', 'Home Depot', 'Costco', 'Starbucks', 'McDonalds', 'Shell Gas', 'Uber', 'Netflix', 'Spotify', 'Apple Store', 'Google Play', 'PayPal Transfer'])[floor(random() * 15 + 1)],
    (ARRAY['retail', 'grocery', 'electronics', 'gas_station', 'restaurant', 'entertainment', 'transportation', 'subscription', 'online_services'])[floor(random() * 9 + 1)],
    CASE floor(random() * 6)
        WHEN 0 THEN 'Online purchase for electronics - laptop computer with extended warranty and accessories'
        WHEN 1 THEN 'Grocery shopping - weekly family groceries including fresh produce and household items'
        WHEN 2 THEN 'Gas station fuel purchase - regular unleaded gasoline and convenience store snacks'
        WHEN 3 THEN 'Restaurant dining - dinner for two at upscale Italian restaurant with wine'
        WHEN 4 THEN 'Suspicious activity detected - multiple small transactions from unknown location'
        ELSE 'ATM withdrawal - cash withdrawal from out-of-state ATM with high fees'
    END,
    '**** **** **** ' || lpad((floor(random() * 9999))::text, 4, '0'),
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'])[floor(random() * 10 + 1)],
    (ARRAY['NY', 'CA', 'IL', 'TX', 'AZ', 'PA', 'FL'])[floor(random() * 7 + 1)],
    random() > 0.4, -- 60% online transactions
    random() > 0.95, -- 5% fraud
    round((random() * 0.3)::numeric, 2) -- Low fraud scores for most
FROM generate_series(1, 200);

-- Add some high-risk transactions
INSERT INTO transactions (customer_id, transaction_amount, transaction_type, merchant_name, merchant_category, transaction_description, card_number_masked, location_city, location_state, is_online, fraud_flag, fraud_score)
VALUES 
((SELECT customer_id FROM customerdb.customers WHERE risk_score > 0.5 LIMIT 1), 5000.00, 'purchase', 'Unknown Merchant', 'unknown', 'Large purchase from unverified merchant - potential money laundering scheme', '**** **** **** 9999', 'Unknown', 'XX', true, true, 0.95),
((SELECT customer_id FROM customerdb.customers WHERE risk_score > 0.5 LIMIT 1 OFFSET 1), 3500.00, 'transfer', 'Overseas Transfer', 'financial', 'International wire transfer to high-risk country - flagged by compliance', '**** **** **** 8888', 'Miami', 'FL', true, true, 0.87);

-- =====================================================================================
-- STEP 4: EMBEDDING GENERATION USING AIDB
-- =====================================================================================

-- Note: These are example calls to AIDB embedding functions
-- Actual function names and parameters may vary based on EDB AIDB implementation

-- Generate embeddings for customer feedback
\c customerdb

-- Update feedback with embeddings using AIDB
UPDATE customer_feedback 
SET feedback_embedding = aidb_generate_embedding('text-embedding-ada-002', feedback_text),
    processed = TRUE
WHERE feedback_embedding IS NULL;

-- Alternative approach using batch processing for better performance
-- SELECT aidb_batch_generate_embeddings(
--     'text-embedding-ada-002',
--     ARRAY(SELECT feedback_text FROM customer_feedback WHERE feedback_embedding IS NULL)
-- );

-- Generate embeddings for transaction descriptions
\c transactiondb

UPDATE transactions 
SET description_embedding = aidb_generate_embedding('text-embedding-ada-002', transaction_description),
    processed = TRUE
WHERE description_embedding IS NULL;

-- =====================================================================================
-- STEP 5: CROSS-DATABASE AGGREGATION AND ANALYSIS
-- =====================================================================================

-- Example 1: Join customers with their transactions across databases
-- Note: This requires foreign data wrapper (FDW) or application-level joins

-- Create foreign data wrapper to connect transactiondb from customerdb
\c customerdb

-- Install postgres_fdw extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create foreign server
CREATE SERVER transactiondb_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'transactiondb');

-- Create user mapping (adjust credentials as needed)
CREATE USER MAPPING FOR CURRENT_USER
    SERVER transactiondb_server
    OPTIONS (user 'postgres', password 'password');

-- Create foreign table for transactions
CREATE FOREIGN TABLE foreign_transactions (
    transaction_id UUID,
    customer_id UUID,
    transaction_amount DECIMAL(12,2),
    transaction_type VARCHAR(20),
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    transaction_description TEXT,
    transaction_date TIMESTAMP,
    card_number_masked VARCHAR(20),
    location_city VARCHAR(50),
    location_state VARCHAR(50),
    is_online BOOLEAN,
    fraud_flag BOOLEAN,
    fraud_score DECIMAL(3,2),
    description_embedding vector(1536)
) SERVER transactiondb_server
OPTIONS (schema_name 'public', table_name 'transactions');

-- =====================================================================================
-- STEP 6: ADVANCED QUERIES AND VECTOR SIMILARITY SEARCH
-- =====================================================================================

-- Query 1: Customer risk analysis with transaction patterns
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.risk_score,
    COUNT(ft.transaction_id) as total_transactions,
    SUM(ft.transaction_amount) as total_amount,
    AVG(ft.fraud_score) as avg_fraud_score,
    COUNT(CASE WHEN ft.fraud_flag = true THEN 1 END) as fraud_count
FROM customers c
LEFT JOIN foreign_transactions ft ON c.customer_id = ft.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.risk_score
ORDER BY c.risk_score DESC, avg_fraud_score DESC
LIMIT 20;

-- Query 2: Find similar customer feedback using vector similarity
-- Example: Find feedback similar to complaints about transaction failures
WITH target_feedback AS (
    SELECT feedback_embedding 
    FROM customer_feedback 
    WHERE feedback_text ILIKE '%transaction%failed%' 
    LIMIT 1
)
SELECT 
    cf.feedback_id,
    cf.feedback_text,
    cf.feedback_type,
    cf.sentiment_score,
    cf.feedback_embedding <=> tf.feedback_embedding AS similarity_distance
FROM customer_feedback cf, target_feedback tf
WHERE cf.feedback_embedding <=> tf.feedback_embedding < 0.3 -- Similarity threshold
ORDER BY similarity_distance
LIMIT 10;

-- Query 3: Fraud detection using transaction description similarity
\c transactiondb

-- Find transactions similar to known fraud patterns
WITH fraud_pattern AS (
    SELECT description_embedding 
    FROM transactions 
    WHERE fraud_flag = true 
    AND transaction_description ILIKE '%suspicious%'
    LIMIT 1
)
SELECT 
    t.transaction_id,
    t.customer_id,
    t.transaction_amount,
    t.merchant_name,
    t.transaction_description,
    t.fraud_score,
    t.description_embedding <=> fp.description_embedding AS similarity_distance
FROM transactions t, fraud_pattern fp
WHERE t.fraud_flag = false -- Look for unflagged transactions
AND t.description_embedding <=> fp.description_embedding < 0.2
ORDER BY similarity_distance
LIMIT 15;

-- Query 4: Multi-dimensional fraud analysis
\c customerdb

-- Combine customer risk, feedback sentiment, and transaction patterns
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS full_name,
    c.risk_score,
    AVG(cf.sentiment_score) as avg_sentiment,
    COUNT(cf.feedback_id) as feedback_count,
    SUM(ft.transaction_amount) as total_spent,
    AVG(ft.fraud_score) as avg_transaction_fraud_score,
    COUNT(CASE WHEN ft.fraud_flag = true THEN 1 END) as confirmed_fraud_count,
    -- Composite risk score
    (c.risk_score * 0.4 + 
     COALESCE(AVG(ft.fraud_score), 0) * 0.4 + 
     CASE WHEN AVG(cf.sentiment_score) < -0.5 THEN 0.2 ELSE 0 END) as composite_risk_score
FROM customers c
LEFT JOIN customer_feedback cf ON c.customer_id = cf.customer_id
LEFT JOIN foreign_transactions ft ON c.customer_id = ft.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.risk_score
HAVING COUNT(ft.transaction_id) > 0 -- Only customers with transactions
ORDER BY composite_risk_score DESC
LIMIT 25;

-- =====================================================================================
-- STEP 7: REAL-TIME FRAUD DETECTION FUNCTIONS
-- =====================================================================================

-- Create a function to detect potential fraud using embeddings
\c transactiondb

CREATE OR REPLACE FUNCTION detect_fraud_similarity(
    input_description TEXT,
    similarity_threshold FLOAT DEFAULT 0.25
) RETURNS TABLE (
    similar_transaction_id UUID,
    similarity_score FLOAT,
    original_fraud_score DECIMAL,
    recommended_action TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH input_embedding AS (
        SELECT aidb_generate_embedding('text-embedding-ada-002', input_description) as embedding
    )
    SELECT 
        t.transaction_id,
        (t.description_embedding <=> ie.embedding)::FLOAT as similarity,
        t.fraud_score,
        CASE 
            WHEN (t.description_embedding <=> ie.embedding) < 0.1 AND t.fraud_flag = true THEN 'BLOCK - High similarity to known fraud'
            WHEN (t.description_embedding <=> ie.embedding) < 0.2 THEN 'REVIEW - Moderate similarity to suspicious activity'
            ELSE 'APPROVE - Low risk transaction'
        END as action
    FROM transactions t, input_embedding ie
    WHERE t.description_embedding <=> ie.embedding < similarity_threshold
    AND t.fraud_flag = true
    ORDER BY similarity
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Example usage of fraud detection function
SELECT * FROM detect_fraud_similarity(
    'Large cash withdrawal from ATM in foreign country using stolen card'
);

-- =====================================================================================
-- STEP 8: PERFORMANCE OPTIMIZATION AND MONITORING
-- =====================================================================================

-- Create materialized view for frequently accessed customer risk data
\c customerdb

CREATE MATERIALIZED VIEW customer_risk_summary AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.risk_score,
    c.account_status,
    COUNT(cf.feedback_id) as feedback_count,
    AVG(cf.sentiment_score) as avg_sentiment,
    COUNT(CASE WHEN cf.feedback_type = 'complaint' THEN 1 END) as complaint_count,
    COUNT(ft.transaction_id) as transaction_count,
    SUM(ft.transaction_amount) as total_transaction_amount,
    COUNT(CASE WHEN ft.fraud_flag = true THEN 1 END) as fraud_transaction_count,
    MAX(ft.transaction_date) as last_transaction_date
FROM customers c
LEFT JOIN customer_feedback cf ON c.customer_id = cf.customer_id
LEFT JOIN foreign_transactions ft ON c.customer_id = ft.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.risk_score, c.account_status;

-- Create index on materialized view
CREATE INDEX idx_customer_risk_summary_risk_score ON customer_risk_summary(risk_score DESC);

-- Refresh materialized view (should be scheduled)
REFRESH MATERIALIZED VIEW customer_risk_summary;

-- =====================================================================================
-- STEP 9: SAMPLE ANALYSIS QUERIES
-- =====================================================================================

-- Analysis 1: Top risky customers with recent activity
SELECT 
    customer_id,
    first_name || ' ' || last_name as full_name,
    email,
    risk_score,
    transaction_count,
    total_transaction_amount,
    fraud_transaction_count,
    complaint_count,
    avg_sentiment
FROM customer_risk_summary
WHERE last_transaction_date >= CURRENT_DATE - INTERVAL '30 days'
AND (risk_score > 0.5 OR fraud_transaction_count > 0 OR complaint_count > 2)
ORDER BY risk_score DESC, fraud_transaction_count DESC;

-- Analysis 2: Sentiment analysis correlation with fraud
SELECT 
    CASE 
        WHEN avg_sentiment >= 0.5 THEN 'Positive'
        WHEN avg_sentiment >= 0 THEN 'Neutral'
        WHEN avg_sentiment >= -0.5 THEN 'Negative'
        ELSE 'Very Negative'
    END as sentiment_category,
    COUNT(*) as customer_count,
    AVG(risk_score) as avg_risk_score,
    SUM(fraud_transaction_count) as total_fraud_transactions,
    AVG(total_transaction_amount) as avg_transaction_volume
FROM customer_risk_summary
WHERE feedback_count > 0
GROUP BY sentiment_category
ORDER BY avg_risk_score DESC;

-- =====================================================================================
-- STEP 10: CLEANUP AND MAINTENANCE FUNCTIONS
-- =====================================================================================

-- Function to update embeddings for new feedback
\c customerdb

CREATE OR REPLACE FUNCTION update_feedback_embeddings() RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE customer_feedback 
    SET feedback_embedding = aidb_generate_embedding('text-embedding-ada-002', feedback_text),
        processed = TRUE
    WHERE feedback_embedding IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update transaction embeddings
\c transactiondb

CREATE OR REPLACE FUNCTION update_transaction_embeddings() RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE transactions 
    SET description_embedding = aidb_generate_embedding('text-embedding-ada-002', transaction_description),
        processed = TRUE
    WHERE description_embedding IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================================
-- USAGE SUMMARY AND NEXT STEPS
-- =====================================================================================

/*
This demonstration showcases the following EDB Postgres AI capabilities:

1. MULTI-DATABASE ARCHITECTURE:
   - customerdb: Customer profiles and feedback
   - transactiondb: Transaction records with descriptions
   - Foreign Data Wrapper for cross-database queries

2. VECTOR EMBEDDINGS:
   - Generated embeddings for unstructured text (feedback, transaction descriptions)
   - Used aidb_generate_embedding() function for AI-powered embedding generation
   - Configured vector similarity search with pgvector extension

3. FRAUD DETECTION FEATURES:
   - Vector similarity search to find similar fraud patterns
   - Composite risk scoring combining multiple data sources
   - Real-time fraud detection function using embeddings
   - Cross-database correlation analysis

4. PERFORMANCE OPTIMIZATIONS:
   - IVFFlat indexes for vector similarity search
   - Materialized views for frequently accessed aggregations
   - Batch processing for embedding generation

5. SAMPLE QUERIES INCLUDED:
   - Customer risk analysis with transaction patterns
   - Vector similarity search for fraud detection
   - Sentiment analysis correlation with fraud patterns
   - Cross-database aggregation and reporting

TO USE THIS DEMONSTRATION:
1. Execute the database creation scripts as a superuser
2. Run the table creation and indexing commands
3. Execute the data population scripts
4. Configure Foreign Data Wrapper connections
5. Run the embedding generation functions
6. Execute sample analysis queries
7. Use the fraud detection functions for real-time monitoring

REQUIRED EXTENSIONS:
- pgvector (for vector operations)
- postgres_fdw (for cross-database queries)
- uuid-ossp (for UUID generation)
- EDB Postgres AI extensions (for aidb_generate_embedding function)

PERFORMANCE CONSIDERATIONS:
- Vector operations can be computationally intensive
- Consider batch processing for large datasets
- Use appropriate similarity thresholds for your use case
- Regular maintenance of materialized views is recommended
- Monitor index usage and query performance

This demonstration provides a comprehensive foundation for building
AI-powered fraud detection systems using EDB Postgres AI capabilities.
*/
