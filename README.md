# EDB Postgres AI (AIDB) Multi-Database Fraud Detection Demo

This repository contains a comprehensive SQL demonstration of EDB Postgres AI capabilities for fraud detection across multiple databases using both structured and unstructured data.

## Overview

The demo showcases advanced fraud detection techniques using:
- **Multi-database architecture** with Foreign Data Wrappers
- **Vector embeddings** for unstructured data analysis
- **Machine learning integration** through AIDB
- **Real-time fraud monitoring** and alerting
- **Cross-database aggregation** and analysis

## Demo Components

### 1. Database Structure
- **customerdb**: Customer information, feedback, and behavior data
- **transactiondb**: Transaction records, merchant data, and fraud patterns

### 2. Data Volume
- **120+ customer records** with structured demographic data
- **120+ customer feedback entries** with unstructured text and sentiment analysis
- **150+ transaction records** with mixed structured and unstructured data
- **Fraud pattern definitions** with detection rules and embeddings

### 3. Key Features Demonstrated

#### AIDB Integration
- Vector embeddings generated for unstructured text data
- Similarity search capabilities using pgvector
- Pattern matching for fraud detection
- Sentiment analysis integration

#### Cross-Database Operations
- Foreign Data Wrappers connecting both databases
- Aggregation queries spanning multiple databases
- Real-time fraud monitoring across data sources

#### Advanced Analytics
- Vector similarity search for fraud pattern detection
- Multi-dimensional risk scoring
- Customer segmentation based on behavior patterns
- Real-time fraud monitoring dashboard

## Prerequisites

Before running this demo, ensure you have:

1. **EDB Postgres AI (AIDB)** installed and configured
2. **pgvector extension** available and installed
3. **Foreign Data Wrapper (postgres_fdw)** extension enabled
4. **PostgreSQL 14+** with appropriate permissions to create databases
5. **Sufficient memory** for vector operations and indexing

## Installation and Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/vibhorkum/pgvector-fraud-detection.git
   cd pgvector-fraud-detection
   ```

2. **Execute the demo script**:
   ```bash
   psql -f examples/aidb_multidb_demo.sql
   ```

3. **Update AIDB configuration**:
   - Replace `simulate_aidb_embedding()` calls with actual `aidb_generate_embedding()`
   - Configure your AIDB model endpoints
   - Adjust FDW connection parameters for your environment

## Usage Examples

### 1. Find High-Risk Transactions
```sql
-- Connect to transactiondb
\c transactiondb;

-- Query the fraud monitoring dashboard
SELECT * FROM fraud_monitoring_dashboard 
WHERE alert_level IN ('CRITICAL ALERT', 'HIGH ALERT')
ORDER BY fraud_score DESC
LIMIT 10;
```

### 2. Analyze Customer Sentiment vs Fraud Patterns
```sql
-- Connect to customerdb
\c customerdb;

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    AVG(cf.sentiment_score) as avg_sentiment,
    ft.fraudulent_transactions,
    c.risk_score
FROM customers c
JOIN customer_feedback cf ON c.customer_id = cf.customer_id
JOIN (
    SELECT customer_id, 
           SUM(CASE WHEN is_fraudulent THEN 1 ELSE 0 END) as fraudulent_transactions
    FROM foreign_transactions 
    GROUP BY customer_id
) ft ON c.customer_id = ft.customer_id
WHERE ft.fraudulent_transactions > 0
GROUP BY c.customer_id, c.first_name, c.last_name, ft.fraudulent_transactions, c.risk_score
ORDER BY ft.fraudulent_transactions DESC, avg_sentiment ASC;
```

### 3. Vector Similarity Search for Transaction Patterns
```sql
-- Connect to transactiondb
\c transactiondb;

-- Find transactions similar to known fraud patterns
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
    t.fraud_score,
    t.is_fraudulent,
    (t.transaction_embedding <-> st.transaction_embedding) as similarity_distance
FROM transactions t
CROSS JOIN suspicious_transaction st
WHERE t.transaction_embedding <-> st.transaction_embedding < 0.3
  AND t.is_fraudulent = FALSE
ORDER BY similarity_distance
LIMIT 15;
```

### 4. Customer Segmentation Analysis
```sql
-- Connect to customerdb
\c customerdb;

WITH customer_segments AS (
    SELECT 
        c.customer_id,
        c.risk_score,
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
    LEFT JOIN (
        SELECT 
            customer_id,
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
    ROUND(AVG(risk_score), 3) as avg_risk_score,
    ROUND(AVG(total_transactions), 1) as avg_transactions,
    ROUND(AVG(avg_sentiment), 3) as avg_customer_sentiment
FROM customer_segments
GROUP BY customer_segment
ORDER BY avg_risk_score DESC;
```

## Performance Considerations

### Indexing Strategy
The demo includes optimized indexes for vector operations:

```sql
-- Vector similarity indexes
CREATE INDEX idx_feedback_embedding_ivfflat 
ON customer_feedback USING ivfflat (feedback_embedding vector_cosine_ops)
WITH (lists = 100);

CREATE INDEX idx_transaction_embedding_ivfflat 
ON transactions USING ivfflat (transaction_embedding vector_cosine_ops)
WITH (lists = 100);

-- Traditional indexes for common queries
CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
CREATE INDEX idx_transactions_fraud_score ON transactions(fraud_score DESC);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
```

### Memory Configuration
For optimal vector operations, consider adjusting PostgreSQL configuration:

```sql
-- Recommended settings for vector operations
SET shared_buffers = '256MB';
SET effective_cache_size = '1GB';
SET work_mem = '64MB';
SET maintenance_work_mem = '128MB';
```

## Customization

### 1. Fraud Detection Rules
Modify the `fraud_patterns` table to add custom detection rules:

```sql
INSERT INTO fraud_patterns (pattern_name, pattern_description, detection_rules, risk_weight) VALUES
('Custom Pattern', 'Your custom fraud pattern', 'your_custom_rule', 0.75);
```

### 2. Risk Scoring
Adjust risk score calculations in the fraud monitoring queries based on your business requirements.

### 3. AIDB Model Integration
Replace the simulation function with actual AIDB calls:

```sql
-- Replace this simulation
SELECT simulate_aidb_embedding(input_text)

-- With actual AIDB function
SELECT aidb_generate_embedding(input_text, 'your-embedding-model')
```

## Data Model

### customerdb Tables
- `customers`: Customer demographic and account information
- `customer_feedback`: Unstructured customer feedback with sentiment analysis
- `customer_behavior`: Customer behavior patterns and device information

### transactiondb Tables
- `transactions`: Transaction records with structured and unstructured data
- `merchants`: Merchant information and risk ratings
- `fraud_patterns`: Fraud detection pattern definitions

### Foreign Tables
- Cross-database access through Foreign Data Wrappers
- Real-time data aggregation and analysis

## Monitoring and Alerting

The demo includes a materialized view for real-time fraud monitoring:

```sql
-- Refresh the monitoring dashboard
REFRESH MATERIALIZED VIEW fraud_monitoring_dashboard;

-- Query recent high-risk transactions
SELECT 
    customer_id,
    first_name,
    last_name,
    amount,
    merchant_name,
    alert_level,
    recommended_action
FROM fraud_monitoring_dashboard
WHERE alert_level IN ('CONFIRMED FRAUD', 'CRITICAL ALERT', 'HIGH ALERT')
ORDER BY 
    CASE alert_level
        WHEN 'CONFIRMED FRAUD' THEN 1
        WHEN 'CRITICAL ALERT' THEN 2
        WHEN 'HIGH ALERT' THEN 3
    END,
    fraud_score DESC;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
1. Check the existing issues in the GitHub repository
2. Create a new issue with detailed information
3. Include your PostgreSQL and AIDB version information
4. Provide sample data and queries when applicable

## Related Resources

- [EDB Postgres AI Documentation](https://www.enterprisedb.com/docs/)
- [pgvector Extension](https://github.com/pgvector/pgvector)
- [PostgreSQL Foreign Data Wrappers](https://www.postgresql.org/docs/current/fdwhandler.html)
- [Vector Similarity Search Best Practices](https://www.postgresql.org/docs/current/vectors.html)