-- ================================================
-- RetailCo Sales Performance Dashboard
-- SQL Analysis Queries
-- Author: Yash
-- ================================================

-- ── Q1: Total Business Performance ───────────────
SELECT 
    COUNT(order_id)                                    AS total_orders,
    ROUND(SUM(sales_amount), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                              AS total_profit,
    ROUND((SUM(profit) / SUM(sales_amount)) * 100, 2) AS profit_margin_pct
FROM orders;

-- ── Q2: Revenue by Region ────────────────────────
SELECT 
    region,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    ROUND(SUM(profit), 2)       AS total_profit,
    ROUND((SUM(profit) / SUM(sales_amount)) * 100, 2) AS profit_margin_pct
FROM orders
GROUP BY region
ORDER BY total_revenue DESC;

-- ── Q3: Top Selling Products ─────────────────────
SELECT 
    p.product_name,
    p.category,
    COUNT(o.order_id)             AS total_orders,
    SUM(o.quantity)               AS total_units_sold,
    ROUND(SUM(o.sales_amount), 2) AS total_revenue,
    ROUND(SUM(o.profit), 2)       AS total_profit,
    ROUND((SUM(o.profit) / SUM(o.sales_amount)) * 100, 2) AS margin_pct
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC;

-- ── Q4: High Discount Orders ─────────────────────
SELECT 
    CASE 
        WHEN discount_pct = 0               THEN 'No Discount'
        WHEN discount_pct BETWEEN 1 AND 10  THEN 'Low Discount'
        WHEN discount_pct BETWEEN 11 AND 20 THEN 'Medium Discount'
        WHEN discount_pct > 20              THEN 'High Discount'
    END AS discount_category,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    ROUND(SUM(profit), 2)       AS total_profit,
    ROUND(AVG(profit), 2)       AS avg_profit_per_order
FROM orders
GROUP BY discount_category
ORDER BY avg_profit_per_order DESC;

-- ── Q5: Customer + Order Details ─────────────────
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    c.segment,
    COUNT(o.order_id)             AS total_orders,
    ROUND(SUM(o.sales_amount), 2) AS total_spent,
    ROUND(SUM(o.profit), 2)       AS total_profit,
    ROUND(AVG(o.sales_amount), 2) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.city, c.segment
ORDER BY total_spent DESC
LIMIT 10;

-- ── Q6: Profit Categorization ────────────────────
SELECT 
    CASE 
        WHEN profit < 0                    THEN 'Loss'
        WHEN profit BETWEEN 0 AND 5000     THEN 'Low Profit'
        WHEN profit BETWEEN 5001 AND 20000 THEN 'Medium Profit'
        WHEN profit > 20000                THEN 'High Profit'
    END AS profit_category,
    COUNT(order_id)             AS total_orders,
    ROUND(SUM(sales_amount), 2) AS total_revenue,
    ROUND(SUM(profit), 2)       AS total_profit,
    ROUND(AVG(profit), 2)       AS avg_profit
FROM orders
GROUP BY profit_category
ORDER BY avg_profit DESC;

-- ── Q7: Monthly Sales Trend ──────────────────────
SELECT 
    DATE_FORMAT(order_date, '%Y-%m')    AS order_month,
    COUNT(order_id)                     AS total_orders,
    ROUND(SUM(sales_amount), 2)         AS monthly_revenue,
    ROUND(SUM(profit), 2)               AS monthly_profit,
    ROUND(AVG(sales_amount), 2)         AS avg_order_value
FROM orders
GROUP BY order_month
ORDER BY order_month ASC;

-- ── Q8: Above Average Orders ─────────────────────
SELECT 
    order_id,
    customer_id,
    product_id,
    region,
    ROUND(sales_amount, 2) AS sales_amount,
    ROUND(profit, 2)       AS profit
FROM orders
WHERE sales_amount > (
    SELECT AVG(sales_amount) 
    FROM orders
)
ORDER BY sales_amount DESC
LIMIT 15;

-- ── Q9: Customer Segmentation (CTE) ──────────────
WITH customer_summary AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.segment,
        c.city,
        COUNT(o.order_id)             AS total_orders,
        ROUND(SUM(o.sales_amount), 2) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment, c.city
)
SELECT 
    customer_id,
    customer_name,
    segment,
    city,
    total_orders,
    total_spent,
    CASE 
        WHEN total_spent > 500000  THEN 'VIP'
        WHEN total_spent > 200000  THEN 'Regular'
        ELSE                            'Occasional'
    END AS customer_tier
FROM customer_summary
ORDER BY total_spent DESC;

-- ── Q10: Running Total Revenue (Window Function) ──
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        ROUND(SUM(sales_amount), 2)      AS monthly_revenue
    FROM orders
    GROUP BY order_month
    ORDER BY order_month
)
SELECT 
    order_month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        ORDER BY order_month
    ), 2) AS running_total,
    ROUND(monthly_revenue * 100.0 / SUM(monthly_revenue) OVER (), 2) AS pct_of_total
FROM monthly_sales
ORDER BY order_month;

-- ── Q11: Return Rate by Product ──────────────────
SELECT 
    p.product_name,
    p.category,
    COUNT(o.order_id)              AS total_orders,
    COUNT(r.return_id)             AS total_returns,
    ROUND(COUNT(r.return_id) * 100.0 / 
          COUNT(o.order_id), 2)    AS return_rate_pct,
    ROUND(SUM(o.sales_amount), 2)  AS total_revenue,
    ROUND(SUM(o.profit), 2)        AS total_profit
FROM orders o
JOIN products p ON o.product_id = p.product_id
LEFT JOIN returns r ON o.order_id = r.order_id
GROUP BY p.product_name, p.category
ORDER BY return_rate_pct DESC;

-- ── Q12: Return Reasons Breakdown ────────────────
SELECT 
    r.reason,
    COUNT(r.return_id)              AS total_returns,
    ROUND(COUNT(r.return_id) * 100.0 / 
          (SELECT COUNT(*) FROM returns), 2) AS pct_of_returns,
    ROUND(SUM(o.sales_amount), 2)   AS revenue_at_risk,
    ROUND(SUM(o.profit), 2)         AS profit_at_risk
FROM returns r
JOIN orders o ON r.order_id = o.order_id
GROUP BY r.reason
ORDER BY total_returns DESC;