-- 2. Data Exploration
-- What day of the week is used for each week_date value?
-- What range of week numbers are missing from the dataset?
-- How many total transactions were there for each year in the dataset?
-- What is the total sales for each region for each month?
-- What is the total count of transactions for each platform
-- What is the percentage of sales for Retail vs Shopify for each month?
-- What is the percentage of sales by demographic for each year in the dataset?
-- Which age_band and demographic values contribute the most to Retail sales?
-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
-- If not - how would you calculate it instead?

-- 1
select distinct dayname(week_date)
from weekly_sales;

-- 2
select distinct week_number from weekly_sales;

-- 3
select years,sum(transactions) from weekly_sales
group by years;

-- 4
select month_number,region,sum(sales)
from weekly_sales
group by month_number,region
order by region, month_number desc;

-- 5
select platform,count(transactions) from weekly_sales
group by platform;

-- 6
with cte as(
select month_number,
        sum(case when platform = 'Shopify' then sales end) as shopify_sales,
        sum(case when platform = 'Retail' then sales end) as retail_sales
    from weekly_sales 
    group by month_number
    order by month_number
    )
    select month_number,round(100.0 * shopify_sales/(shopify_sales+retail_sales),2) as 'shopify_percent',
    round(100.0 * retail_sales/(shopify_sales+retail_sales),2) as 'retail_percent'
    from cte ;

-- 2nd approach
select month_number, platform,
round(sum(sales)*100.0/sum(sum(sales)) over(partition by month_number),2) as 'platform_sales'
from weekly_sales
group by month_number,platform;


-- 7
with cte as(
select years,
        sum(case when demographic = 'Couples' then sales end) as couple_sales,
        sum(case when demographic = 'Families' then sales end) as family_sales,
        sum(case when demographic = 'Unknown' then sales end) as unknown_sales
    from weekly_sales 
    group by years
    order by years
    )
    select years,round(100.0 * couple_sales/(couple_sales+family_sales+unknown_sales),2) as 'couple_percent',
    round(100.0 * family_sales/(couple_sales+family_sales+unknown_sales),2) as 'family_percent',
    round(100.0 * unknown_sales/(couple_sales+family_sales+unknown_sales),2) as 'unknown_percent'
    from cte ;


-- 2nd approach
select years,demographic,
round(sum(sales)*100.0/sum(sum(sales)) over(partition by years),2) as 'demographics_sales'
from weekly_sales
group by years,demographic;

-- 8
select age_brands,demographic,sum(sales) as 'Total_sales'
from weekly_sales
where platform='Retail' 
group by age_brands, demographic
order by Total_sales desc;


-- 9
select years,platform,round(avg(avg_transactions),1) as 'avg_of_avg',
round(sum(sales)/sum(transactions),1) as 'overall_trans'
from weekly_sales
group by years,platform
order by years;



-- 3. Before & After Analysis
-- This technique is usually used when we inspect an important event and want 
-- to inspect the impact before and after a certain point in time.

-- Taking the week_date value of 2020-06-15 as the baseline week where 
-- the Data Mart sustainable packaging changes came into effect.

-- We would include all week_date values for 2020-06-15 as the start of the period 
-- after the change and the previous week_date values would be before

-- Using this analysis approach - answer the following questions:

-- What is the total sales for the 4 weeks before and after 2020-06-15? 
-- What is the growth or reduction rate in actual values and percentage of sales?
-- What about the entire 12 weeks before and after?
-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

-- 1
WITH before_and_after_analysis AS (
    SELECT 
        SUM(CASE 
            WHEN week_date BETWEEN DATE_SUB('2020-06-15', INTERVAL 4 WEEK) 
                             AND DATE_SUB('2020-06-15', INTERVAL 1 DAY) 
            THEN sales 
        END) AS before_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15' 
                             AND DATE_SUB(DATE_ADD('2020-06-15', INTERVAL 4 WEEK), INTERVAL 1 DAY) 
            THEN sales 
        END) AS after_sales
    FROM weekly_sales
)
SELECT 
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_variance,
    ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM before_and_after_analysis;

-- 2
WITH before_and_after_analysis AS (
    SELECT 
        SUM(CASE 
            WHEN week_date BETWEEN DATE_SUB('2020-06-15', INTERVAL 12 WEEK) 
                             AND DATE_SUB('2020-06-15', INTERVAL 1 DAY) 
            THEN sales 
        END) AS before_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15' 
                             AND DATE_SUB(DATE_ADD('2020-06-15', INTERVAL 12 WEEK), INTERVAL 1 DAY) 
            THEN sales 
        END) AS after_sales
    FROM weekly_sales
)
SELECT 
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_variance,
    ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM before_and_after_analysis;


-- 3
WITH before_and_after_analysis AS (
    SELECT 
        years,
        SUM(CASE 
            WHEN week_date BETWEEN DATE_SUB(CONCAT(years, '-06-15'), INTERVAL 4 WEEK) 
                             AND DATE_SUB(CONCAT(years, '-06-15'), INTERVAL 1 DAY) 
            THEN sales ELSE 0 
        END) AS before_sales,
        SUM(CASE 
            WHEN week_date BETWEEN CONCAT(years, '-06-15') 
                             AND DATE_SUB(DATE_ADD(CONCAT(years, '-06-15'), INTERVAL 4 WEEK), INTERVAL 1 DAY) 
            THEN sales ELSE 0 
        END) AS after_sales
    FROM weekly_sales
    GROUP BY years
)
SELECT 
    years,
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_variance,
    ROUND(100.0 * (after_sales - before_sales) / NULLIF(before_sales, 0), 2) AS variance_percentage
FROM before_and_after_analysis;




-- Query 2 with 12 week
WITH before_and_after_analysis AS (
    SELECT 
        years,
        SUM(CASE 
            WHEN week_date BETWEEN DATE_SUB(CONCAT(years, '-06-15'), INTERVAL 12 WEEK) 
                             AND DATE_SUB(CONCAT(years, '-06-15'), INTERVAL 1 DAY) 
            THEN sales ELSE 0 
        END) AS before_sales,
        SUM(CASE 
            WHEN week_date BETWEEN CONCAT(years, '-06-15') 
                             AND DATE_SUB(DATE_ADD(CONCAT(years, '-06-15'), INTERVAL 12 WEEK), INTERVAL 1 DAY) 
            THEN sales ELSE 0 
        END) AS after_sales
    FROM weekly_sales
    GROUP BY years
)
SELECT 
    years,
    before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_variance,
    ROUND(100.0 * (after_sales - before_sales) / NULLIF(before_sales, 0), 2) AS variance_percentage
FROM before_and_after_analysis;



-- Bonus Question
-- Which areas of the business have the highest negative impact in 
-- sales metrics performance in 2020 for the 12 week before and after period?

-- region
-- platform
-- age_band
-- demographic
-- customer_type
-- Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

WITH before_and_after_analysis AS (
    SELECT region,
        SUM(CASE 
            WHEN week_date BETWEEN DATE_SUB('2020-06-15', INTERVAL 12 WEEK) 
                             AND DATE_SUB('2020-06-15', INTERVAL 1 DAY) 
            THEN sales 
        END) AS before_sales,
        SUM(CASE 
            WHEN week_date BETWEEN '2020-06-15' 
                             AND DATE_SUB(DATE_ADD('2020-06-15', INTERVAL 12 WEEK), INTERVAL 1 DAY) 
            THEN sales 
        END) AS after_sales
    FROM weekly_sales
    group by region
)
SELECT 
    region,before_sales,
    after_sales,
    (after_sales - before_sales) AS sales_variance,
    ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS variance_percentage
FROM before_and_after_analysis;
