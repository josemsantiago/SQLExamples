/*
================================================================================
04_TSQL_PROGRAMMING: STORED PROCEDURES
================================================================================
This file demonstrates advanced T-SQL stored procedure development including:
- Parameter handling (input, output, default values)
- Complex business logic implementation
- Error handling with TRY/CATCH blocks
- Transaction management
- Dynamic SQL generation
- Cursor operations
- Advanced control flow
- Performance optimization techniques
- Security best practices

Author: Jose Santiago Echevarria
Created: 2025
================================================================================
*/

-- =============================================================================
-- 1. BASIC STORED PROCEDURE STRUCTURE
-- =============================================================================

-- 1.1: Simple procedure with input parameters
CREATE PROCEDURE GetCustomerOrders
    @CustomerID NVARCHAR(5),
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Default date range if not provided
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(YEAR, -1, GETDATE());

    IF @EndDate IS NULL
        SET @EndDate = GETDATE();

    SELECT
        o.order_id,
        o.order_date,
        o.required_date,
        o.shipped_date,
        o.freight,
        od.product_id,
        p.product_name,
        od.unit_price,
        od.quantity,
        od.discount,
        (od.unit_price * od.quantity * (1 - od.discount)) AS line_total
    FROM orders o
    INNER JOIN order_details od ON o.order_id = od.order_id
    INNER JOIN products p ON od.product_id = p.product_id
    WHERE o.customer_id = @CustomerID
      AND o.order_date BETWEEN @StartDate AND @EndDate
    ORDER BY o.order_date DESC, o.order_id, od.product_id;
END;
GO

-- 1.2: Procedure with output parameters
CREATE PROCEDURE GetCustomerStatistics
    @CustomerID NVARCHAR(5),
    @TotalOrders INT OUTPUT,
    @TotalAmount MONEY OUTPUT,
    @AverageOrderValue MONEY OUTPUT,
    @LastOrderDate DATE OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @TotalOrders = COUNT(*),
        @TotalAmount = SUM(freight + ISNULL(order_total.total, 0)),
        @LastOrderDate = MAX(order_date)
    FROM orders o
    OUTER APPLY (
        SELECT SUM(unit_price * quantity * (1 - discount)) AS total
        FROM order_details od
        WHERE od.order_id = o.order_id
    ) order_total
    WHERE o.customer_id = @CustomerID;

    IF @TotalOrders > 0
        SET @AverageOrderValue = @TotalAmount / @TotalOrders;
    ELSE
        SET @AverageOrderValue = 0;
END;
GO

-- =============================================================================
-- 2. ADVANCED ERROR HANDLING AND TRANSACTIONS
-- =============================================================================

-- 2.1: Comprehensive error handling procedure
CREATE PROCEDURE ProcessOrderBatch
    @BatchSize INT = 100,
    @ProcessDate DATE = NULL,
    @ProcessedCount INT OUTPUT,
    @ErrorMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ProcessedCount = 0;
    SET @ErrorMessage = NULL;

    -- Validate input parameters
    IF @BatchSize <= 0 OR @BatchSize > 1000
    BEGIN
        SET @ErrorMessage = 'BatchSize must be between 1 and 1000';
        RETURN -1;
    END;

    IF @ProcessDate IS NULL
        SET @ProcessDate = CAST(GETDATE() AS DATE);

    DECLARE @TransactionStarted BIT = 0;

    BEGIN TRY
        -- Start transaction if not already in one
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @TransactionStarted = 1;
        END;

        -- Create temporary table for batch processing
        CREATE TABLE #OrdersToProcess (
            order_id INT PRIMARY KEY,
            customer_id NVARCHAR(5),
            order_amount MONEY,
            priority_level INT
        );

        -- Select orders to process with complex business logic
        INSERT INTO #OrdersToProcess (order_id, customer_id, order_amount, priority_level)
        SELECT TOP (@BatchSize)
            o.order_id,
            o.customer_id,
            ISNULL(order_total.total, 0) + o.freight AS order_amount,
            CASE
                WHEN c.customer_type = 'VIP' THEN 1
                WHEN ISNULL(order_total.total, 0) > 1000 THEN 2
                WHEN o.required_date <= DATEADD(DAY, 3, GETDATE()) THEN 3
                ELSE 4
            END AS priority_level
        FROM orders o
        INNER JOIN customers c ON o.customer_id = c.customer_id
        OUTER APPLY (
            SELECT SUM(unit_price * quantity * (1 - discount)) AS total
            FROM order_details od
            WHERE od.order_id = o.order_id
        ) order_total
        WHERE CAST(o.order_date AS DATE) = @ProcessDate
          AND o.status = 'PENDING'
        ORDER BY
            CASE
                WHEN c.customer_type = 'VIP' THEN 1
                WHEN ISNULL(order_total.total, 0) > 1000 THEN 2
                WHEN o.required_date <= DATEADD(DAY, 3, GETDATE()) THEN 3
                ELSE 4
            END,
            o.order_date;

        -- Process orders in priority order
        UPDATE o SET
            status = 'PROCESSED',
            processed_date = GETDATE(),
            processed_by = SYSTEM_USER
        FROM orders o
        INNER JOIN #OrdersToProcess otp ON o.order_id = otp.order_id;

        SET @ProcessedCount = @@ROWCOUNT;

        -- Log processing activity
        INSERT INTO processing_log (
            process_type,
            process_date,
            records_affected,
            batch_size,
            executed_by,
            execution_time
        ) VALUES (
            'ORDER_BATCH_PROCESSING',
            GETDATE(),
            @ProcessedCount,
            @BatchSize,
            SYSTEM_USER,
            GETDATE()
        );

        -- Commit transaction if we started it
        IF @TransactionStarted = 1
            COMMIT TRANSACTION;

        PRINT 'Successfully processed ' + CAST(@ProcessedCount AS VARCHAR) + ' orders.';

    END TRY
    BEGIN CATCH
        -- Rollback transaction if we started it
        IF @TransactionStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Capture error information
        SET @ErrorMessage =
            'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR) + CHAR(13) +
            'Error Message: ' + ERROR_MESSAGE() + CHAR(13) +
            'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR) + CHAR(13) +
            'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');

        -- Log error
        INSERT INTO error_log (
            error_message,
            error_date,
            procedure_name,
            error_line,
            executed_by
        ) VALUES (
            @ErrorMessage,
            GETDATE(),
            'ProcessOrderBatch',
            ERROR_LINE(),
            SYSTEM_USER
        );

        -- Re-throw the error to caller
        THROW;
    END CATCH;

    RETURN 0;
END;
GO

-- =============================================================================
-- 3. DYNAMIC SQL GENERATION
-- =============================================================================

-- 3.1: Advanced dynamic SQL with parameter validation
CREATE PROCEDURE GenerateDynamicReport
    @TableName NVARCHAR(128),
    @Columns NVARCHAR(MAX) = NULL,
    @WhereClause NVARCHAR(MAX) = NULL,
    @OrderBy NVARCHAR(MAX) = NULL,
    @TopCount INT = NULL,
    @ExecuteQuery BIT = 1,
    @GeneratedSQL NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ErrorMsg NVARCHAR(500);

    -- Validate table name exists and user has access
    IF NOT EXISTS (
        SELECT 1
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_NAME = @TableName
          AND TABLE_TYPE = 'BASE TABLE'
    )
    BEGIN
        SET @ErrorMsg = 'Table ' + QUOTENAME(@TableName) + ' does not exist or access denied.';
        THROW 50001, @ErrorMsg, 1;
    END;

    -- Default columns if not specified
    IF @Columns IS NULL OR LTRIM(RTRIM(@Columns)) = ''
    BEGIN
        SELECT @Columns = STRING_AGG(QUOTENAME(COLUMN_NAME), ', ')
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = @TableName
        ORDER BY ORDINAL_POSITION;
    END;

    -- Build the dynamic SQL
    SET @SQL = 'SELECT ';

    -- Add TOP clause if specified
    IF @TopCount IS NOT NULL AND @TopCount > 0
        SET @SQL = @SQL + 'TOP (' + CAST(@TopCount AS VARCHAR) + ') ';

    SET @SQL = @SQL + @Columns + CHAR(13) + 'FROM ' + QUOTENAME(@TableName);

    -- Add WHERE clause if specified
    IF @WhereClause IS NOT NULL AND LTRIM(RTRIM(@WhereClause)) != ''
        SET @SQL = @SQL + CHAR(13) + 'WHERE ' + @WhereClause;

    -- Add ORDER BY clause if specified
    IF @OrderBy IS NOT NULL AND LTRIM(RTRIM(@OrderBy)) != ''
        SET @SQL = @SQL + CHAR(13) + 'ORDER BY ' + @OrderBy;

    SET @GeneratedSQL = @SQL;

    -- Execute the query if requested
    IF @ExecuteQuery = 1
    BEGIN
        PRINT 'Executing Dynamic SQL:';
        PRINT @SQL;
        PRINT '----------------------------------------';

        EXEC sp_executesql @SQL;
    END;
    ELSE
    BEGIN
        PRINT 'Generated SQL (not executed):';
        PRINT @SQL;
    END;
END;
GO

-- =============================================================================
-- 4. CURSOR OPERATIONS FOR COMPLEX PROCESSING
-- =============================================================================

-- 4.1: Advanced cursor processing with business logic
CREATE PROCEDURE ProcessCustomerRenewal
    @ProcessDate DATE = NULL,
    @DryRun BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @ProcessDate IS NULL
        SET @ProcessDate = GETDATE();

    DECLARE @CustomerID NVARCHAR(5);
    DECLARE @LastOrderDate DATE;
    DECLARE @TotalOrders INT;
    DECLARE @TotalSpent MONEY;
    DECLARE @CustomerTier NVARCHAR(20);
    DECLARE @RenewalDiscount DECIMAL(5,2);
    DECLARE @ProcessedCount INT = 0;
    DECLARE @EmailsSent INT = 0;

    -- Declare cursor for customers due for renewal
    DECLARE renewal_cursor CURSOR FOR
    SELECT
        c.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(*) AS total_orders,
        SUM(order_totals.total_amount) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    OUTER APPLY (
        SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_amount
        FROM order_details od
        WHERE od.order_id = o.order_id
    ) order_totals
    WHERE c.status = 'ACTIVE'
      AND (
          MAX(o.order_date) <= DATEADD(MONTH, -6, @ProcessDate)
          OR MAX(o.order_date) IS NULL
      )
    GROUP BY c.customer_id
    HAVING COUNT(*) >= 3 OR SUM(order_totals.total_amount) >= 1000;

    OPEN renewal_cursor;

    FETCH NEXT FROM renewal_cursor
    INTO @CustomerID, @LastOrderDate, @TotalOrders, @TotalSpent;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Determine customer tier and renewal discount
        SET @CustomerTier = CASE
            WHEN @TotalSpent >= 10000 THEN 'PLATINUM'
            WHEN @TotalSpent >= 5000 THEN 'GOLD'
            WHEN @TotalSpent >= 2000 THEN 'SILVER'
            ELSE 'BRONZE'
        END;

        SET @RenewalDiscount = CASE @CustomerTier
            WHEN 'PLATINUM' THEN 25.00
            WHEN 'GOLD' THEN 20.00
            WHEN 'SILVER' THEN 15.00
            ELSE 10.00
        END;

        IF @DryRun = 0
        BEGIN
            -- Update customer tier
            UPDATE customers
            SET
                customer_tier = @CustomerTier,
                renewal_discount = @RenewalDiscount,
                last_renewal_process = @ProcessDate,
                modified_date = GETDATE()
            WHERE customer_id = @CustomerID;

            -- Create renewal offer record
            INSERT INTO customer_renewal_offers (
                customer_id,
                offer_date,
                customer_tier,
                discount_percent,
                valid_until,
                created_date
            ) VALUES (
                @CustomerID,
                @ProcessDate,
                @CustomerTier,
                @RenewalDiscount,
                DATEADD(DAY, 30, @ProcessDate),
                GETDATE()
            );

            -- Queue renewal email
            INSERT INTO email_queue (
                recipient_customer_id,
                email_type,
                subject,
                template_name,
                parameters,
                priority,
                scheduled_send_date
            ) VALUES (
                @CustomerID,
                'RENEWAL_OFFER',
                'Special Renewal Offer - ' + @CustomerTier + ' Customer',
                'customer_renewal_template',
                JSON_OBJECT(
                    'customer_tier', @CustomerTier,
                    'discount_percent', @RenewalDiscount,
                    'total_spent', @TotalSpent,
                    'last_order_date', @LastOrderDate
                ),
                CASE @CustomerTier
                    WHEN 'PLATINUM' THEN 1
                    WHEN 'GOLD' THEN 2
                    ELSE 3
                END,
                DATEADD(HOUR, 2, GETDATE())
            );

            SET @EmailsSent = @EmailsSent + 1;
        END;
        ELSE
        BEGIN
            -- Dry run output
            PRINT 'Customer: ' + @CustomerID +
                  ', Tier: ' + @CustomerTier +
                  ', Discount: ' + CAST(@RenewalDiscount AS VARCHAR) + '%' +
                  ', Total Spent: $' + CAST(@TotalSpent AS VARCHAR) +
                  ', Last Order: ' + ISNULL(CAST(@LastOrderDate AS VARCHAR), 'Never');
        END;

        SET @ProcessedCount = @ProcessedCount + 1;

        FETCH NEXT FROM renewal_cursor
        INTO @CustomerID, @LastOrderDate, @TotalOrders, @TotalSpent;
    END;

    CLOSE renewal_cursor;
    DEALLOCATE renewal_cursor;

    -- Summary output
    IF @DryRun = 1
    BEGIN
        PRINT '========================================';
        PRINT 'DRY RUN SUMMARY:';
        PRINT 'Customers that would be processed: ' + CAST(@ProcessedCount AS VARCHAR);
    END
    ELSE
    BEGIN
        PRINT 'RENEWAL PROCESSING COMPLETED:';
        PRINT 'Customers processed: ' + CAST(@ProcessedCount AS VARCHAR);
        PRINT 'Emails queued: ' + CAST(@EmailsSent AS VARCHAR);

        -- Log processing summary
        INSERT INTO processing_log (
            process_type,
            process_date,
            records_affected,
            additional_info,
            executed_by
        ) VALUES (
            'CUSTOMER_RENEWAL_PROCESSING',
            GETDATE(),
            @ProcessedCount,
            'Emails queued: ' + CAST(@EmailsSent AS VARCHAR),
            SYSTEM_USER
        );
    END;
END;
GO

-- =============================================================================
-- 5. ADVANCED BUSINESS LOGIC PROCEDURES
-- =============================================================================

-- 5.1: Complex order processing with inventory management
CREATE PROCEDURE ProcessOrderWithInventory
    @OrderID INT,
    @ForceProcess BIT = 0,
    @ProcessingResult NVARCHAR(50) OUTPUT,
    @ErrorDetails NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ProcessingResult = 'FAILED';
    SET @ErrorDetails = NULL;

    DECLARE @CustomerID NVARCHAR(5);
    DECLARE @OrderStatus NVARCHAR(20);
    DECLARE @ProductID INT;
    DECLARE @QuantityOrdered SMALLINT;
    DECLARE @UnitsInStock SMALLINT;
    DECLARE @UnitsOnOrder SMALLINT;
    DECLARE @ReorderLevel SMALLINT;
    DECLARE @Discontinued BIT;
    DECLARE @InsufficientInventory BIT = 0;
    DECLARE @BackorderItems TABLE (ProductID INT, QuantityShort SMALLINT);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate order exists and is in correct status
        SELECT @CustomerID = customer_id, @OrderStatus = status
        FROM orders
        WHERE order_id = @OrderID;

        IF @CustomerID IS NULL
        BEGIN
            SET @ErrorDetails = 'Order ID ' + CAST(@OrderID AS VARCHAR) + ' not found.';
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF @OrderStatus NOT IN ('PENDING', 'CONFIRMED')
        BEGIN
            SET @ErrorDetails = 'Order status is ' + @OrderStatus + '. Can only process PENDING or CONFIRMED orders.';
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Check inventory for all order items
        DECLARE inventory_cursor CURSOR FOR
        SELECT od.product_id, od.quantity
        FROM order_details od
        WHERE od.order_id = @OrderID;

        OPEN inventory_cursor;
        FETCH NEXT FROM inventory_cursor INTO @ProductID, @QuantityOrdered;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT
                @UnitsInStock = units_in_stock,
                @UnitsOnOrder = units_on_order,
                @ReorderLevel = reorder_level,
                @Discontinued = discontinued
            FROM products
            WHERE product_id = @ProductID;

            -- Check if product is discontinued
            IF @Discontinued = 1
            BEGIN
                SET @ErrorDetails = ISNULL(@ErrorDetails + CHAR(13), '') +
                    'Product ID ' + CAST(@ProductID AS VARCHAR) + ' is discontinued.';
                SET @InsufficientInventory = 1;
            END
            -- Check inventory availability
            ELSE IF @UnitsInStock < @QuantityOrdered
            BEGIN
                SET @ErrorDetails = ISNULL(@ErrorDetails + CHAR(13), '') +
                    'Insufficient inventory for Product ID ' + CAST(@ProductID AS VARCHAR) +
                    '. Requested: ' + CAST(@QuantityOrdered AS VARCHAR) +
                    ', Available: ' + CAST(@UnitsInStock AS VARCHAR);

                INSERT INTO @BackorderItems (ProductID, QuantityShort)
                VALUES (@ProductID, @QuantityOrdered - @UnitsInStock);

                SET @InsufficientInventory = 1;
            END;

            FETCH NEXT FROM inventory_cursor INTO @ProductID, @QuantityOrdered;
        END;

        CLOSE inventory_cursor;
        DEALLOCATE inventory_cursor;

        -- Process based on inventory availability
        IF @InsufficientInventory = 1 AND @ForceProcess = 0
        BEGIN
            SET @ProcessingResult = 'INSUFFICIENT_INVENTORY';
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- Update inventory and process order
        UPDATE p
        SET units_in_stock = p.units_in_stock - od.quantity,
            last_updated = GETDATE()
        FROM products p
        INNER JOIN order_details od ON p.product_id = od.product_id
        WHERE od.order_id = @OrderID
          AND p.units_in_stock >= od.quantity;

        -- Update order status
        UPDATE orders
        SET
            status = CASE
                WHEN @InsufficientInventory = 1 THEN 'PARTIAL'
                ELSE 'SHIPPED'
            END,
            shipped_date = CASE
                WHEN @InsufficientInventory = 0 THEN GETDATE()
                ELSE NULL
            END,
            processed_date = GETDATE(),
            processed_by = SYSTEM_USER
        WHERE order_id = @OrderID;

        -- Create backorder records if needed
        IF EXISTS (SELECT 1 FROM @BackorderItems)
        BEGIN
            INSERT INTO backorders (order_id, product_id, quantity_backordered, backorder_date)
            SELECT @OrderID, ProductID, QuantityShort, GETDATE()
            FROM @BackorderItems;
        END;

        -- Trigger reorder for low inventory items
        INSERT INTO reorder_requests (product_id, current_stock, reorder_level, requested_quantity, request_date)
        SELECT
            p.product_id,
            p.units_in_stock,
            p.reorder_level,
            p.reorder_level * 2,
            GETDATE()
        FROM products p
        INNER JOIN order_details od ON p.product_id = od.product_id
        WHERE od.order_id = @OrderID
          AND p.units_in_stock <= p.reorder_level
          AND p.discontinued = 0
          AND NOT EXISTS (
              SELECT 1 FROM reorder_requests rr
              WHERE rr.product_id = p.product_id
                AND rr.status = 'PENDING'
          );

        COMMIT TRANSACTION;

        SET @ProcessingResult = CASE
            WHEN @InsufficientInventory = 1 THEN 'PARTIAL_SUCCESS'
            ELSE 'SUCCESS'
        END;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @ErrorDetails = 'Error processing order: ' + ERROR_MESSAGE();
        SET @ProcessingResult = 'ERROR';
    END CATCH;
END;
GO

-- =============================================================================
-- 6. UTILITY AND MAINTENANCE PROCEDURES
-- =============================================================================

-- 6.1: Database maintenance and optimization procedure
CREATE PROCEDURE PerformDatabaseMaintenance
    @MaintenanceType NVARCHAR(20) = 'FULL',  -- FULL, INDEX_ONLY, STATS_ONLY
    @TablePattern NVARCHAR(128) = NULL,
    @VerboseOutput BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableName NVARCHAR(128);
    DECLARE @IndexName NVARCHAR(128);
    DECLARE @FragmentationPercent FLOAT;
    DECLARE @PageCount BIGINT;
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @TablesProcessed INT = 0;
    DECLARE @IndexesRebuilt INT = 0;
    DECLARE @StatsUpdated INT = 0;

    IF @VerboseOutput = 1
        PRINT 'Starting database maintenance at ' + CAST(@StartTime AS VARCHAR);

    -- Create temporary table for maintenance actions
    CREATE TABLE #MaintenanceActions (
        TableName NVARCHAR(128),
        IndexName NVARCHAR(128),
        ActionType NVARCHAR(20),
        FragmentationPercent FLOAT,
        PageCount BIGINT,
        SQL_Command NVARCHAR(MAX)
    );

    BEGIN TRY
        -- 1. Analyze index fragmentation
        IF @MaintenanceType IN ('FULL', 'INDEX_ONLY')
        BEGIN
            INSERT INTO #MaintenanceActions (TableName, IndexName, ActionType, FragmentationPercent, PageCount, SQL_Command)
            SELECT
                OBJECT_SCHEMA_NAME(ips.object_id) + '.' + OBJECT_NAME(ips.object_id) AS TableName,
                i.name AS IndexName,
                CASE
                    WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
                    WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
                    ELSE 'NONE'
                END AS ActionType,
                ips.avg_fragmentation_in_percent AS FragmentationPercent,
                ips.page_count AS PageCount,
                CASE
                    WHEN ips.avg_fragmentation_in_percent > 30 THEN
                        'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(ips.object_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REBUILD WITH (ONLINE = ON, SORT_IN_TEMPDB = ON)'
                    WHEN ips.avg_fragmentation_in_percent > 10 THEN
                        'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(ips.object_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REORGANIZE'
                    ELSE NULL
                END AS SQL_Command
            FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
            INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
            WHERE ips.page_count > 100  -- Only consider indexes with significant size
              AND i.type_desc IN ('CLUSTERED', 'NONCLUSTERED')
              AND (@TablePattern IS NULL OR OBJECT_NAME(ips.object_id) LIKE @TablePattern);

            -- Execute index maintenance
            DECLARE index_cursor CURSOR FOR
            SELECT SQL_Command
            FROM #MaintenanceActions
            WHERE ActionType IN ('REBUILD', 'REORGANIZE')
              AND SQL_Command IS NOT NULL;

            OPEN index_cursor;
            FETCH NEXT FROM index_cursor INTO @SQL;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF @VerboseOutput = 1
                    PRINT 'Executing: ' + @SQL;

                EXEC sp_executesql @SQL;
                SET @IndexesRebuilt = @IndexesRebuilt + 1;

                FETCH NEXT FROM index_cursor INTO @SQL;
            END;

            CLOSE index_cursor;
            DEALLOCATE index_cursor;
        END;

        -- 2. Update statistics
        IF @MaintenanceType IN ('FULL', 'STATS_ONLY')
        BEGIN
            DECLARE stats_cursor CURSOR FOR
            SELECT DISTINCT
                QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + '.' + QUOTENAME(OBJECT_NAME(object_id)) AS TableName
            FROM sys.stats s
            INNER JOIN sys.tables t ON s.object_id = t.object_id
            WHERE (@TablePattern IS NULL OR OBJECT_NAME(s.object_id) LIKE @TablePattern);

            OPEN stats_cursor;
            FETCH NEXT FROM stats_cursor INTO @TableName;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @SQL = 'UPDATE STATISTICS ' + @TableName + ' WITH FULLSCAN';

                IF @VerboseOutput = 1
                    PRINT 'Updating statistics for: ' + @TableName;

                EXEC sp_executesql @SQL;
                SET @StatsUpdated = @StatsUpdated + 1;
                SET @TablesProcessed = @TablesProcessed + 1;

                FETCH NEXT FROM stats_cursor INTO @TableName;
            END;

            CLOSE stats_cursor;
            DEALLOCATE stats_cursor;
        END;

        -- 3. Log maintenance activity
        INSERT INTO maintenance_log (
            maintenance_type,
            start_time,
            end_time,
            tables_processed,
            indexes_rebuilt,
            statistics_updated,
            executed_by
        ) VALUES (
            @MaintenanceType,
            @StartTime,
            GETDATE(),
            @TablesProcessed,
            @IndexesRebuilt,
            @StatsUpdated,
            SYSTEM_USER
        );

        IF @VerboseOutput = 1
        BEGIN
            PRINT '========================================';
            PRINT 'MAINTENANCE COMPLETED SUCCESSFULLY';
            PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StartTime, GETDATE()) AS VARCHAR) + ' seconds';
            PRINT 'Tables processed: ' + CAST(@TablesProcessed AS VARCHAR);
            PRINT 'Indexes rebuilt/reorganized: ' + CAST(@IndexesRebuilt AS VARCHAR);
            PRINT 'Statistics updated: ' + CAST(@StatsUpdated AS VARCHAR);
        END;

    END TRY
    BEGIN CATCH
        PRINT 'ERROR during maintenance: ' + ERROR_MESSAGE();

        INSERT INTO error_log (
            error_message,
            error_date,
            procedure_name,
            executed_by
        ) VALUES (
            'Database maintenance error: ' + ERROR_MESSAGE(),
            GETDATE(),
            'PerformDatabaseMaintenance',
            SYSTEM_USER
        );

        THROW;
    END CATCH;
END;
GO

/*
================================================================================
END OF STORED PROCEDURES EXAMPLES
================================================================================
These examples demonstrate:

1. BASIC PROCEDURES:
   - Input/output parameters
   - Default parameter values
   - Return values and status codes

2. ERROR HANDLING:
   - TRY/CATCH blocks
   - Transaction management
   - Error logging and reporting
   - Graceful error recovery

3. DYNAMIC SQL:
   - Parameter validation
   - SQL injection prevention
   - Dynamic query generation
   - Parameterized execution

4. CURSOR OPERATIONS:
   - Complex row-by-row processing
   - Business logic implementation
   - Performance considerations

5. ADVANCED BUSINESS LOGIC:
   - Inventory management
   - Order processing workflows
   - Customer relationship management
   - Data validation and integrity

6. MAINTENANCE PROCEDURES:
   - Index maintenance
   - Statistics updates
   - Performance monitoring
   - Automated maintenance tasks

Best practices demonstrated:
- Always use SET NOCOUNT ON
- Proper transaction handling
- Comprehensive error handling
- Parameter validation
- Security considerations
- Performance optimization
- Logging and auditing

Next: Explore user-defined functions and advanced T-SQL programming constructs.
================================================================================
*/