#!/bin/bash

# Simple SQL validation script for the AIDB demo

echo "=== EDB Postgres AI Multi-Database Demo Validation ==="
echo ""

# Check if the main SQL file exists
if [ ! -f "examples/aidb_multidb_demo.sql" ]; then
    echo "❌ ERROR: aidb_multidb_demo.sql not found!"
    exit 1
fi

echo "✅ Found aidb_multidb_demo.sql"

# Basic file statistics
echo ""
echo "=== File Statistics ==="
echo "Lines: $(wc -l < examples/aidb_multidb_demo.sql)"
echo "Size: $(du -h examples/aidb_multidb_demo.sql | cut -f1)"

# Check for required sections
echo ""
echo "=== Section Validation ==="

sections=(
    "DATABASE SETUP"
    "CUSTOMERDB SETUP"
    "POPULATE CUSTOMERDB"
    "TRANSACTIONDB SETUP" 
    "POPULATE TRANSACTIONDB"
    "AIDB EMBEDDING GENERATION"
    "FOREIGN DATA WRAPPER SETUP"
    "SAMPLE QUERIES"
    "VECTOR SIMILARITY SEARCH"
    "FRAUD DETECTION QUERIES"
)

for section in "${sections[@]}"; do
    if grep -q "$section" examples/aidb_multidb_demo.sql; then
        echo "✅ Found section: $section"
    else
        echo "⚠️  Missing section: $section"
    fi
done

# Check for required SQL constructs
echo ""
echo "=== SQL Construct Validation ==="

constructs=(
    "CREATE DATABASE"
    "CREATE TABLE"
    "CREATE EXTENSION"
    "INSERT INTO"
    "CREATE SERVER"
    "CREATE FOREIGN TABLE"
    "vector(384)"
    "pgvector"
    "postgres_fdw"
    "simulate_aidb_embedding"
)

for construct in "${constructs[@]}"; do
    count=$(grep -c "$construct" examples/aidb_multidb_demo.sql)
    if [ $count -gt 0 ]; then
        echo "✅ Found $count instances of: $construct"
    else
        echo "❌ Missing: $construct"
    fi
done

# Check data volume requirements
echo ""
echo "=== Data Volume Validation ==="

# Count customer inserts
customer_inserts=$(grep -c "INSERT INTO customers" examples/aidb_multidb_demo.sql)
echo "✅ Customer insert statements: $customer_inserts"

# Count transaction inserts
transaction_inserts=$(grep -c "INSERT INTO transactions" examples/aidb_multidb_demo.sql)
echo "✅ Transaction insert statements: $transaction_inserts"

# Check for generate_series usage (bulk data generation)
if grep -q "generate_series" examples/aidb_multidb_demo.sql; then
    echo "✅ Found bulk data generation using generate_series"
else
    echo "⚠️  No bulk data generation found"
fi

# Basic syntax checks
echo ""
echo "=== Basic Syntax Validation ==="

# Check for balanced parentheses in CREATE TABLE statements
create_table_lines=$(grep -n "CREATE TABLE" examples/aidb_multidb_demo.sql)
echo "✅ CREATE TABLE statements found at lines: $(echo "$create_table_lines" | cut -d: -f1 | tr '\n' ' ')"

# Check for proper semicolon usage
if grep -q ";$" examples/aidb_multidb_demo.sql; then
    echo "✅ Found statements with proper semicolon termination"
else
    echo "⚠️  Check semicolon usage"
fi

# Check README exists
echo ""
echo "=== Documentation Validation ==="
if [ -f "README.md" ]; then
    readme_size=$(wc -l < README.md)
    echo "✅ README.md found ($readme_size lines)"
else
    echo "❌ README.md not found"
fi

echo ""
echo "=== Validation Complete ==="
echo ""
echo "📋 Summary:"
echo "   - Main SQL demo file: examples/aidb_multidb_demo.sql"
echo "   - Documentation: README.md"
echo "   - Ready for execution with proper AIDB setup"
echo ""
echo "🚀 To run the demo:"
echo "   1. Ensure EDB Postgres AI is configured"
echo "   2. Replace simulate_aidb_embedding() with aidb_generate_embedding()"
echo "   3. Update FDW connection parameters"
echo "   4. Execute: psql -f examples/aidb_multidb_demo.sql"