-- Create database and use it
CREATE DATABASE pizza_runner;
USE pizza_runner;

-- Create the runners table
DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  `runner_id` INT,
  `registration_date` DATE
);

INSERT INTO runners (`runner_id`, `registration_date`) VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

-- Create the customer_orders table
DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  `order_id` INT,
  `customer_id` INT,
  `pizza_id` INT,
  `exclusions` VARCHAR(4),
  `extras` VARCHAR(4),
  `order_time` TIMESTAMP
);

INSERT INTO customer_orders (`order_id`, `customer_id`, `pizza_id`, `exclusions`, `extras`, `order_time`) VALUES
  (1, 101, 1, '', '', '2020-01-01 18:05:02'),
  (2, 101, 1, '', '', '2020-01-01 19:00:52'),
  (3, 102, 1, '', '', '2020-01-02 23:51:23'),
  (3, 102, 2, '', NULL, '2020-01-02 23:51:23'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 2, '4', '', '2020-01-04 13:23:46'),
  (5, 104, 1, 'null', '1', '2020-01-08 21:00:29'),
  (6, 101, 2, 'null', 'null', '2020-01-08 21:03:13'),
  (7, 105, 2, 'null', '1', '2020-01-08 21:20:29'),
  (8, 102, 1, 'null', 'null', '2020-01-09 23:54:33'),
  (9, 103, 1, '4', '1, 5', '2020-01-10 11:22:59'),
  (10, 104, 1, 'null', 'null', '2020-01-11 18:34:49'),
  (10, 104, 1, '2, 6', '1, 4', '2020-01-11 18:34:49');

-- Create the runner_orders table
DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  `order_id` INT,
  `runner_id` INT,
  `pickup_time` VARCHAR(19),
  `distance` VARCHAR(7),
  `duration` VARCHAR(10),
  `cancellation` VARCHAR(23)
);

INSERT INTO runner_orders (`order_id`, `runner_id`, `pickup_time`, `distance`, `duration`, `cancellation`) VALUES
  (1, 1, '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  (2, 1, '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  (3, 1, '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  (4, 2, '2020-01-04 13:53:03', '23.4', '40', NULL),
  (5, 3, '2020-01-08 21:10:57', '10', '15', NULL),
  (6, 3, 'null', 'null', 'null', 'Restaurant Cancellation'),
  (7, 2, '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  (8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  (9, 2, 'null', 'null', 'null', 'Customer Cancellation'),
  (10, 1, '2020-01-11 18:50:20', '10km', '10minutes', 'null');

-- Create the pizza_names table
DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  `pizza_id` INT,
  `pizza_name` VARCHAR(255)
);

INSERT INTO pizza_names (`pizza_id`, `pizza_name`) VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');

-- Create the pizza_recipes table
DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  `pizza_id` INT,
  `toppings` VARCHAR(255)
);

INSERT INTO pizza_recipes (`pizza_id`, `toppings`) VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');

-- Create the pizza_toppings table
DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  `topping_id` INT,
  `topping_name` VARCHAR(255)
);

INSERT INTO pizza_toppings (`topping_id`, `topping_name`) VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');






## Handling Null and Data types of customers order table

-- Replace NULL values with defaults
UPDATE customer_orders
SET exclusions = 'None'
WHERE exclusions IS NULL or exclusions = 'null' or exclusions= '';

UPDATE customer_orders
SET extras = 'None'
WHERE extras IS NULL or extras ='null' or extras='';

-- Ensure correct data types
ALTER TABLE customer_orders
MODIFY  exclusions VARCHAR(255);
ALTER TABLE customer_orders
MODIFY  extras VARCHAR(255);

-- checking customer_orders table
SELECT * from customer_orders;



## Handling Null and Data types of runner orders table

-- removing the null or NULL value in column pickup_time and cancellation column to apprppriate value
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time ='null' or pickup_time='';

UPDATE runner_orders
SET cancellation = 'None'
WHERE cancellation IS NULL OR cancellation = 'null' OR cancellation = '';


-- Clean up the 'distance' column: Remove 'km' and extra spaces, replace NULL with '0'

UPDATE runner_orders
SET distance = TRIM(REPLACE(REPLACE(distance, ' km', ''), 'km', '')),
    distance = TRIM(REPLACE(distance, ' ', '')) -- remove any spaces
WHERE distance IS NOT NULL;

-- Clean up the 'duration' column: Remove all variations of 'min', 'minute', etc., then trim the column
UPDATE runner_orders
SET duration= trim(replace(replace(replace(replace(replace(replace(duration, 'minutes',''), ' minutes', ''), 'minute',''), ' minute',''),'mins',''),' mins',''))
WHERE duration IS NOT NULL;

-- Change NULL values in 'distance' to '0'
UPDATE runner_orders
SET distance = '0'
WHERE distance ='null';

-- Change NULL values in 'duration' to '0'
UPDATE runner_orders
SET duration = '0'
WHERE duration ='null';



-- Change pickup_time to TIMESTAMP
ALTER TABLE runner_orders
CHANGE COLUMN pickup_time pickup_time TIMESTAMP;

-- Change distance to DECIMAL(10, 2)
ALTER TABLE runner_orders
CHANGE COLUMN distance distance_in_km DECIMAL(10, 2);

-- Change duration to INT
ALTER TABLE runner_orders
CHANGE COLUMN duration duration_in_min INT;

-- Alter the column data type to VARCHAR(30) to store cancellation descriptions
ALTER TABLE runner_orders
CHANGE COLUMN cancellation cancellation VARCHAR(30) DEFAULT 'None';

#checking the runner_order table 
select * from runner_orders;






-- A. PIZZA METRICS
-- How many pizzas were ordered?
-- How many unique customer orders were made?
-- How many successful orders were delivered by each runner?
-- How many of each type of pizza was delivered?
-- How many Vegetarian and Meatlovers were ordered by each customer?
-- What was the maximum number of pizzas delivered in a single order?
-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- How many pizzas were delivered that had both exclusions and extras?
-- What was the total volume of pizzas ordered for each hour of the day?
-- What was the volume of orders for each day of the week?


-- 1
select count(*) as 'total Pizzas Ordered'
 from customer_orders;
 
 -- 2
 select count(distinct customer_id)
 from customer_orders;
 
 -- 3
select runner_id, count(*) 'Successful_order_dilevered'
 from runner_orders
where cancellation not in ('Restaurant Cancellation','Customer Cancellation')
group by runner_id;

 -- 4
select pizza_name , 
count(*) as 'Total_pizza_ordered' from customer_orders c
join pizza_names p 
on c.pizza_id=p.pizza_id
join runner_orders r on c.order_id=r.order_id
where cancellation not in ('Restaurant Cancellation','Customer Cancellation') 
group by pizza_name;

-- 5
select customer_id,pizza_name,count(*) as 'total_pizza' 
from customer_orders c
join pizza_names p on c.pizza_id=p.pizza_id
group by customer_id,pizza_name
order by customer_id;

-- 6
select c.order_id, count(*) as 'Total_pizza_delivered' from customer_orders c 
join runner_orders r on c.order_id=r.order_id
where cancellation not in ('Restaurant Cancellation', 'Customer Cancellation')
group by c.order_id
order by Total_pizza_delivered desc
limit 1;

-- 7
select c.customer_id,
sum(case when c.exclusions='None' and c.extras='None' then 1 else 0 end) as 'Pizza_without_changes',
sum(case when c.exclusions!='None' or c.extras!='None' then 1 else 0 end) as 'Pizza_with_changes'
from customer_orders c
join runner_orders r on c.order_id=r.order_id
where cancellation= 'None' 
group by c.customer_id;


-- 8
select count(*) 'Pizza_having_both_exclusions_and_extras' from customer_orders c
join runner_orders r on c.order_id=r.order_id
where cancellation not in ('Restaurant Cancellation', 'Customer Cancellation') and exclusions!='None' and extras!='None';

-- 9
select extract(hour from order_time) as 'Order_Hour',
count(*) as 'pizza_ordered' from customer_orders c
group by Order_Hour
order by Order_Hour ;

-- 10
select
    DAYNAME(order_time) AS day_of_week_name, 
    DAYOFWEEK(order_time) AS day_of_week_number,
    COUNT(*) AS total_orders  
 from
    customer_orders
group by 
     DAYNAME(order_time),DAYOFWEEK(order_time) 
order by 
    DAYOFWEEK(order_time); 









-- B. RUNNER AND CUSTOMER EXPERIENCE
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- What was the average distance travelled for each customer?
-- What was the difference between the longest and shortest delivery times for all orders?
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- What is the successful delivery percentage for each runner?

-- 1
select date_add('2021-01-01',interval(floor(datediff(registration_date,'2021-01-01')/7)) week) as'week_start_date'
,count(*) from runners
where registration_date >='2021-01-01'
group by week_start_date
order by week_start_date;

-- 2
select runner_id, round(avg(timestampdiff(second,order_time,pickup_time)/60),2) as'Avg_pickup_time_in_min'
from customer_orders c 
join runner_orders r on c.order_id=r.order_id
where order_time is not null
and pickup_time is not null
group by runner_id;


-- 3
select  c.order_id,count(*), 
sum(round((timestampdiff(second,order_time,pickup_time)/60),2)) as'pickup_time_in_min'
from customer_orders c 
join runner_orders r on c.order_id=r.order_id
where order_time is not null
and pickup_time is not null
group by c.order_id ;
-- yes there is relationalship between time taken to prepare and the no. of pizza ordered as 
-- the number of pizzas ordered increases the time taken to pickup(the preparation time ) increases.


-- 4
select customer_id, round(avg(distance_in_km),2) as'avg_distance_travelled' 
from customer_orders c 
join runner_orders r on c.order_id=r.order_id
where cancellation = 'None'
group by customer_id;

-- 5
select max(duration_in_min)- min(duration_in_min) as 'diff_between_longest_and_shortest_delivery_time'
from runner_orders
where cancellation ='None';

-- 6 
select order_id,runner_id, 
round(avg((distance_in_km * 1000) /(duration_in_min*60)),2) as 'Speed_in_ms'
from runner_orders
where cancellation='None'
group by order_id,runner_id
order by runner_id;

-- 7
select runner_id, 
round((sum(case when cancellation='None' then 1 else 0 end)*100 /count(*)),2) as 'Successful_delivery_percentage' 
from runner_orders
group by runner_id;






-- C. INGREDIENT OPTIMISATION
-- What are the standard ingredients for each pizza?
-- What was the most commonly added extra?
-- What was the most common exclusion?
-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order 
-- from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?


-- 1
select pn.pizza_name, group_concat(pt.topping_name order by pt.topping_id)
from pizza_names pn
join pizza_recipes pr on pn.pizza_id= pr.pizza_id
join pizza_toppings pt on find_in_set(pt.topping_id, replace(pr.toppings,' ',''))
group by pn.pizza_name;


-- 2
select p.topping_name,count(*) as 'most_commonly_used_extras'from customer_orders c
join pizza_toppings p on find_in_set(p.topping_id,replace(c.extras,' ',''))
group by p.topping_name
order by count(*) desc
limit 1;


-- 3
select p.topping_name, count(*) as 'most_commonly_used_exclusions' from customer_orders c
join pizza_toppings p on find_in_set(p.topping_id,replace(c.exclusions,' ',''))
group by p.topping_name 
order by count(*) desc
limit 1;


-- 4
SELECT 
    order_id,
    CASE 
        WHEN exclusions = 'None' AND extras = 'None' THEN pizza_name
        WHEN exclusions != 'None' AND extras = 'None' THEN 
            CONCAT(pizza_name, ' - Exclude ', 
                  GROUP_CONCAT(DISTINCT pt.topping_name ORDER BY pt.topping_name))
        WHEN exclusions = 'None' AND extras != 'None' THEN 
            CONCAT(pizza_name, ' - Extra ',
                  GROUP_CONCAT(DISTINCT pt.topping_name ORDER BY pt.topping_name))
        ELSE 
            CONCAT(pizza_name, ' - Exclude ', 
                  GROUP_CONCAT(DISTINCT CASE 
                      WHEN FIND_IN_SET(pt.topping_id, REPLACE(exclusions, ' ', '')) 
                      THEN pt.topping_name END ORDER BY pt.topping_name),
                  ' - Extra ',
                  GROUP_CONCAT(DISTINCT CASE 
                      WHEN FIND_IN_SET(pt.topping_id, REPLACE(extras, ' ', '')) 
                      THEN pt.topping_name END ORDER BY pt.topping_name))
    END as order_item
FROM (
    SELECT 
        co.order_id,co.customer_id,
        pn.pizza_name,
        co.exclusions,
        co.extras
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
) o
LEFT JOIN pizza_toppings pt ON 
    FIND_IN_SET(pt.topping_id, REPLACE(o.exclusions, ' ', '')) > 0
    OR FIND_IN_SET(pt.topping_id, REPLACE(o.extras, ' ', '')) > 0
GROUP BY order_id, pizza_name, exclusions, extras,customer_id
ORDER BY order_id;





SELECT 
    co.order_id,
    CONCAT(
        pn.pizza_name,
        -- Add exclusions if any
        CASE 
            WHEN co.exclusions != 'None' THEN
                CONCAT(' - Exclude ', 
                    GROUP_CONCAT(
                        DISTINCT CASE 
                            WHEN FIND_IN_SET(pt1.topping_id, REPLACE(co.exclusions, ' ', '')) > 0 
                            THEN pt1.topping_name 
                        END
                        ORDER BY pt1.topping_name
                    )
                )
            ELSE ''
        END,
        -- Add extras if any
        CASE 
            WHEN co.extras != 'None' THEN
                CONCAT(' - Extra ', 
                    GROUP_CONCAT(
                        DISTINCT CASE 
                            WHEN FIND_IN_SET(pt2.topping_id, REPLACE(co.extras, ' ', '')) > 0 
                            THEN pt2.topping_name 
                        END
                        ORDER BY pt2.topping_name
                    )
                )
            ELSE ''
        END
    ) AS order_item
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
LEFT JOIN pizza_toppings pt1 ON pt1.topping_id IN (1,2,3,4,5,6,7,8,9,10,11,12)
LEFT JOIN pizza_toppings pt2 ON pt2.topping_id IN (1,2,3,4,5,6,7,8,9,10,11,12)
GROUP BY co.order_id, co.pizza_id, co.exclusions, co.extras, pn.pizza_name
ORDER BY co.order_id;



-- 5
WITH pizza_details AS (
    -- First get all delivered pizza orders with their default toppings
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt.topping_name,
        COUNT(*) as topping_count
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    JOIN runner_orders ro ON co.order_id = ro.order_id
    CROSS JOIN pizza_toppings pt
    WHERE 
        ro.cancellation = 'None' -- Only delivered pizzas
        AND FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0 -- Match default toppings
        AND NOT FIND_IN_SET(pt.topping_id, REPLACE(co.exclusions, ' ', '')) -- Exclude toppings from exclusions
    GROUP BY 
        co.order_id, 
        pn.pizza_name,
        pt.topping_name
),
extra_toppings AS (
    -- Get any toppings explicitly added as extras
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt.topping_name,
        COUNT(*) as topping_count
    FROM customer_orders co
    JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    JOIN runner_orders ro ON co.order_id = ro.order_id
    CROSS JOIN pizza_toppings pt
    WHERE 
        ro.cancellation = 'None' -- Only delivered pizzas
        AND FIND_IN_SET(pt.topping_id, REPLACE(co.extras, ' ', '')) > 0 -- Match extras
    GROUP BY 
        co.order_id, 
        pn.pizza_name,
        pt.topping_name
),
combined_details AS (
    -- Combine base pizza toppings and extras
    SELECT
        pd.order_id,
        pd.pizza_name,
        pd.topping_name,
        pd.topping_count + COALESCE(et.topping_count, 0) as topping_count
    FROM pizza_details pd
    LEFT JOIN extra_toppings et
        ON pd.order_id = et.order_id
        AND pd.pizza_name = et.pizza_name
        AND pd.topping_name = et.topping_name
    UNION ALL
    -- Add extra toppings that are not part of the original recipe
    SELECT
        et.order_id,
        et.pizza_name,
        et.topping_name,
        et.topping_count
    FROM extra_toppings et
    LEFT JOIN pizza_details pd
        ON et.order_id = pd.order_id
        AND et.pizza_name = pd.pizza_name
        AND et.topping_name = pd.topping_name
    WHERE pd.topping_name IS NULL
)
SELECT 
    CONCAT(
        order_id, '. ',
        pizza_name, ': ',
        GROUP_CONCAT(
            CASE 
                WHEN topping_count > 1 THEN CONCAT(topping_count, 'x', topping_name) -- Show count if > 1
                ELSE topping_name
            END
            ORDER BY topping_name ASC -- Alphabetically ordered
            SEPARATOR ', '
        )
    ) as ordered_ingredients
FROM combined_details
GROUP BY order_id, pizza_name;





-- 6
WITH delivered_pizzas AS (
    -- Filter delivered pizzas and get their base toppings, extras, and exclusions
    SELECT 
        co.order_id,
        pr.toppings AS base_toppings,  
        COALESCE(co.extras, '') AS extras,  -- Get extras from customer_orders table
        COALESCE(co.exclusions, '') AS exclusions,  -- Get exclusions from customer_orders table
        ro.cancellation
    FROM customer_orders co
    JOIN runner_orders ro ON co.order_id = ro.order_id
    JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
    WHERE ro.cancellation = 'None'  -- Only include delivered pizzas
),
expanded_toppings AS (
    -- Expand toppings to handle base, extras, and exclusions
    SELECT 
        dp.order_id,
        pt.topping_name,
        CASE
            WHEN FIND_IN_SET(pt.topping_id, REPLACE(dp.base_toppings, ' ', '')) > 0 
                 AND FIND_IN_SET(pt.topping_id, REPLACE(dp.exclusions, ' ', '')) = 0
            THEN 1
            ELSE 0
        END AS base_topping_count,
        
        CASE
            WHEN FIND_IN_SET(pt.topping_id, REPLACE(dp.extras, ' ', '')) > 0 
            THEN 1
            ELSE 0
        END AS extra_topping_count
    FROM delivered_pizzas dp
    CROSS JOIN pizza_toppings pt
),
final_count AS (
    -- Sum the total count of each topping across all orders
    SELECT 
        et.topping_name,
        SUM(et.base_topping_count + et.extra_topping_count) AS total_times_used
    FROM expanded_toppings et
    GROUP BY et.topping_name
)
-- Get the final result sorted by most frequent ingredient first
SELECT 
    topping_name,
    total_times_used
FROM final_count
ORDER BY total_times_used DESC;


-- D. Pricing and Ratings
-- 1.If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
--  how much money has Pizza Runner made so far if there are no delivery fees?
-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner,
--  how would you design an additional table for this new dataset 
-- - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4. Using your newly generated table - 
-- can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
-- and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?



-- 1.
select c.pizza_id, sum(case 
when pizza_id=1 then 12 
when pizza_id=2 then 10 else 0 end) as 'total prize in dollar'
from customer_orders c
join runner_orders r on 
c.order_id=r.order_id
where cancellation='None'
group by c.pizza_id ;

-- 2.
WITH non_cancelled_orders AS (
   SELECT 
       co.order_id, 
       co.pizza_id, 
       pn.pizza_name,
       co.extras
   FROM customer_orders co
   JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
   JOIN runner_orders ro ON co.order_id = ro.order_id
   WHERE ro.cancellation = 'None'
),
order_pricing AS (
   SELECT 
       pizza_name,
       SUM(
           CASE 
               WHEN pizza_name = 'Meatlovers' THEN 12 
               ELSE 10 
           END + 
           CASE 
               WHEN extras != 'None' THEN 
                   (LENGTH(extras) - LENGTH(REPLACE(extras, ',', '')) + 1) +
                   (CASE WHEN extras LIKE '%4%' THEN 1 ELSE 0 END)
               ELSE 0 
           END
       ) as total_revenue
   FROM non_cancelled_orders
   GROUP BY pizza_name
)

SELECT 
   pizza_name,
   total_revenue
FROM order_pricing;





-- 3.
CREATE INDEX idx_order_id ON runner_orders(order_id);
CREATE INDEX idx_runner_id ON runner_orders(runner_id);

CREATE TABLE ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,       -- Unique rating ID
    order_id INT NOT NULL,                          -- Reference to order ID from runner_orders table
    customer_id INT NOT NULL,                       -- Reference to customer ID from customer_orders table
    runner_id INT NOT NULL,                         -- Reference to runner ID from runner_orders table
    rating INT CHECK (rating >= 1 AND rating <= 5),  -- Rating value between 1 and 5
    rating_date DATE,                               -- The date when the rating is given
    FOREIGN KEY (order_id) REFERENCES runner_orders(order_id),  -- Foreign key constraint for order_id
    FOREIGN KEY (runner_id) REFERENCES runner_orders(runner_id)  -- Foreign key for runner_id
);
-- Insert ratings for only successful deliveries (those without cancellation)
INSERT INTO ratings (order_id, customer_id, runner_id, rating, rating_date)
SELECT r.order_id, o.customer_id, r.runner_id,
       FLOOR(1 + (RAND() * 5)) AS rating, CURDATE()  -- Generate random rating between 1 and 5
FROM runner_orders r
JOIN customer_orders o ON r.order_id = o.order_id  -- Join runner_orders and customer_orders to fetch customer_id
WHERE (r.cancellation IS NULL OR r.cancellation = 'None');



-- 4
WITH CustomerPizzaCounts AS (
    SELECT 
        customer_id, 
        order_id, 
        order_time, 
        COUNT(*) AS Total_pizza 
    FROM customer_orders 
    GROUP BY customer_id, order_id, order_time
),
DeliveryDetails AS (
    SELECT 
        cpc.customer_id,
        cpc.order_id,
        ro.runner_id,
        r.rating,
        cpc.order_time,
        ro.pickup_time,
        TIMESTAMPDIFF(MINUTE, cpc.order_time, ro.pickup_time) AS time_to_pickup,
        ro.duration_in_min AS delivery_duration,
        ROUND(ro.distance_in_km / (ro.duration_in_min / 60), 2) AS average_speed,
        cpc.Total_pizza AS total_pizzas
    FROM 
        CustomerPizzaCounts cpc
    JOIN 
        runner_orders ro ON cpc.order_id = ro.order_id
    LEFT JOIN 
        ratings r ON cpc.order_id = r.order_id 
            
    WHERE 
        ro.cancellation = 'None'
)
SELECT * FROM DeliveryDetails
ORDER BY order_id;




-- 5
WITH PizzaPrices AS (
    SELECT 
        order_id,
        customer_id,
        CASE 
            WHEN pizza_id = 1 THEN 12 
            WHEN pizza_id = 2 THEN 10 
        END AS pizza_price
    FROM customer_orders
),
DeliveryCosts AS (
    SELECT 
        pp.order_id,
        SUM(pizza_price) AS total_sales,
        runner_id,
        distance_in_km,
        distance_in_km * 0.30 AS delivery_cost
    FROM PizzaPrices pp
    JOIN runner_orders ro ON pp.order_id = ro.order_id
    WHERE cancellation = 'None'
    GROUP BY pp.order_id, runner_id, distance_in_km
),
TotalCalculation AS (
    SELECT 
        SUM(total_sales) AS total_revenue,
        SUM(delivery_cost) AS total_delivery_cost,
        SUM(total_sales - delivery_cost) AS net_profit
    FROM DeliveryCosts
)
SELECT * FROM TotalCalculation;

