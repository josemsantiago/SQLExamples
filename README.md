# SQL Mastery Examples
### Comprehensive SQL and Transact-SQL Reference & Portfolio

[![SQL](https://img.shields.io/badge/SQL-Advanced-blue.svg)](https://www.w3schools.com/sql/)
[![T-SQL](https://img.shields.io/badge/T--SQL-Expert-red.svg)](https://docs.microsoft.com/en-us/sql/t-sql/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Professional-lightblue.svg)](https://postgresql.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive collection of SQL examples demonstrating mastery from basic queries to advanced database programming, including extensive Transact-SQL features, performance optimization, and enterprise-level database solutions.

## 📚 **Table of Contents**

- [Overview](#overview)
- [Database Schema](#database-schema)
- [SQL Fundamentals](#sql-fundamentals)
- [Advanced Queries](#advanced-queries)
- [Transact-SQL Features](#transact-sql-features)
- [Performance Optimization](#performance-optimization)
- [Data Analysis Examples](#data-analysis-examples)
- [Enterprise Patterns](#enterprise-patterns)
- [Setup Instructions](#setup-instructions)

## 🎯 **Overview**

This repository demonstrates comprehensive SQL expertise through practical examples covering:

### **Skill Coverage Matrix**
| Category | Basic | Intermediate | Advanced | Expert |
|----------|-------|--------------|----------|--------|
| **Queries** | ✅ SELECT, WHERE, ORDER BY | ✅ JOINs, Subqueries | ✅ CTEs, Window Functions | ✅ Recursive Queries |
| **Data Manipulation** | ✅ INSERT, UPDATE, DELETE | ✅ MERGE, UPSERT | ✅ Bulk Operations | ✅ Transaction Control |
| **Database Design** | ✅ Tables, Constraints | ✅ Indexes, Views | ✅ Triggers, Procedures | ✅ Partitioning |
| **T-SQL Programming** | ✅ Variables, Conditions | ✅ Loops, Error Handling | ✅ Dynamic SQL | ✅ CLR Integration |
| **Performance** | ✅ Basic Indexing | ✅ Execution Plans | ✅ Query Optimization | ✅ Advanced Tuning |

## 📊 **Database Schema**

The examples use multiple database schemas including:

### **Northwind Database** (Classic Business Schema)
- **Products & Categories**: Product catalog management
- **Customers & Orders**: Order processing system
- **Employees & Territories**: Human resources data
- **Suppliers & Shipping**: Supply chain management

### **Museum of Modern Art (MoMA) Dataset**
- **Artworks**: Comprehensive art collection data
- **Artists**: Artist biographical information
- **Exhibitions**: Exhibition and curation data

### **Custom Enterprise Schemas**
- **Financial System**: Banking and transaction processing
- **E-commerce Platform**: Online retail operations
- **Social Media Analytics**: User engagement metrics

## 🔧 **File Structure**

```
SQLExamples/
├── 01_fundamentals/
│   ├── basic_queries.sql           # SELECT, WHERE, ORDER BY
│   ├── data_types.sql              # All SQL data types
│   ├── operators.sql               # Arithmetic, logical, comparison
│   └── string_functions.sql        # Text manipulation functions
├── 02_intermediate/
│   ├── joins_comprehensive.sql     # All JOIN types with examples
│   ├── subqueries_correlated.sql   # Nested and correlated subqueries
│   ├── aggregate_grouping.sql      # GROUP BY, HAVING, aggregates
│   └── date_time_functions.sql     # Date/time manipulation
├── 03_advanced/
│   ├── window_functions.sql        # ROW_NUMBER, RANK, LAG/LEAD
│   ├── common_table_expressions.sql # CTEs and recursive queries
│   ├── pivot_unpivot.sql          # Data transformation
│   └── advanced_analytics.sql      # Statistical functions
├── 04_tsql_programming/
│   ├── variables_control_flow.sql  # T-SQL programming constructs
│   ├── stored_procedures.sql       # Procedure development
│   ├── functions_udfs.sql          # User-defined functions
│   ├── triggers_advanced.sql       # Trigger programming
│   ├── error_handling.sql          # TRY/CATCH, transactions
│   └── dynamic_sql.sql             # Dynamic query generation
├── 05_performance/
│   ├── indexing_strategies.sql     # Index design and optimization
│   ├── execution_plans.sql         # Query plan analysis
│   ├── query_optimization.sql      # Performance tuning
│   └── statistics_maintenance.sql  # Statistics and maintenance
├── 06_enterprise/
│   ├── partitioning.sql           # Table and index partitioning
│   ├── security_permissions.sql    # Security and access control
│   ├── backup_recovery.sql         # Backup and recovery strategies
│   └── high_availability.sql       # HA and disaster recovery
├── 07_data_analysis/
│   ├── moma_analysis.sql          # Museum data analysis
│   ├── business_intelligence.sql   # BI queries and reporting
│   ├── time_series_analysis.sql    # Temporal data analysis
│   └── statistical_analysis.sql    # Advanced statistics
├── 08_real_world_scenarios/
│   ├── ecommerce_queries.sql      # E-commerce use cases
│   ├── financial_reporting.sql     # Financial analysis
│   ├── social_media_analytics.sql  # Social analytics
│   └── inventory_management.sql    # Supply chain queries
└── schemas/
    ├── northwind_schema.sql        # Northwind database setup
    ├── moma_schema.sql            # MoMA database setup
    ├── enterprise_schemas.sql      # Custom business schemas
    └── sample_data.sql            # Test data generation
```

## 🚀 **Featured Examples**

### **1. Advanced Window Functions**
```sql
-- Customer order analysis with multiple window functions
SELECT
    customer_id,
    order_date,
    order_amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) as order_sequence,
    LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) as previous_order,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) as next_order_date,
    SUM(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as running_total,
    AVG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date
                           ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) as moving_avg
FROM orders
ORDER BY customer_id, order_date;
```

### **2. Recursive Common Table Expression**
```sql
-- Organizational hierarchy traversal
WITH EmployeeHierarchy AS (
    -- Anchor: Top-level managers
    SELECT employee_id, manager_id, first_name, last_name, 0 as level,
           CAST(first_name + ' ' + last_name AS VARCHAR(MAX)) as hierarchy_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: Direct reports
    SELECT e.employee_id, e.manager_id, e.first_name, e.last_name,
           eh.level + 1,
           eh.hierarchy_path + ' -> ' + e.first_name + ' ' + e.last_name
    FROM employees e
    INNER JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM EmployeeHierarchy ORDER BY level, hierarchy_path;
```

### **3. Advanced T-SQL Procedure with Error Handling**
```sql
CREATE PROCEDURE ProcessOrderBatch
    @BatchSize INT = 100,
    @ProcessDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ProcessedCount INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Complex business logic with multiple operations
        WITH OrdersToProcess AS (
            SELECT TOP(@BatchSize) order_id, customer_id, order_amount
            FROM orders
            WHERE process_date = ISNULL(@ProcessDate, CAST(GETDATE() AS DATE))
              AND status = 'PENDING'
        )
        UPDATE o SET
            status = 'PROCESSED',
            processed_date = GETDATE()
        FROM orders o
        INNER JOIN OrdersToProcess otp ON o.order_id = otp.order_id;

        SET @ProcessedCount = @@ROWCOUNT;

        -- Audit logging
        INSERT INTO process_log (process_type, records_affected, process_date)
        VALUES ('ORDER_BATCH', @ProcessedCount, GETDATE());

        COMMIT TRANSACTION;

        PRINT 'Successfully processed ' + CAST(@ProcessedCount AS VARCHAR) + ' orders.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SET @ErrorMessage =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR) + CHAR(13) +
            'Error Message: ' + ERROR_MESSAGE() + CHAR(13) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);

        INSERT INTO error_log (error_message, error_date, procedure_name)
        VALUES (@ErrorMessage, GETDATE(), 'ProcessOrderBatch');

        THROW;
    END CATCH
END
```

## 📈 **Performance Optimization Examples**

### **Query Optimization Techniques**
- Index strategy recommendations
- Execution plan analysis
- Statistics maintenance
- Query rewriting patterns
- Partitioning strategies

### **Advanced Indexing**
- Clustered vs Non-clustered indexes
- Covering indexes
- Filtered indexes
- Columnstore indexes
- Full-text search indexes

## 🔒 **Enterprise Features**

### **Security & Permissions**
- Row-level security implementation
- Dynamic data masking
- Transparent data encryption
- Custom security predicates

### **High Availability**
- Always On Availability Groups
- Database mirroring
- Log shipping configurations
- Backup and recovery strategies

## 📊 **Business Intelligence Examples**

### **Data Warehousing Patterns**
- Star and snowflake schemas
- Slowly changing dimensions
- Fact table design patterns
- ETL process examples

### **Analytical Queries**
- Sales trend analysis
- Customer segmentation
- Cohort analysis
- Time series forecasting

## 🛠 **Setup Instructions**

### **Prerequisites**
- SQL Server 2016+ (for T-SQL features)
- PostgreSQL 12+ (for standard SQL examples)
- SQL Server Management Studio or Azure Data Studio
- Sample databases (scripts provided)

### **Database Setup**
```bash
# 1. Create sample databases
sqlcmd -S your_server -i schemas/northwind_schema.sql
sqlcmd -S your_server -i schemas/moma_schema.sql
sqlcmd -S your_server -i schemas/sample_data.sql

# 2. Run examples by category
sqlcmd -S your_server -i 01_fundamentals/basic_queries.sql
```

### **Environment Configuration**
```sql
-- Enable advanced T-SQL features
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
```

## 📚 **Learning Path**

### **Beginner Track** (Files 01_*)
1. Basic queries and filtering
2. Data types and operators
3. String and date functions
4. Simple joins

### **Intermediate Track** (Files 02_*)
1. Complex joins and subqueries
2. Aggregate functions and grouping
3. Date/time manipulation
4. Data modification operations

### **Advanced Track** (Files 03_*)
1. Window functions and analytics
2. Common table expressions
3. Pivot/unpivot operations
4. Advanced data analysis

### **Expert Track** (Files 04_* - 08_*)
1. T-SQL programming constructs
2. Performance optimization
3. Enterprise features
4. Real-world scenarios

## 🎯 **Key Concepts Demonstrated**

### **SQL Fundamentals**
- ✅ All basic SQL operations (SELECT, INSERT, UPDATE, DELETE)
- ✅ Complex WHERE clauses with multiple conditions
- ✅ All JOIN types (INNER, LEFT, RIGHT, FULL, CROSS)
- ✅ Subqueries (correlated and non-correlated)
- ✅ Set operations (UNION, INTERSECT, EXCEPT)

### **Advanced SQL Features**
- ✅ Window functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE)
- ✅ Analytical functions (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
- ✅ Common Table Expressions (CTEs) and recursive queries
- ✅ PIVOT and UNPIVOT operations
- ✅ MERGE statements for complex data synchronization

### **T-SQL Programming**
- ✅ Variables, control flow (IF/ELSE, WHILE loops)
- ✅ Stored procedures with parameters and return values
- ✅ User-defined functions (scalar, table-valued, multi-statement)
- ✅ Triggers (AFTER, INSTEAD OF, DDL triggers)
- ✅ Error handling with TRY/CATCH blocks
- ✅ Transaction management and isolation levels

### **Performance & Optimization**
- ✅ Index design and maintenance strategies
- ✅ Execution plan analysis and optimization
- ✅ Query hints and plan guides
- ✅ Statistics creation and maintenance
- ✅ Partitioning strategies for large tables

### **Enterprise Features**
- ✅ Security implementations (RLS, DDM, TDE)
- ✅ High availability configurations
- ✅ Backup and recovery procedures
- ✅ Database maintenance plans
- ✅ Performance monitoring and tuning

## 🔍 **Real-World Applications**

Each example is designed to solve actual business problems:
- **E-commerce**: Product recommendations, sales analysis
- **Finance**: Risk assessment, regulatory reporting
- **Healthcare**: Patient analytics, outcome tracking
- **Manufacturing**: Quality control, supply chain optimization
- **Social Media**: User engagement, content analysis

## 📈 **Portfolio Highlights**

This collection demonstrates:
- **Depth**: From basic queries to complex analytical solutions
- **Breadth**: Coverage of all major SQL and T-SQL features
- **Practicality**: Real-world business scenarios
- **Performance**: Optimization techniques and best practices
- **Enterprise**: Production-ready solutions and patterns

## 🤝 **Contributing**

Contributions welcome! Please ensure:
- Examples are well-documented with comments
- Include expected output or results
- Follow consistent formatting standards
- Add appropriate test data if needed

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Demonstrating comprehensive SQL mastery from fundamentals to enterprise-level database solutions.*