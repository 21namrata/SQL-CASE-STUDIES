-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, 
-- write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

select customer_id,group_concat(concat(p.plan_name,' on ', s.start_date)order by s.start_date asc) as 'onboarding_journey'
from subscriptions s
join plans p on s.plan_id=p.plan_id
where customer_id<=8
group by customer_id ;




-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- What is the number and percentage of customer plans after their initial free trial?
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- How many customers have upgraded to an annual plan in 2020?
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- 1
select count(distinct customer_id) as 'Total Customers'
from subscriptions s;


-- 2
select date_format(start_date,'%Y-%m-01') as 'start_of_month',
count(*) as'Trail Counts'
from subscriptions 
where plan_id=0
group by start_of_month
order by start_of_month;

-- 3
select plan_name,count(plan_name) as 'total_plans'
from subscriptions s
join plans p on s.plan_id=p.plan_id
where s.start_date > '2020-12-31'
group by plan_name;

-- 4
select count(distinct customer_id) as 'Total_customers',
round(((select count(customer_id) from subscriptions where plan_id=4)/count(distinct customer_id)*100),1) as 'Percent_of_churn_customers'
from subscriptions; 

-- 5
with trial_churn as (
select s.customer_id,s.start_date as 'trial_start_date',
su.start_date as 'churn_start_date' from subscriptions s 
join subscriptions su on 
s.customer_id=su.customer_id
where s.plan_id=0 and su.plan_id=4
and su.start_date between s.start_date and date_add(s.start_date, interval 7 day)
)
select count(distinct customer_id)  as 'Total_churned_customer_after_trial',
round(count(distinct customer_id)*100.0/
(select count(distinct customer_id) from subscriptions where plan_id=0)) as 'churn_percentage'
from trial_churn;

-- 6
select count(distinct customer_id) as 'No_of_customers_in_paid_plan',
round(count(distinct customer_id)*100.0/
(select count(distinct customer_id) from subscriptions where plan_id=0),2) as 'Paid_percentage'
from subscriptions
where plan_id in (1,2,3);

-- 7
select p.plan_name,count(distinct s.customer_id) as 'Customer_count',
round(count(distinct s.customer_id)*100.0/
(select count(distinct customer_id) from subscriptions where start_date<='2020-12-31'),1) as 'Customer_percentage'
from subscriptions s
join plans p on s.plan_id=p.plan_id
where s.start_date <='2020-12-31'
group by p.plan_name;

-- 8
select p.plan_name,count(distinct s.customer_id) as 'Total Customers'
from subscriptions s
join plans p on s.plan_id=p.plan_id
where s.plan_id=3 and start_date <='2020-12-31'
group by p.plan_name;

-- 9
with annual_customers as( 
select customer_id, max(case when plan_id=0 then start_date end) as 'trial_start_date',
max(case when plan_id=3 then start_date end) as 'annual_start_date' 
from subscriptions 
group by customer_id
having annual_start_date is not null
)
select round(avg(datediff(annual_start_date,trial_start_date)),1) as 'avg_day_to_annual_plan' from annual_customers;


-- 2nd approach
SELECT
    AVG(DATEDIFF(annual_plan_date, first_plan_date)) AS avg_days_to_annual_plan
FROM (
    SELECT
        customer_id,
        MIN(start_date) AS first_plan_date,  -- The first plan join date
        MAX(CASE WHEN plan_id = 3 THEN start_date END) AS annual_plan_date  -- Date they switched to annual plan (plan_id = 3)
    FROM
        subscriptions
    GROUP BY
        customer_id
    HAVING
        annual_plan_date IS NOT NULL  -- Only consider customers who have an annual plan
) AS customer_plan_dates;


-- 10
with date_difference as (
select customer_id,
datediff(min(case when plan_id=3 then start_date end),
min(case when plan_id=0 then start_date end)) as 'days_between'
from subscriptions 
where plan_id in (0,3)
group by customer_id
having days_between is not null
),
bucket_box as (
select customer_id,days_between, 
case 
when days_between between 0 and 30 then '0-30 days'
when days_between between 30 and 60 then '30-60 days'
when days_between between 60 and 90 then '60-90 days'
else '90+ days'
end as bucket from date_difference
)
select bucket,count(*)as 'customer_count',round(avg(days_between),1) as 'average_days'
from bucket_box
group by bucket;

-- 11
with cte1 as (
select * from subscriptions s
where start_date <='2020-12-31' and s.plan_id = 1
),
cte2 as (
select * from subscriptions s
where start_date <='2020-12-31' and s.plan_id = 2
)
select count(*) from cte1 c1
join cte2 c2 on c1.customer_id =c2.customer_id 
where c1.start_date>c2.start_date;

-- 2nd approach
SELECT COUNT(DISTINCT s1.customer_id) AS customers_downgraded
FROM subscriptions s1
JOIN subscriptions s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 2
  AND s2.plan_id = 1
  AND s1.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND s2.start_date BETWEEN '2020-01-01' AND '2020-12-31'
  AND s2.start_date > s1.start_date;
  
  
-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes 
-- amounts paid by each customer in the subscriptions table with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current 
-- billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments


select s.customer_id,s.plan_id,s.start_date,p.plan_name,p.price 
from subscriptions s join plans p on 
s.plan_id=p.plan_id 
where extract(year from start_date) =2020;






WITH RECURSIVE payments AS (
    -- Initial payments based on subscription start
    SELECT 
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date as payment_date,
        CASE
            WHEN p.plan_id = 3 THEN p.price  -- pro annual full payment
            ELSE p.price  -- monthly payments
        END as amount,
        1 as payment_order
    FROM subscriptions s
    JOIN plans p ON s.plan_id = p.plan_id
    WHERE s.plan_id != 0  -- exclude trial
        AND s.plan_id != 4  -- exclude churns
        AND YEAR(s.start_date) = 2020

    UNION ALL

    -- Recursive monthly payments
    SELECT 
        p.customer_id,
        p.plan_id,
        p.plan_name,
        DATE_ADD(p.payment_date, INTERVAL 1 MONTH) as payment_date,
        p.amount,
        p.payment_order + 1
    FROM payments p
    WHERE p.plan_id IN (1, 2)  -- only for monthly plans
        AND DATE_ADD(p.payment_date, INTERVAL 1 MONTH) <= '2020-12-31'
        -- Stop if customer has churned
        AND NOT EXISTS (
            SELECT 1 
            FROM subscriptions s2 
            WHERE s2.customer_id = p.customer_id 
                AND s2.plan_id = 4 
                AND s2.start_date <= DATE_ADD(p.payment_date, INTERVAL 1 MONTH)
        )
        -- Stop if customer has upgraded
        AND NOT EXISTS (
            SELECT 1 
            FROM subscriptions s3 
            WHERE s3.customer_id = p.customer_id 
                AND s3.plan_id > p.plan_id 
                AND s3.start_date <= DATE_ADD(p.payment_date, INTERVAL 1 MONTH)
        )
)

SELECT 
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    payment_order
FROM payments
ORDER BY customer_id, payment_date;










