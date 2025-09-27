/*
================================================================================
05_PERFORMANCE: INDEXING STRATEGIES
================================================================================
This file demonstrates advanced SQL Server indexing strategies including:
- Clustered vs Non-clustered indexes
- Covering indexes and included columns
- Filtered indexes for specific conditions
- Columnstore indexes for analytical workloads
- Full-text search indexes
- Spatial indexes for geographic data
- Index maintenance and monitoring
- Performance analysis and optimization

Author: Jose Santiago Echevarria
Created: 2025
================================================================================
*/

-- =============================================================================
-- 1. CLUSTERED INDEX DESIGN
-- =============================================================================

-- 1.1: Optimal clustered index selection
-- Good clustered index characteristics: unique, narrow, static, ever-increasing

-- Example: Orders table with optimal clustered index
DROP INDEX IF EXISTS PK_Orders ON orders;
CREATE CLUSTERED INDEX PK_Orders ON orders (order_id);

-- Analysis query to verify clustered index effectiveness
SELECT
    i.name AS index_name,
    i.type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    ips.avg_page_space_used_in_percent
FROM sys.indexes i
INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('orders'), NULL, NULL, 'DETAILED') ips
    ON i.object_id = ips.object_id AND i.index_id = ips.index_id
WHERE i.object_id = OBJECT_ID('orders');

-- 1.2: Comparison of different clustered index choices
-- Demonstrate fragmentation with poor clustered index choice

-- Poor choice: clustered index on frequently updated column
CREATE TABLE sales_bad_clustered (
    sale_id INT IDENTITY(1,1),
    customer_id INT,
    sale_date DATETIME2,
    amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'PENDING',
    last_updated DATETIME2 DEFAULT GETDATE(),

    -- BAD: Clustered index on frequently updated column
    CLUSTERED INDEX CIX_Sales_Bad_LastUpdated (last_updated)
);

-- Good choice: clustered index on identity column
CREATE TABLE sales_good_clustered (
    sale_id INT IDENTITY(1,1),
    customer_id INT,
    sale_date DATETIME2,
    amount DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'PENDING',
    last_updated DATETIME2 DEFAULT GETDATE(),

    -- GOOD: Clustered index on ever-increasing identity
    CLUSTERED INDEX CIX_Sales_Good_SaleId (sale_id)
);

-- =============================================================================
-- 2. NON-CLUSTERED INDEX OPTIMIZATION
-- =============================================================================

-- 2.1: Single column non-clustered indexes
CREATE NONCLUSTERED INDEX IX_Customers_Country ON customers (country);
CREATE NONCLUSTERED INDEX IX_Products_CategoryId ON products (category_id);
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate ON orders (order_date);

-- 2.2: Composite indexes with optimal column ordering
-- Rule: Most selective columns first, then by query patterns

-- Optimal composite index for common WHERE clause patterns
CREATE NONCLUSTERED INDEX IX_Orders_Customer_Date_Status ON orders (
    customer_id,        -- High selectivity
    order_date,         -- Range queries
    status             -- Additional filtering
);

-- Index usage analysis
SELECT
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    s.last_user_seek,
    s.last_user_scan,
    i.name AS index_name
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
  AND s.object_id = OBJECT_ID('orders')
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC;

-- =============================================================================
-- 3. COVERING INDEXES AND INCLUDED COLUMNS
-- =============================================================================

-- 3.1: Covering index to eliminate key lookups
-- Query that benefits from covering index
SELECT customer_id, order_date, freight, shipped_date
FROM orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31'
  AND status = 'SHIPPED';

-- Covering index with included columns
CREATE NONCLUSTERED INDEX IX_Orders_Date_Status_COVERING ON orders (
    order_date,
    status
) INCLUDE (
    customer_id,
    freight,
    shipped_date
);

-- 3.2: Wide covering index for complex queries
-- Complex query requiring multiple columns
SELECT
    c.customer_id,
    c.company_name,
    c.city,
    c.country,
    COUNT(*) AS order_count,
    SUM(o.freight) AS total_freight,
    MAX(o.order_date) AS last_order_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA'
  AND o.order_date >= '2023-01-01'
GROUP BY c.customer_id, c.company_name, c.city, c.country;

-- Covering index for the above query
CREATE NONCLUSTERED INDEX IX_Customers_Country_COVERING ON customers (
    country
) INCLUDE (
    customer_id,
    company_name,
    city
);

CREATE NONCLUSTERED INDEX IX_Orders_Customer_Date_COVERING ON orders (
    customer_id,
    order_date
) INCLUDE (
    freight
);

-- =============================================================================
-- 4. FILTERED INDEXES
-- =============================================================================

-- 4.1: Filtered index for sparse data
-- Only index non-NULL regions (saves space and improves performance)
CREATE NONCLUSTERED INDEX IX_Employees_Region_Filtered ON employees (region)
WHERE region IS NOT NULL;

-- 4.2: Filtered index for specific value ranges
-- Index only for recent orders (most frequently queried)
CREATE NONCLUSTERED INDEX IX_Orders_Recent_Filtered ON orders (
    order_date,
    customer_id
) WHERE order_date >= '2023-01-01';

-- 4.3: Filtered index for active records only
CREATE NONCLUSTERED INDEX IX_Products_Active_Price ON products (
    unit_price DESC,
    product_name
) WHERE discontinued = 0;

-- Demonstrate space savings with filtered indexes
SELECT
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.has_filter,
    i.filter_definition,
    ps.used_page_count,
    ps.reserved_page_count
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('products')
ORDER BY ps.used_page_count DESC;

-- =============================================================================
-- 5. COLUMNSTORE INDEXES
-- =============================================================================

-- 5.1: Clustered columnstore for analytical workloads
-- Create fact table optimized for analytics
CREATE TABLE sales_fact_columnstore (
    sale_date DATE,
    product_id INT,
    customer_id INT,
    territory_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    total_amount AS (quantity * unit_price * (1 - discount_percent/100))
);

-- Clustered columnstore index for maximum compression and analytical performance
CREATE CLUSTERED COLUMNSTORE INDEX CCI_SalesFact ON sales_fact_columnstore;

-- 5.2: Non-clustered columnstore for mixed workloads
-- Regular table with additional columnstore for analytics
CREATE TABLE orders_with_columnstore (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    freight DECIMAL(10,2),
    ship_country VARCHAR(50),
    order_total DECIMAL(12,2)
);

-- Non-clustered columnstore for analytical queries while maintaining OLTP performance
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_Orders_Analytics ON orders_with_columnstore (
    customer_id,
    order_date,
    freight,
    ship_country,
    order_total
);

-- 5.3: Columnstore performance analysis
-- Query optimized for columnstore
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    ship_country,
    COUNT(*) AS order_count,
    SUM(order_total) AS total_sales,
    AVG(freight) AS avg_freight
FROM orders_with_columnstore
WHERE order_date >= '2020-01-01'
GROUP BY YEAR(order_date), MONTH(order_date), ship_country
ORDER BY order_year, order_month, total_sales DESC;

-- =============================================================================
-- 6. SPECIALIZED INDEX TYPES
-- =============================================================================

-- 6.1: Full-text search indexes
-- Enable full-text search on database
-- ALTER DATABASE YourDatabase SET ENABLE_BROKER;

-- Create full-text catalog
-- CREATE FULLTEXT CATALOG product_catalog AS DEFAULT;

-- Full-text index on product descriptions
/*
CREATE FULLTEXT INDEX ON products (
    product_name LANGUAGE 'English',
    description LANGUAGE 'English'
)
KEY INDEX PK_Products
ON product_catalog;
*/

-- Full-text search queries
/*
-- Contains search
SELECT product_id, product_name, description
FROM products
WHERE CONTAINS(description, 'organic AND healthy');

-- Freetext search
SELECT product_id, product_name, description
FROM products
WHERE FREETEXT((product_name, description), 'natural food supplement');

-- Ranked search with score
SELECT product_id, product_name, description, rank_score
FROM products p
INNER JOIN CONTAINSTABLE(products, description, 'vitamin OR mineral') ct
    ON p.product_id = ct.[KEY]
ORDER BY ct.RANK DESC;
*/

-- 6.2: Spatial indexes for geographic data
CREATE TABLE store_locations (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    location GEOGRAPHY
);

-- Spatial index for geography data
CREATE SPATIAL INDEX IX_StoreLocations_Geography ON store_locations (location)
USING GEOGRAPHY_GRID
WITH (
    GRIDS = (LEVEL_1 = MEDIUM, LEVEL_2 = MEDIUM, LEVEL_3 = MEDIUM, LEVEL_4 = MEDIUM),
    CELLS_PER_OBJECT = 16
);

-- Spatial queries
/*
DECLARE @search_area GEOGRAPHY = GEOGRAPHY::Point(40.7128, -74.0060, 4326).STBuffer(5000); -- 5km radius around NYC

SELECT store_id, store_name, location.STDistance(@search_area.STCentroid()) AS distance_meters
FROM store_locations
WHERE location.STIntersects(@search_area) = 1
ORDER BY distance_meters;
*/

-- =============================================================================
-- 7. INDEX MAINTENANCE AND MONITORING
-- =============================================================================

-- 7.1: Index fragmentation analysis
SELECT
    OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
    OBJECT_NAME(ips.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    ips.avg_fragmentation_in_percent,
    ips.fragment_count,
    ips.page_count,
    ips.avg_page_space_used_in_percent,
    CASE
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'NO ACTION'
    END AS recommended_action
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.page_count > 100  -- Only consider indexes with substantial size
  AND i.name IS NOT NULL   -- Exclude heap tables
ORDER BY ips.avg_fragmentation_in_percent DESC;

-- 7.2: Missing index analysis
SELECT
    migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,
    'CREATE INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' +
    REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '') + '_' +
    REPLACE(REPLACE(REPLACE(ISNULL(mid.inequality_columns,''), ', ', '_'), '[', ''), ']', '') AS index_name,
    'CREATE NONCLUSTERED INDEX IX_' + OBJECT_NAME(mid.object_id) + '_' +
    REPLACE(REPLACE(REPLACE(ISNULL(mid.equality_columns,''), ', ', '_'), '[', ''), ']', '') + '_' +
    REPLACE(REPLACE(REPLACE(ISNULL(mid.inequality_columns,''), ', ', '_'), '[', ''), ']', '') +
    ' ON ' + mid.statement +
    ' (' + ISNULL(mid.equality_columns,'') +
    CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END +
    ISNULL(mid.inequality_columns, '') + ')' +
    ISNULL(' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
    migs.user_seeks,
    migs.user_scans,
    migs.avg_total_user_cost,
    migs.avg_user_impact,
    OBJECT_NAME(mid.object_id) AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10
ORDER BY improvement_measure DESC;

-- 7.3: Index usage statistics
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    i.is_unique,
    i.is_primary_key,
    ISNULL(ius.user_seeks, 0) AS user_seeks,
    ISNULL(ius.user_scans, 0) AS user_scans,
    ISNULL(ius.user_lookups, 0) AS user_lookups,
    ISNULL(ius.user_updates, 0) AS user_updates,
    ius.last_user_seek,
    ius.last_user_scan,
    ius.last_user_lookup,
    ius.last_user_update,
    ps.used_page_count,
    ps.reserved_page_count,
    CASE
        WHEN ius.user_updates > 0 AND (ius.user_seeks + ius.user_scans + ius.user_lookups) = 0
            THEN 'Consider dropping - only updates, no reads'
        WHEN ius.user_seeks + ius.user_scans + ius.user_lookups < ius.user_updates / 10
            THEN 'Low read/write ratio - review necessity'
        ELSE 'Good usage'
    END AS usage_assessment
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = DB_ID()
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id > 100  -- Exclude system tables
  AND i.name IS NOT NULL  -- Exclude heap tables
ORDER BY ps.used_page_count DESC;

-- =============================================================================
-- 8. INDEX MAINTENANCE PROCEDURES
-- =============================================================================

-- 8.1: Automated index maintenance procedure
CREATE PROCEDURE MaintainIndexes
    @FragmentationThreshold FLOAT = 10.0,
    @RebuildThreshold FLOAT = 30.0,
    @MinPageCount INT = 100,
    @MaxDegreeOfParallelism INT = 0,
    @OnlineRebuild BIT = 1,
    @DryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @ActionCount INT = 0;

    -- Log maintenance start
    PRINT 'Starting index maintenance at ' + CAST(@StartTime AS VARCHAR(23));

    IF @DryRun = 1
        PRINT 'DRY RUN MODE - No actual maintenance will be performed';

    DECLARE maintenance_cursor CURSOR FOR
    SELECT
        OBJECT_SCHEMA_NAME(ips.object_id) + '.' + OBJECT_NAME(ips.object_id) AS table_name,
        i.name AS index_name,
        ips.avg_fragmentation_in_percent,
        ips.page_count,
        CASE
            WHEN ips.avg_fragmentation_in_percent >= @RebuildThreshold THEN 'REBUILD'
            WHEN ips.avg_fragmentation_in_percent >= @FragmentationThreshold THEN 'REORGANIZE'
            ELSE 'NONE'
        END AS action_type
    FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.page_count >= @MinPageCount
      AND i.name IS NOT NULL
      AND ips.avg_fragmentation_in_percent >= @FragmentationThreshold
    ORDER BY ips.avg_fragmentation_in_percent DESC;

    DECLARE @TableName NVARCHAR(256), @IndexName NVARCHAR(128), @Fragmentation FLOAT, @PageCount BIGINT, @Action NVARCHAR(20);

    OPEN maintenance_cursor;
    FETCH NEXT FROM maintenance_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount, @Action;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Action = 'REBUILD'
        BEGIN
            SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON ' + @TableName + ' REBUILD';

            IF @OnlineRebuild = 1
                SET @SQL = @SQL + ' WITH (ONLINE = ON';
            ELSE
                SET @SQL = @SQL + ' WITH (';

            IF @MaxDegreeOfParallelism > 0
                SET @SQL = @SQL + ', MAXDOP = ' + CAST(@MaxDegreeOfParallelism AS VARCHAR);

            SET @SQL = @SQL + ')';
        END
        ELSE IF @Action = 'REORGANIZE'
        BEGIN
            SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON ' + @TableName + ' REORGANIZE';
        END;

        PRINT 'Table: ' + @TableName + ', Index: ' + @IndexName +
              ', Fragmentation: ' + CAST(ROUND(@Fragmentation, 2) AS VARCHAR) +
              '%, Pages: ' + CAST(@PageCount AS VARCHAR) + ', Action: ' + @Action;

        IF @DryRun = 0
        BEGIN
            BEGIN TRY
                EXEC sp_executesql @SQL;
                SET @ActionCount = @ActionCount + 1;
            END TRY
            BEGIN CATCH
                PRINT 'ERROR: ' + ERROR_MESSAGE();
            END CATCH;
        END
        ELSE
        BEGIN
            PRINT 'Would execute: ' + @SQL;
            SET @ActionCount = @ActionCount + 1;
        END;

        FETCH NEXT FROM maintenance_cursor INTO @TableName, @IndexName, @Fragmentation, @PageCount, @Action;
    END;

    CLOSE maintenance_cursor;
    DEALLOCATE maintenance_cursor;

    DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
    PRINT '========================================';
    PRINT 'Index maintenance completed';
    PRINT 'Duration: ' + CAST(@Duration AS VARCHAR) + ' seconds';
    PRINT 'Actions performed: ' + CAST(@ActionCount AS VARCHAR);
END;
GO

-- =============================================================================
-- 9. PERFORMANCE TESTING AND VALIDATION
-- =============================================================================

-- 9.1: Index effectiveness testing
-- Test query performance with and without indexes

-- Clear plan cache for accurate testing
-- DBCC FREEPROCCACHE;

-- Test query
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Query 1: Test covering index effectiveness
SELECT customer_id, order_date, freight, shipped_date
FROM orders
WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31'
  AND status = 'SHIPPED';

-- Query 2: Test filtered index effectiveness
SELECT employee_id, first_name, last_name, region
FROM employees
WHERE region = 'WA';

-- Query 3: Test composite index effectiveness
SELECT customer_id, COUNT(*) AS order_count, SUM(freight) AS total_freight
FROM orders
WHERE customer_id = 'ALFKI'
  AND order_date >= '2023-01-01'
GROUP BY customer_id;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- 9.2: Index size and storage analysis
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS schema_name,
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    ps.used_page_count,
    ps.reserved_page_count,
    (ps.used_page_count * 8.0) / 1024 AS used_space_mb,
    (ps.reserved_page_count * 8.0) / 1024 AS reserved_space_mb,
    ps.row_count
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id > 100
  AND i.name IS NOT NULL
ORDER BY ps.used_page_count DESC;

/*
================================================================================
END OF INDEXING STRATEGIES EXAMPLES
================================================================================
These examples demonstrate:

1. CLUSTERED INDEX DESIGN:
   - Optimal clustered index selection criteria
   - Impact of clustered index choice on performance
   - Fragmentation analysis and monitoring

2. NON-CLUSTERED INDEXES:
   - Single column vs composite indexes
   - Column ordering strategies
   - Index usage pattern analysis

3. COVERING INDEXES:
   - Eliminating key lookups
   - INCLUDE column usage
   - Wide covering indexes for complex queries

4. FILTERED INDEXES:
   - Space-efficient indexing for sparse data
   - Date range filtering
   - Active record indexing

5. COLUMNSTORE INDEXES:
   - Clustered columnstore for analytical workloads
   - Non-clustered columnstore for mixed OLTP/OLAP
   - Compression and performance benefits

6. SPECIALIZED INDEXES:
   - Full-text search capabilities
   - Spatial indexes for geographic data
   - XML indexes for structured documents

7. INDEX MAINTENANCE:
   - Fragmentation monitoring
   - Missing index identification
   - Usage statistics analysis
   - Automated maintenance procedures

8. PERFORMANCE VALIDATION:
   - Testing methodologies
   - Statistics analysis
   - Storage impact assessment

Best practices covered:
- Index design principles
- Maintenance strategies
- Performance monitoring
- Storage optimization
- Query plan analysis

Next: Explore query optimization and execution plan analysis.
================================================================================
*/