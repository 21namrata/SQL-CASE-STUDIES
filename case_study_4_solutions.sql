-- A. Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?
-- What is the number of nodes per region?
-- How many customers are allocated to each region?
-- How many days on average are customers reallocated to a different node?
-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

-- 1
select count(distinct node_id) as 'Total Distinct Nodes' 
from customer_nodes;

-- 2
select c.region_id,count(c.node_id) as 'Total_nodes' from
customer_nodes c join regions r on
c.region_id=r.region_id 
group by region_id;

-- 3
select c.region_id,count( distinct c.customer_id) as 'Total_Customers' from customer_nodes c
join customer_transactions ct on
c.customer_id=ct.customer_id
join regions r on c.region_id=r.region_id
group by c.region_id;


-- 4
WITH CTE AS (
    SELECT 
        CASE 
            WHEN LAG(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) = node_id 
                 AND LEAD(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) = node_id THEN 'MIDDLE' 
            WHEN LEAD(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) = node_id THEN 'START' 
            WHEN LAG(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) = node_id THEN 'END' 
            ELSE 'IGNORE' 
        END AS type, n.* 
    FROM data_bank.customer_nodes n 
    WHERE end_date != '9999-12-31' 
    ORDER BY customer_id, start_date
),
CTE2 AS (
    SELECT cte.*, 
           CASE WHEN type = 'START' THEN LEAD(end_date) OVER (ORDER BY customer_id, start_date) END AS final_end_date 
    FROM CTE 
    WHERE type IN ('START', 'END') 
    ORDER BY customer_id, start_date
),
COMBINED_TABLE AS (
SELECT * FROM (
    SELECT cte.customer_id, cte.region_id, cte.node_id, MIN(cte.start_date) AS start_date, final_end_date AS end_date 
    FROM CTE 
    JOIN CTE2 ON CTE.start_date BETWEEN CTE2.start_date AND CTE2.final_end_date AND cte.customer_id = cte2.customer_id 
    GROUP BY cte.customer_id, cte.region_id, cte.node_id, final_end_date
    UNION ALL
    SELECT customer_id, region_id, node_id, start_date, end_date 
    FROM CTE 
    WHERE type = 'IGNORE'
) temp ORDER BY customer_id,start_date)
SELECT avg(end_date-start_date+1) FROM COMBINED_TABLE;







-- 5
WITH CTE AS (
    SELECT n.*, 
           CASE 
               WHEN node_id != LAG(node_id) OVER (PARTITION BY customer_id ORDER BY start_date) THEN 1 
               ELSE 0 
           END AS node_switched 
    FROM data_bank.customer_nodes n 
    WHERE end_date != '9999-12-31'
),
CTE2 AS (
    SELECT cte.*, 
           SUM(node_switched) OVER (PARTITION BY customer_id ORDER BY start_date) AS cum_sum 
    FROM CTE
),
CTE3 AS (
    SELECT customer_id, region_id, node_id, 
           MIN(start_date) AS start_date, 
           MAX(end_date) AS end_date 
    FROM CTE2 
    GROUP BY customer_id, region_id, node_id, cum_sum 
),
CTE4 AS (
    SELECT CTE3.*, 
           DATEDIFF(end_date, start_date) + 1 AS days_stayed 
    FROM CTE3
),
RankedData AS (
    SELECT cte4.region_id, r.region_name, days_stayed,
           ROW_NUMBER() OVER (PARTITION BY cte4.region_id ORDER BY days_stayed) AS rn,
           COUNT(*) OVER (PARTITION BY cte4.region_id) AS total_rows
    FROM CTE4 
    JOIN data_bank.regions r ON cte4.region_id = r.region_id
),
PercentileRanks AS (
    SELECT region_id, region_name, 
           FLOOR(0.5 * total_rows) + 1 AS p50,
           FLOOR(0.8 * total_rows) + 1 AS p80,
           FLOOR(0.95 * total_rows) + 1 AS p95
    FROM RankedData
    GROUP BY region_id, region_name, total_rows
),
FinalSelection AS (
    SELECT rd.region_id, rd.region_name, rd.days_stayed, p.p50, p.p80, p.p95,
           ROW_NUMBER() OVER (PARTITION BY rd.region_id ORDER BY ABS(rd.rn - p.p50)) AS rn50,
           ROW_NUMBER() OVER (PARTITION BY rd.region_id ORDER BY ABS(rd.rn - p.p80)) AS rn80,
           ROW_NUMBER() OVER (PARTITION BY rd.region_id ORDER BY ABS(rd.rn - p.p95)) AS rn95
    FROM RankedData rd
    JOIN PercentileRanks p ON rd.region_id = p.region_id
)
SELECT f.region_id, f.region_name,
       MAX(CASE WHEN rn50 = 1 THEN f.days_stayed END) AS `50th percentile`,
       MAX(CASE WHEN rn80 = 1 THEN f.days_stayed END) AS `80th percentile`,
       MAX(CASE WHEN rn95 = 1 THEN f.days_stayed END) AS `95th percentile`
FROM FinalSelection f
GROUP BY f.region_id, f.region_name;





-- B. Customer Transactions
-- 1 What is the unique count and total amount for each transaction type?
-- 2 What is the average total historical deposit counts and amounts for all customers?
-- 3 For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- 4 What is the closing balance for each customer at the end of the month?
-- 5 What is the percentage of customers who increase their closing balance by more than 5%?

-- 1
select txn_type,count(*) as 'Total Count',
sum(txn_amount) as 'Total Amount' from customer_transactions 
group by txn_type;

-- 2
with cte as (
select count(*) as 'total_count',
sum(txn_amount) as 'Total_amount'  from customer_transactions 
where txn_type = 'deposit'
group by customer_id
)
select round(avg(total_count),2) as 'avg_total_count_of_all_customers',
round(avg(total_amount),2) as 'avg_total_amount_of_all_customers'
from cte;

-- 3
with cte as(
select customer_id,monthname(txn_date) as month_name,
sum(case when txn_type='deposit' then 1 else 0 end) as 'deposit_count',
sum(case when txn_type='withdrawal' then 1 else 0 end) as 'withdrawal_count',
sum(case when txn_type='purchase' then 1 else 0 end) as 'purchase_count'
from customer_transactions
group by 1,2
)
select month_name,
sum(case when (deposit_count > 1) and (purchase_count>=1 or withdrawal_count >= 1) then 1 else 0 end) as 'customer_count'
from cte 
group by month_name
order by month_name asc;



-- 4
WITH monthly_transactions AS (
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_value_per_month
    FROM data_bank.customer_transactions
    GROUP BY customer_id, month
),
running_balance AS (
    SELECT 
        customer_id,
        month,
        SUM(net_value_per_month) OVER (PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM monthly_transactions
),
all_months AS (
    SELECT 1 AS month UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4
),
all_combinations AS (
    SELECT DISTINCT c.customer_id, m.month
    FROM (SELECT DISTINCT customer_id FROM data_bank.customer_transactions) c
    CROSS JOIN all_months m
),
final_balance AS (
    SELECT 
        ac.customer_id,
        ac.month,
        COALESCE(rb.closing_balance, 
            LAG(rb.closing_balance) OVER (PARTITION BY ac.customer_id ORDER BY ac.month)) AS closing_balance
    FROM all_combinations ac
    LEFT JOIN running_balance rb 
        ON ac.customer_id = rb.customer_id AND ac.month = rb.month
)
SELECT * FROM final_balance
ORDER BY customer_id, month;


-- APPROACH 2

with cte1 as (
select customer_id,months,sum(net_value_per_month) over(partition by customer_id order by months) as closing_balance
from
(select customer_id, month(txn_date) as 'months',
sum(case when txn_type='deposit' then txn_amount else -txn_amount end) as 'net_value_per_month'
from customer_transactions
group by customer_id,month(txn_date)
order by month(txn_date),customer_id
)temp
),
cte2 as (
select customer_id,months,lead(months) over(partition by customer_id order by months) as next_month,
closing_balance
from cte1
),
cte3 AS (
    select distinct customer_id, 1 as months from CTE2
    union all select distinct customer_id, 2 from CTE2
    union all select distinct customer_id, 3 from CTE2
    union all select distinct customer_id, 4 from CTE2
),
CTE4 AS (
    select 
        c.customer_id, 
        c.months,
        coalesce(a.closing_balance, 
                 lag(a.closing_balance) over (partition by c.customer_id order by c.months)) as closing_balance
    from CTE3 c
    left join CTE2 a on c.customer_id = a.customer_id and c.months = a.months
)
select * from CTE4
order by customer_id, months;



-- 5
WITH monthly_transactions AS (
    SELECT 
        customer_id,
        EXTRACT(MONTH FROM txn_date) AS month,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount 
            ELSE -txn_amount 
        END) AS net_value_per_month
    FROM data_bank.customer_transactions
    GROUP BY customer_id, month
),
running_balance AS (
    SELECT 
        customer_id,
        month,
        SUM(net_value_per_month) OVER (PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM monthly_transactions
),
all_months AS (
    SELECT 1 AS month UNION ALL
    SELECT 2 UNION ALL
    SELECT 3 UNION ALL
    SELECT 4
),
all_combinations AS (
    SELECT DISTINCT c.customer_id, m.month
    FROM (SELECT DISTINCT customer_id FROM data_bank.customer_transactions) c
    CROSS JOIN all_months m
),
final_balance AS (
    SELECT 
        ac.customer_id,
        ac.month,
        COALESCE(rb.closing_balance, 
            LAG(rb.closing_balance) OVER (PARTITION BY ac.customer_id ORDER BY ac.month)) AS closing_balance
    FROM all_combinations ac
    LEFT JOIN running_balance rb 
        ON ac.customer_id = rb.customer_id AND ac.month = rb.month
),
final_closing_balance AS (
    SELECT 
        customer_id,
        MAX(CASE WHEN month = 1 THEN closing_balance END) AS jan_balance,
        MAX(CASE WHEN month = 4 THEN closing_balance END) AS apr_balance
    FROM final_balance
    WHERE month IN (1, 4)
    GROUP BY customer_id
)
SELECT 
    ROUND(100.0 * SUM(
        CASE 
            WHEN apr_balance > (jan_balance + (0.05 * ABS(jan_balance))) THEN 1 
            ELSE 0 
        END
    ) / NULLIF(COUNT(jan_balance), 0), 2) AS perc_of_customers
FROM final_closing_balance;









