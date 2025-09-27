/*
================================================================================
03_ADVANCED: WINDOW FUNCTIONS
================================================================================
This file demonstrates advanced SQL window functions including:
- ROW_NUMBER, RANK, DENSE_RANK, NTILE
- LAG, LEAD, FIRST_VALUE, LAST_VALUE
- Aggregate window functions with frames
- Partitioning and ordering
- Advanced analytical scenarios

Window functions perform calculations across a set of table rows that are
somehow related to the current row, without using GROUP BY.

Author: Jose Santiago Echevarria
Created: 2025
================================================================================
*/

-- =============================================================================
-- 1. RANKING WINDOW FUNCTIONS
-- =============================================================================

-- 1.1: ROW_NUMBER - Assigns unique sequential integers
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date,
    salary,
    ROW_NUMBER() OVER (ORDER BY hire_date) AS hire_sequence,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS salary_rank,
    ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_salary_rank
FROM employees;

-- 1.2: RANK - Assigns ranks with gaps for ties
SELECT
    product_id,
    product_name,
    unit_price,
    category_id,
    RANK() OVER (ORDER BY unit_price DESC) AS price_rank_overall,
    RANK() OVER (PARTITION BY category_id ORDER BY unit_price DESC) AS price_rank_in_category,
    DENSE_RANK() OVER (ORDER BY unit_price DESC) AS dense_price_rank
FROM products
WHERE discontinued = 0;

-- 1.3: DENSE_RANK - Assigns ranks without gaps
SELECT
    customer_id,
    order_date,
    order_amount,
    RANK() OVER (ORDER BY order_amount DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY order_amount DESC) AS rank_no_gaps,
    ROW_NUMBER() OVER (ORDER BY order_amount DESC) AS unique_rank
FROM orders
WHERE order_date >= '2023-01-01';

-- 1.4: NTILE - Distributes rows into specified number of groups
SELECT
    customer_id,
    total_orders,
    total_amount,
    NTILE(4) OVER (ORDER BY total_amount DESC) AS quartile,
    NTILE(10) OVER (ORDER BY total_amount DESC) AS decile,
    CASE
        WHEN NTILE(4) OVER (ORDER BY total_amount DESC) = 1 THEN 'Top 25%'
        WHEN NTILE(4) OVER (ORDER BY total_amount DESC) = 2 THEN 'Upper Middle 25%'
        WHEN NTILE(4) OVER (ORDER BY total_amount DESC) = 3 THEN 'Lower Middle 25%'
        ELSE 'Bottom 25%'
    END AS customer_segment
FROM (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_amount) AS total_amount
    FROM orders
    GROUP BY customer_id
) customer_summary;

-- =============================================================================
-- 2. VALUE WINDOW FUNCTIONS (LAG, LEAD, FIRST_VALUE, LAST_VALUE)
-- =============================================================================

-- 2.1: LAG and LEAD - Access previous and next rows
SELECT
    order_id,
    customer_id,
    order_date,
    order_amount,
    LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_amount,
    LEAD(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_amount,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date,
    DATEDIFF(DAY,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date),
        order_date
    ) AS days_since_last_order
FROM orders
WHERE customer_id IN ('ALFKI', 'ANATR', 'ANTON')
ORDER BY customer_id, order_date;

-- 2.2: FIRST_VALUE and LAST_VALUE with frame specification
SELECT
    employee_id,
    first_name,
    last_name,
    department_id,
    salary,
    hire_date,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_hired_salary,
    LAST_VALUE(salary) OVER (
        PARTITION BY department_id
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_hired_salary,
    FIRST_VALUE(first_name + ' ' + last_name) OVER (
        PARTITION BY department_id
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS highest_paid_in_dept
FROM employees;

-- =============================================================================
-- 3. AGGREGATE WINDOW FUNCTIONS
-- =============================================================================

-- 3.1: Running totals and cumulative calculations
SELECT
    order_id,
    customer_id,
    order_date,
    order_amount,
    SUM(order_amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    AVG(order_amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_average,
    COUNT(*) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS order_sequence_number
FROM orders
WHERE customer_id IN ('ALFKI', 'ANATR')
ORDER BY customer_id, order_date;

-- 3.2: Moving averages and sliding windows
SELECT
    product_id,
    order_date,
    quantity_sold,
    unit_price,
    quantity_sold * unit_price AS daily_revenue,
    AVG(quantity_sold) OVER (
        PARTITION BY product_id
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_days,
    SUM(quantity_sold * unit_price) OVER (
        PARTITION BY product_id
        ORDER BY order_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS revenue_last_30_days,
    MIN(quantity_sold) OVER (
        PARTITION BY product_id
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND 6 FOLLOWING
    ) AS min_quantity_13_day_window,
    MAX(quantity_sold) OVER (
        PARTITION BY product_id
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND 6 FOLLOWING
    ) AS max_quantity_13_day_window
FROM daily_sales
WHERE product_id IN (1, 2, 3)
ORDER BY product_id, order_date;

-- =============================================================================
-- 4. FRAME SPECIFICATIONS
-- =============================================================================

-- 4.1: Different frame types demonstration
SELECT
    employee_id,
    department_id,
    salary,
    hire_date,
    -- ROWS frame: Physical number of rows
    AVG(salary) OVER (
        ORDER BY hire_date
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS avg_salary_5_rows,

    -- RANGE frame: Logical range based on values
    AVG(salary) OVER (
        ORDER BY hire_date
        RANGE BETWEEN INTERVAL '1' YEAR PRECEDING AND INTERVAL '1' YEAR FOLLOWING
    ) AS avg_salary_2_year_range,

    -- Unbounded frames
    SUM(salary) OVER (
        PARTITION BY department_id
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_salary_cost,

    SUM(salary) OVER (
        PARTITION BY department_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS total_dept_salary
FROM employees;

-- =============================================================================
-- 5. COMPLEX ANALYTICAL SCENARIOS
-- =============================================================================

-- 5.1: Customer behavior analysis
WITH customer_orders AS (
    SELECT
        customer_id,
        order_date,
        order_amount,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date,
        LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_amount
    FROM orders
),
customer_metrics AS (
    SELECT
        customer_id,
        order_date,
        order_amount,
        DATEDIFF(DAY, prev_order_date, order_date) AS days_between_orders,
        order_amount - prev_order_amount AS amount_change,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence
    FROM customer_orders
)
SELECT
    customer_id,
    order_sequence,
    order_date,
    order_amount,
    days_between_orders,
    amount_change,
    AVG(days_between_orders) OVER (
        PARTITION BY customer_id
        ORDER BY order_date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS avg_days_between_last_5_orders,
    CASE
        WHEN days_between_orders IS NULL THEN 'First Order'
        WHEN days_between_orders <= 30 THEN 'Frequent'
        WHEN days_between_orders <= 90 THEN 'Regular'
        WHEN days_between_orders <= 180 THEN 'Occasional'
        ELSE 'Rare'
    END AS customer_frequency_type
FROM customer_metrics
ORDER BY customer_id, order_sequence;

-- 5.2: Sales trend analysis with year-over-year comparison
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(order_amount) AS monthly_sales,
    LAG(SUM(order_amount), 12) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS same_month_last_year,
    ROUND(
        (SUM(order_amount) - LAG(SUM(order_amount), 12) OVER (ORDER BY YEAR(order_date), MONTH(order_date)))
        / LAG(SUM(order_amount), 12) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) * 100, 2
    ) AS yoy_growth_percent,
    AVG(SUM(order_amount)) OVER (
        ORDER BY YEAR(order_date), MONTH(order_date)
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) AS moving_avg_12_months,
    RANK() OVER (ORDER BY SUM(order_amount) DESC) AS rank_all_months,
    RANK() OVER (PARTITION BY YEAR(order_date) ORDER BY SUM(order_amount) DESC) AS rank_within_year
FROM orders
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;

-- 5.3: Employee performance ranking with percentiles
SELECT
    employee_id,
    first_name + ' ' + last_name AS full_name,
    department_id,
    salary,
    performance_score,
    RANK() OVER (ORDER BY performance_score DESC) AS performance_rank,
    PERCENT_RANK() OVER (ORDER BY performance_score DESC) AS performance_percentile,
    CUME_DIST() OVER (ORDER BY performance_score DESC) AS cumulative_distribution,
    NTILE(10) OVER (ORDER BY performance_score DESC) AS performance_decile,
    CASE
        WHEN PERCENT_RANK() OVER (ORDER BY performance_score DESC) <= 0.1 THEN 'Top 10%'
        WHEN PERCENT_RANK() OVER (ORDER BY performance_score DESC) <= 0.25 THEN 'Top 25%'
        WHEN PERCENT_RANK() OVER (ORDER BY performance_score DESC) <= 0.5 THEN 'Above Average'
        WHEN PERCENT_RANK() OVER (ORDER BY performance_score DESC) <= 0.75 THEN 'Below Average'
        ELSE 'Bottom 25%'
    END AS performance_category,
    salary - AVG(salary) OVER (PARTITION BY department_id) AS salary_vs_dept_avg,
    RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS salary_rank_in_dept
FROM employees e
LEFT JOIN employee_performance ep ON e.employee_id = ep.employee_id;

-- =============================================================================
-- 6. WINDOW FUNCTIONS WITH CONDITIONAL LOGIC
-- =============================================================================

-- 6.1: Advanced conditional window functions
SELECT
    product_id,
    product_name,
    category_id,
    unit_price,
    units_in_stock,
    -- Conditional ranking: only rank non-discontinued products
    CASE
        WHEN discontinued = 0 THEN
            RANK() OVER (PARTITION BY category_id ORDER BY unit_price DESC)
        ELSE NULL
    END AS active_price_rank,

    -- Running total with condition
    SUM(CASE WHEN discontinued = 0 THEN unit_price * units_in_stock ELSE 0 END)
        OVER (PARTITION BY category_id ORDER BY unit_price DESC
              ROWS UNBOUNDED PRECEDING) AS cumulative_active_inventory_value,

    -- Percent of total within category
    ROUND(
        (unit_price * units_in_stock) * 100.0 /
        SUM(unit_price * units_in_stock) OVER (PARTITION BY category_id), 2
    ) AS percent_of_category_value,

    -- Gap analysis: difference from category leader
    unit_price - MAX(unit_price) OVER (PARTITION BY category_id) AS price_gap_from_leader
FROM products
ORDER BY category_id, unit_price DESC;

-- 6.2: Time-based window analysis
WITH daily_sales_summary AS (
    SELECT
        CAST(order_date AS DATE) AS sale_date,
        SUM(order_amount) AS daily_total,
        COUNT(DISTINCT customer_id) AS unique_customers,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY CAST(order_date AS DATE)
)
SELECT
    sale_date,
    daily_total,
    unique_customers,
    order_count,
    -- 7-day moving average
    AVG(daily_total) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_day,

    -- Percent change from previous day
    ROUND(
        (daily_total - LAG(daily_total) OVER (ORDER BY sale_date)) * 100.0 /
        LAG(daily_total) OVER (ORDER BY sale_date), 2
    ) AS pct_change_from_yesterday,

    -- Best and worst days in 30-day window
    MAX(daily_total) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS max_in_30_days,
    MIN(daily_total) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS min_in_30_days,

    -- Rank within month
    RANK() OVER (
        PARTITION BY YEAR(sale_date), MONTH(sale_date)
        ORDER BY daily_total DESC
    ) AS rank_within_month
FROM daily_sales_summary
ORDER BY sale_date;

/*
================================================================================
END OF WINDOW FUNCTIONS EXAMPLES
================================================================================
These examples demonstrate:

1. RANKING FUNCTIONS:
   - ROW_NUMBER(): Unique sequential numbering
   - RANK(): Ranking with gaps for ties
   - DENSE_RANK(): Ranking without gaps
   - NTILE(): Distribution into equal groups

2. VALUE FUNCTIONS:
   - LAG/LEAD: Access to previous/next rows
   - FIRST_VALUE/LAST_VALUE: Access to first/last values in window

3. AGGREGATE WINDOW FUNCTIONS:
   - Running totals and cumulative calculations
   - Moving averages and sliding windows
   - Min/Max within windows

4. FRAME SPECIFICATIONS:
   - ROWS vs RANGE frames
   - Bounded and unbounded frames
   - Custom frame definitions

5. ADVANCED SCENARIOS:
   - Customer behavior analysis
   - Time series analysis
   - Performance rankings
   - Conditional window functions

Window functions are powerful tools for analytical queries and provide
capabilities that would be difficult or impossible with standard GROUP BY.

Next: Explore Common Table Expressions (CTEs) and recursive queries.
================================================================================
*/