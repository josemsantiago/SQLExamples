/*
================================================================================
01_FUNDAMENTALS: BASIC QUERIES
================================================================================
This file demonstrates fundamental SQL query operations including:
- SELECT statements with various clauses
- WHERE conditions and filtering
- ORDER BY sorting
- DISTINCT for unique values
- Basic aggregate functions
- LIMIT/TOP for result limiting

Author: Jose Santiago Echevarria
Created: 2025
================================================================================
*/

-- =============================================================================
-- 1. BASIC SELECT OPERATIONS
-- =============================================================================

-- 1.1: Select all columns from a table
SELECT *
FROM employees;

-- 1.2: Select specific columns
SELECT employee_id, first_name, last_name, hire_date
FROM employees;

-- 1.3: Select with column aliases
SELECT
    employee_id AS emp_id,
    first_name + ' ' + last_name AS full_name,
    hire_date AS date_hired,
    salary AS annual_salary
FROM employees;

-- 1.4: Select with calculated columns
SELECT
    product_name,
    unit_price,
    units_in_stock,
    unit_price * units_in_stock AS inventory_value,
    CASE
        WHEN units_in_stock = 0 THEN 'Out of Stock'
        WHEN units_in_stock < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM products;

-- =============================================================================
-- 2. WHERE CLAUSE AND FILTERING
-- =============================================================================

-- 2.1: Basic WHERE conditions
SELECT customer_id, company_name, city, country
FROM customers
WHERE country = 'USA';

-- 2.2: Multiple conditions with AND
SELECT product_id, product_name, unit_price, category_id
FROM products
WHERE unit_price > 20.00
  AND category_id = 1
  AND discontinued = 0;

-- 2.3: Multiple conditions with OR
SELECT employee_id, first_name, last_name, city
FROM employees
WHERE city = 'Seattle'
   OR city = 'London'
   OR city = 'Tacoma';

-- 2.4: Using IN operator
SELECT customer_id, company_name, country
FROM customers
WHERE country IN ('Germany', 'France', 'Spain', 'Italy');

-- 2.5: Using BETWEEN for ranges
SELECT product_id, product_name, unit_price
FROM products
WHERE unit_price BETWEEN 10.00 AND 50.00;

-- 2.6: Using LIKE for pattern matching
SELECT customer_id, company_name, contact_name
FROM customers
WHERE company_name LIKE 'A%'  -- Starts with 'A'
   OR company_name LIKE '%Ltd'  -- Ends with 'Ltd'
   OR contact_name LIKE '%John%';  -- Contains 'John'

-- 2.7: NULL value handling
SELECT employee_id, first_name, last_name, region
FROM employees
WHERE region IS NULL;

SELECT employee_id, first_name, last_name, region
FROM employees
WHERE region IS NOT NULL;

-- 2.8: Complex WHERE with parentheses
SELECT product_id, product_name, unit_price, category_id
FROM products
WHERE (category_id = 1 OR category_id = 2)
  AND unit_price > 15.00
  AND discontinued = 0;

-- =============================================================================
-- 3. ORDER BY CLAUSE
-- =============================================================================

-- 3.1: Single column ordering
SELECT customer_id, company_name, city
FROM customers
ORDER BY company_name;

-- 3.2: Multiple column ordering
SELECT customer_id, company_name, city, country
FROM customers
ORDER BY country, city, company_name;

-- 3.3: Ascending and descending order
SELECT product_id, product_name, unit_price
FROM products
ORDER BY unit_price DESC, product_name ASC;

-- 3.4: Order by calculated column
SELECT
    product_name,
    unit_price,
    units_in_stock,
    unit_price * units_in_stock AS inventory_value
FROM products
ORDER BY inventory_value DESC;

-- 3.5: Order by column position
SELECT customer_id, company_name, city, country
FROM customers
ORDER BY 4, 3, 2;  -- Order by 4th column (country), then 3rd (city), then 2nd (company_name)

-- =============================================================================
-- 4. DISTINCT VALUES
-- =============================================================================

-- 4.1: Select unique values
SELECT DISTINCT country
FROM customers
ORDER BY country;

-- 4.2: Distinct on multiple columns
SELECT DISTINCT city, country
FROM customers
ORDER BY country, city;

-- 4.3: Count of distinct values
SELECT COUNT(DISTINCT country) AS number_of_countries
FROM customers;

-- =============================================================================
-- 5. BASIC AGGREGATE FUNCTIONS
-- =============================================================================

-- 5.1: COUNT function
SELECT COUNT(*) AS total_employees
FROM employees;

SELECT COUNT(region) AS employees_with_region  -- Excludes NULLs
FROM employees;

-- 5.2: SUM function
SELECT SUM(unit_price * units_in_stock) AS total_inventory_value
FROM products;

-- 5.3: AVG function
SELECT AVG(unit_price) AS average_product_price
FROM products
WHERE discontinued = 0;

-- 5.4: MIN and MAX functions
SELECT
    MIN(unit_price) AS cheapest_product,
    MAX(unit_price) AS most_expensive_product,
    MIN(hire_date) AS earliest_hire_date,
    MAX(hire_date) AS latest_hire_date
FROM products p
CROSS JOIN employees e;

-- 5.5: Multiple aggregates in one query
SELECT
    COUNT(*) AS total_products,
    COUNT(CASE WHEN discontinued = 0 THEN 1 END) AS active_products,
    COUNT(CASE WHEN discontinued = 1 THEN 1 END) AS discontinued_products,
    AVG(unit_price) AS average_price,
    SUM(units_in_stock) AS total_units_in_stock
FROM products;

-- =============================================================================
-- 6. TOP/LIMIT CLAUSES
-- =============================================================================

-- 6.1: TOP in SQL Server
SELECT TOP 10 product_name, unit_price
FROM products
ORDER BY unit_price DESC;

-- 6.2: TOP with percentage
SELECT TOP 25 PERCENT customer_id, company_name
FROM customers
ORDER BY customer_id;

-- 6.3: TOP with ties
SELECT TOP 5 WITH TIES product_name, unit_price
FROM products
ORDER BY unit_price DESC;

-- Alternative for other databases (PostgreSQL, MySQL):
-- SELECT product_name, unit_price
-- FROM products
-- ORDER BY unit_price DESC
-- LIMIT 10;

-- =============================================================================
-- 7. BASIC CASE STATEMENTS
-- =============================================================================

-- 7.1: Simple CASE statement
SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price < 10 THEN 'Budget'
        WHEN unit_price BETWEEN 10 AND 50 THEN 'Standard'
        WHEN unit_price > 50 THEN 'Premium'
        ELSE 'Unknown'
    END AS price_category
FROM products;

-- 7.2: CASE with multiple conditions
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date,
    CASE
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >= 10 THEN 'Veteran'
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >= 5 THEN 'Experienced'
        WHEN DATEDIFF(YEAR, hire_date, GETDATE()) >= 2 THEN 'Intermediate'
        ELSE 'New'
    END AS experience_level,
    CASE
        WHEN region IS NULL THEN 'No Region Assigned'
        ELSE region
    END AS region_status
FROM employees;

-- =============================================================================
-- 8. BASIC STRING OPERATIONS
-- =============================================================================

-- 8.1: String concatenation
SELECT
    first_name + ' ' + last_name AS full_name,
    'Employee: ' + first_name + ' ' + last_name AS formatted_name
FROM employees;

-- 8.2: String functions
SELECT
    company_name,
    UPPER(company_name) AS company_upper,
    LOWER(company_name) AS company_lower,
    LEN(company_name) AS name_length,
    LEFT(company_name, 5) AS first_5_chars,
    RIGHT(company_name, 3) AS last_3_chars
FROM customers;

-- =============================================================================
-- 9. BASIC DATE OPERATIONS
-- =============================================================================

-- 9.1: Current date functions
SELECT
    GETDATE() AS current_datetime,
    GETUTCDATE() AS current_utc_datetime,
    CAST(GETDATE() AS DATE) AS current_date;

-- 9.2: Date parts extraction
SELECT
    hire_date,
    YEAR(hire_date) AS hire_year,
    MONTH(hire_date) AS hire_month,
    DAY(hire_date) AS hire_day,
    DATENAME(WEEKDAY, hire_date) AS hire_weekday
FROM employees;

-- 9.3: Date calculations
SELECT
    employee_id,
    first_name,
    last_name,
    hire_date,
    DATEDIFF(YEAR, hire_date, GETDATE()) AS years_employed,
    DATEDIFF(DAY, hire_date, GETDATE()) AS days_employed
FROM employees;

-- =============================================================================
-- 10. COMBINING MULTIPLE CONCEPTS
-- =============================================================================

-- 10.1: Complex query combining multiple concepts
SELECT TOP 20
    p.product_name,
    c.category_name,
    p.unit_price,
    p.units_in_stock,
    p.unit_price * p.units_in_stock AS inventory_value,
    CASE
        WHEN p.unit_price < 10 THEN 'Budget'
        WHEN p.unit_price BETWEEN 10 AND 50 THEN 'Standard'
        ELSE 'Premium'
    END AS price_category,
    CASE
        WHEN p.units_in_stock = 0 THEN 'Out of Stock'
        WHEN p.units_in_stock < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
WHERE p.discontinued = 0
  AND p.unit_price > 5.00
ORDER BY inventory_value DESC, p.product_name;

-- 10.2: Summary statistics query
SELECT
    'Product Analysis' AS analysis_type,
    COUNT(*) AS total_products,
    COUNT(CASE WHEN discontinued = 0 THEN 1 END) AS active_products,
    ROUND(AVG(unit_price), 2) AS avg_price,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    SUM(units_in_stock) AS total_inventory_units,
    ROUND(SUM(unit_price * units_in_stock), 2) AS total_inventory_value
FROM products;

/*
================================================================================
END OF BASIC QUERIES EXAMPLES
================================================================================
These examples cover the fundamental building blocks of SQL:
- SELECT statements with various options
- WHERE clause filtering with multiple operators
- ORDER BY for sorting results
- DISTINCT for unique values
- Basic aggregate functions (COUNT, SUM, AVG, MIN, MAX)
- TOP/LIMIT for result limiting
- CASE statements for conditional logic
- Basic string and date operations
- Combining multiple concepts in complex queries

Next: Proceed to 02_intermediate for joins, subqueries, and grouping operations.
================================================================================
*/