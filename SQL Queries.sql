/* =========================================================
   BUSINESS ANALYTICS PORTFOLIO PROJECT
   Environment: MySQL 8.0+
   Databases: sql_store, sql_invoicing, sql_inventory, sql_hr
   ========================================================= */


/* =========================================================
   SECTION 1: SALES & REVENUE ANALYTICS
   Database: sql_store
   ========================================================= */

USE sql_store;

/* 1. Total Revenue */
SELECT
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM order_items oi;


/* 2. Monthly Revenue Trend */
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    SUM(oi.quantity * oi.unit_price) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


/* 3. Top 5 Revenue-Generating Products */
SELECT
    p.name AS product_name,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY revenue DESC
LIMIT 5;


/* 4. Product Revenue Contribution (%) */
SELECT
    p.name AS product_name,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) /
        (SELECT SUM(quantity * unit_price) FROM order_items) * 100,
        2
    ) AS revenue_percentage
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name;


/* =========================================================
   SECTION 2: CUSTOMER ANALYTICS
   ========================================================= */

/* 5. Customer Lifetime Value (CLV) */
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.quantity * oi.unit_price) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, customer_name
ORDER BY lifetime_value DESC;


/* 6. Customer Segmentation (Window Function + CASE) */
WITH customer_revenue AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, customer_name
)
SELECT
    customer_name,
    revenue,
    NTILE(4) OVER (ORDER BY revenue DESC) AS quartile,
    CASE
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 1 THEN 'Top Customers'
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 2 THEN 'High Value'
        WHEN NTILE(4) OVER (ORDER BY revenue DESC) = 3 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_revenue;


/* =========================================================
   SECTION 3: ORDER & DELIVERY PERFORMANCE
   ========================================================= */

/* 7. Order Status Distribution */
SELECT
    os.name AS order_status,
    COUNT(*) AS order_count
FROM orders o
JOIN order_statuses os ON o.status = os.order_status_id
GROUP BY os.name;


/* 8. Average Shipping Time */
SELECT
    shipper_id,
    AVG(DATEDIFF(shipped_date, order_date)) AS avg_shipping_days
FROM orders
WHERE shipped_date IS NOT NULL
GROUP BY shipper_id;


/* =========================================================
   SECTION 4: INVOICING & PAYMENT ANALYTICS
   Database: sql_invoicing
   ========================================================= */

USE sql_invoicing;

/* 9. Total Outstanding Balance */
SELECT
    SUM(invoice_total - payment_total) AS outstanding_balance
FROM invoices;


/* 10. Payment Timeliness Analysis */
SELECT
    CASE
        WHEN payment_date IS NULL THEN 'Unpaid'
        WHEN payment_date <= due_date THEN 'On Time'
        ELSE 'Late'
    END AS payment_status,
    COUNT(*) AS invoice_count
FROM invoices
GROUP BY payment_status;


/* 11. Average Days to Payment */
SELECT
    AVG(DATEDIFF(payment_date, invoice_date)) AS avg_days_to_payment
FROM invoices
WHERE payment_date IS NOT NULL;


/* 12. Client Financial Risk Classification */
SELECT
    c.name AS client_name,
    SUM(i.invoice_total - i.payment_total) AS outstanding_balance,
    CASE
        WHEN SUM(i.invoice_total - i.payment_total) > 300 THEN 'High Risk'
        WHEN SUM(i.invoice_total - i.payment_total) BETWEEN 100 AND 300 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM clients c
JOIN invoices i ON c.client_id = i.client_id
GROUP BY c.name;


/* =========================================================
   SECTION 5: INVENTORY ANALYTICS
   Database: sql_inventory
   ========================================================= */

USE sql_inventory;

/* 13. Inventory Health Status */
SELECT
    name AS product_name,
    quantity_in_stock,
    CASE
        WHEN quantity_in_stock < 20 THEN 'Critical'
        WHEN quantity_in_stock BETWEEN 20 AND 50 THEN 'Low'
        ELSE 'Healthy'
    END AS stock_status
FROM products;


/* 14. Total Inventory Value */
SELECT
    SUM(quantity_in_stock * unit_price) AS total_inventory_value
FROM products;


/* =========================================================
   SECTION 6: HR ANALYTICS
   Database: sql_hr
   ========================================================= */

USE sql_hr;

/* 15. Average Salary by Office Location */
SELECT
    o.city,
    AVG(e.salary) AS avg_salary
FROM employees e
JOIN offices o ON e.office_id = o.office_id
GROUP BY o.city;


/* 16. Employee Salary Band Distribution */
SELECT
    CASE
        WHEN salary < 60000 THEN 'Low'
        WHEN salary BETWEEN 60000 AND 90000 THEN 'Mid'
        ELSE 'High'
    END AS salary_band,
    COUNT(*) AS employee_count
FROM employees
GROUP BY salary_band;


/* 17. Manager Span of Control */
SELECT
    reports_to AS manager_id,
    COUNT(*) AS direct_reports
FROM employees
WHERE reports_to IS NOT NULL
GROUP BY reports_to;

/* ===================== END OF FILE ===================== */
