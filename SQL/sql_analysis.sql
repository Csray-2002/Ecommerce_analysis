
use OlistAnalytics

-- Q1. what is  the total orders
select count(distinct(order_id)) as total_order from orders_master

-- Q2 what is total_revenue
select Round(SUM(payment_value),2) as Total_Revenue from payments

-- Q3 what is average order value
select ROUND(sum(p.payment_value) / COUNT(distinct(o.order_id)),2) as AOV
from orders_master o join payments p on o.order_id = p.order_id where o.order_status = 
'delivered'



-- 4 How many orders are there per order_status?
select COUNT(order_id) as Number_of_orders,order_status from orders_master group by order_status

--5 calculate the montly revenue and order count
select 
YEAR(o.order_purchase_timestamp) as year_of_order,
MONTH(o.order_purchase_timestamp) as month_order,
COUNT(distinct(o.order_id)) as total_orders,
round(SUM(oi.price),2) as item_revenuie
from orders_master o
join orders_items oi
on o.order_id=oi.order_id
where o.order_status = 'delivered'
group by YEAR(o.order_purchase_timestamp),
MONTH(o.order_purchase_timestamp)
order by year_of_order,month_order


-- q6 top 10 items as a revenue
SELECT TOP 10
    t.column2 AS category,
    round(SUM(oi.price),2) AS revenue
FROM orders_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.brazilian_name
GROUP BY t.column2
ORDER BY revenue DESC;



-- q7. what is the average order value per month?
select FORMAT(o.order_purchase_timestamp, 'yyyy-MM') as month,
Round(SUM(oi.price) / COUNT(Distinct(o.order_id)),2) AS AOV
from orders_master o join orders_items oi 
on o.order_id = oi.order_id
group by FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
order by month



-- Q8. Find the revenue by state and rank it and also avg order value

select c.customer_state,
COUNT(distinct(oi.order_id)) as orders,
round(SUM(oi.price),2) as revenue,
(round(SUM(oi.price),2))/(select COUNT(distinct(order_id)) from orders_items)as AOV,
RANK() over (order by sum(oi.price) desc) as revenue_rnk
from customers c 
join orders_master o on c.customer_id = o.customer_id
join orders_items oi on o.order_id=oi.order_id
group by (c.customer_state)
order by revenue_rnk


-- q9. What is the split of payment types 
--(credit card, boleto, voucher) by count and value
select payment_type, SUM(payment_value)
from payments group by payment_type

--q10. What is the average number of installments per payment type?
select payment_type, avg(payment_installments) as 'No of Installment' 
from payments
group by payment_type



-- Q11 Find the top 10 customers by total spend 
-- there is no name so we have to use the unique id.
SELECT  top 10 customer_unique_id, Round(sum(payment_value),2) as total_spend
FROM orders_master
group by customer_unique_id
order by sum(payment_value) desc



-- q12 Bucket customers into Low / Medium / High spenders 
--    with CASE and count each.
WITH c_spend AS (
    SELECT c.customer_unique_id,
           SUM(oi.price) AS total_spend
    FROM customers c
    JOIN orders_master o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT CASE
WHEN total_spend < 100 THEN 'Low'
WHEN total_spend <= 300 THEN 'Medium'
ELSE 'High'
END AS spender_type,
COUNT(*) AS customers
FROM c_spend
GROUP BY 
CASE
    WHEN total_spend < 100 THEN 'Low'
    WHEN total_spend <= 300 THEN 'Medium'
    ELSE 'High'
end


-- q.13 How many customers ordered more than once (repeat customers), 
-- and what is the repeat rate?

with cust as (
select c.customer_unique_id,
COUNT(distinct(o.order_id)) as orders
from customers c
join orders_master o on c.customer_id = o.customer_id
group by c.customer_unique_id)
select count(*) as total_customers,
SUM(case when orders > 1 then 1 else 0 end) as repeat_customer,
ROUND(SUM(case when orders > 1 then 1 else 0 end) * 100 / COUNT(*),2)
as repeat_rate
from cust
-- THIS SHOWS JUST 3 OUT OF 100 CUSTOMERS COME BACK

-- now seggregating it with 2+,3,4+ orders 
WITH cust AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders
    FROM customers c
    JOIN orders_master o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_buckets AS (
    SELECT
        customer_unique_id,
        orders,
        CASE
            WHEN orders = 1 THEN '1 Order'
            WHEN orders = 2 THEN '2 Orders'
            WHEN orders = 3 THEN '3 Orders'
            ELSE '4+ Orders'
        END AS customer_type
    FROM cust
)
SELECT
    customer_type,
    COUNT(*) AS customers,
    cast(ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM cust),
        2) as decimal(10,2)
    ) AS customer_percentage
FROM customer_buckets
GROUP BY customer_type
ORDER BY 
    CASE customer_type
        WHEN '1 Order' THEN 1
        WHEN '2 Orders' THEN 2
        WHEN '3 Orders' THEN 3
        WHEN '4+ Orders' THEN 4
    END;


-- Q14. how much percentage the order delivered late
SELECT 
COUNT(order_id) as late_delivered,
COUNT(order_id) * 100 / (select COUNT(order_id) from orders_master) 
as late_percentage
FROM orders_master
where DATEDIFF(day,order_delivered_customer_date, 
order_estimated_delivery_date) < 0


--15. What is the distribution of review scores (1-5)?
SELECT COUNT(REVIEW_ID) as no_of_reviews, review_score,
COUNT(REVIEW_ID) *100 / 
(SELECT COUNT(REVIEW_ID) FROM reviews) as review_pct
FROM reviews
GROUP BY review_score
ORDER BY review_score ASC


-- q16. Compare the average review score for late vs. 
-- on-time deliveries
WITH d AS (
    SELECT o.order_id,
           CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 'Late' ELSE 'On time' END AS delivery_status
    FROM orders_master o
    WHERE o.order_delivered_customer_date IS NOT NULL
)
SELECT d.delivery_status,
       AVG(r.review_score * 1.0) AS avg_score
FROM d
JOIN reviews r ON d.order_id = r.order_id
GROUP BY d.delivery_status;



-- q.17 Rank categories by revenue within each year (DENSE_RANK) and show the 
-- Which categories are driving revenue growth?
WITH cat_year AS (
    SELECT YEAR(o.order_purchase_timestamp) AS yr,
           t.column2 AS category,
           round(SUM(oi.price),2) AS revenue
    FROM orders_master o
    JOIN orders_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN product_category_name_translation t ON p.product_category_name = t.brazilian_name
    GROUP BY YEAR(o.order_purchase_timestamp), t.column2
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY yr ORDER BY revenue DESC) AS rnk
    FROM cat_year
)
SELECT yr, category, revenue, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY yr, rnk;


-- Q18 Calculate the month-over-month revenue growth % using LAG().
WITH monthly AS (
    SELECT
        FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.price) AS revenue
    FROM orders_master o
    JOIN orders_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT
    month,
    orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / NULLIF(orders, 0), 2) AS AOV,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    ) AS revenue_growth_pct
FROM monthly
ORDER BY month;




-- Q19 Calculate the running (cumulative) revenue by month
WITH monthly AS (
    SELECT FORMAT(o.order_purchase_timestamp, 'yyyy-MM') AS month,
           round(SUM(oi.price),1) AS revenue
    FROM orders_master o
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY FORMAT(o.order_purchase_timestamp, 'yyyy-MM')
)
SELECT month,
       revenue,
       SUM(revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) AS running_revenue
FROM monthly
ORDER BY month;



-- Q20. Do a simple RFM segmentation: recency, frequency, monetary using NTILE(4).

WITH rfm AS (
    SELECT c.customer_unique_id,
           DATEDIFF(day, MAX(o.order_purchase_timestamp),
                    (SELECT MAX(order_purchase_timestamp) FROM orders_master)) AS recency,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(oi.price) AS monetary
    FROM customers c
    JOIN orders_master o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT *,
       NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
       CASE WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 2
            ELSE 3 END AS f_score,
       NTILE(4) OVER (ORDER BY monetary) AS m_score
FROM rfm;



-- Q21 Cohort view: the number of customers per first-purchase month who purchased again in later months.

WITH first_order AS (
    SELECT c.customer_unique_id,
           MIN(o.order_purchase_timestamp) AS first_date
    FROM customers c
    JOIN orders_master o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)
SELECT FORMAT(f.first_date, 'yyyy-MM') AS cohort_month,
       DATEDIFF(month, f.first_date, o.order_purchase_timestamp) AS month_number,
       COUNT(DISTINCT f.customer_unique_id) AS customers
FROM first_order f
JOIN customers c ON f.customer_unique_id = c.customer_unique_id
JOIN orders_master o ON c.customer_id = o.customer_id
GROUP BY FORMAT(f.first_date, 'yyyy-MM'),
         DATEDIFF(month, f.first_date, o.order_purchase_timestamp)
ORDER BY cohort_month, month_number;



-- q What percentage of revenue comes from one-time vs repeat customers?
WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(oi.price) AS revenue
    FROM customers c
    JOIN orders_master o ON c.customer_id = o.customer_id
    JOIN orders_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers,
       cast(SUM(revenue) AS decimal(10,2)) AS revenue,
       cast(ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2) as 
       decimal(10,2)) AS revenue_pct
FROM cust
GROUP BY CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END;

EXEC sp_rename 
    'product_category_name_translation.column1',
    'brazilain_name',
    'COLUMN';

