# PgVector Fraud Detection with EDB Postgres AI

This repository demonstrates EDB Postgres AI (AIDB) capabilities for handling structured and unstructured data, embedding generation, and cross-database aggregation for fraud detection scenarios.

## Features

- **Multi-database architecture** with customer and transaction databases
- **Vector embeddings** for unstructured text analysis
- **Cross-database queries** using Foreign Data Wrappers
- **AI-powered fraud detection** using similarity search
- **Realistic data generation** with 100+ sample records
- **Performance optimizations** with materialized views and indexes

## Quick Start

### Prerequisites

- EDB Postgres AI with pgvector extension
- PostgreSQL Foreign Data Wrapper extension
- Database superuser privileges for setup

### Running the Demo

1. **Execute the main demonstration script:**
   ```bash
   psql -U postgres -f examples/aidb_multidb_demo.sql
   ```

2. **Follow the step-by-step execution:**
   - Database creation and setup
   - Table creation with vector columns
   - Data population (100+ customers, 200+ transactions, 150+ feedback records)
   - AIDB embedding generation
   - Cross-database analysis queries

## What's Included

### Database Schema

- **customerdb**
  - `customers` table with structured customer data
  - `customer_feedback` table with unstructured feedback and embeddings
  
- **transactiondb**
  - `transactions` table with transaction data and description embeddings

### Key Features Demonstrated

1. **AIDB Embedding Generation**
   ```sql
   aidb_generate_embedding('text-embedding-ada-002', feedback_text)
   ```

2. **Vector Similarity Search**
   ```sql
   SELECT * FROM customer_feedback 
   WHERE feedback_embedding <=> target_embedding < 0.3
   ORDER BY feedback_embedding <=> target_embedding;
   ```

3. **Cross-Database Aggregation**
   ```sql
   SELECT c.*, ft.transaction_amount 
   FROM customers c
   JOIN foreign_transactions ft ON c.customer_id = ft.customer_id;
   ```

4. **Fraud Detection Function**
   ```sql
   SELECT * FROM detect_fraud_similarity('suspicious transaction description');
   ```

## Sample Analysis Queries

The demonstration includes various analysis queries such as:

- Customer risk analysis with transaction patterns
- Sentiment analysis correlation with fraud patterns
- Vector similarity search for fraud detection
- Real-time fraud detection using embeddings
- Cross-database correlation analysis

## Performance Considerations

- Vector operations can be computationally intensive
- Use batch processing for large datasets
- Configure appropriate similarity thresholds
- Regular maintenance of materialized views recommended
- Monitor index usage and query performance

## File Structure

```
examples/
├── aidb_multidb_demo.sql    # Complete demonstration script
```

## Requirements

- **Extensions Required:**
  - pgvector (for vector operations)
  - postgres_fdw (for cross-database queries)  
  - uuid-ossp (for UUID generation)
  - EDB Postgres AI extensions (for aidb_generate_embedding function)

## License

Apache License 2.0 - see LICENSE file for details.

## Support

This demonstration provides a comprehensive foundation for building AI-powered fraud detection systems using EDB Postgres AI capabilities. For questions or issues, please refer to the EDB Postgres AI documentation.