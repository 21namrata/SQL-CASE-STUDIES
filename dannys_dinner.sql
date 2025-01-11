CREATE DATABASE dannys_diner;
USE dannys_diner;

-- Create the sales table
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

-- Insert data into sales table
INSERT INTO sales (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

-- Create the menu table
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(50),
  price INTEGER
);

-- Insert data into menu table
INSERT INTO menu (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);

-- Create the members table
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- Insert data into members table
INSERT INTO members (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? 

-- 1.
select s.customer_id,sum(price) as 'total amount' 
from sales s join menu m on
s.product_id=m.product_id
group by s.customer_id;

-- 2.
select customer_id,count(*) as 'Days Visited'
from sales 
group by customer_id;

-- 3.
with rankedsales as(
select s.customer_id, m.product_name, 
row_number() over(partition by s.customer_id order by s.order_date,s.product_id) as 'rankedrow'
from sales s join menu m on s.product_id=m.product_id)
select customer_id, product_name from rankedsales 
where rankedrow =1 ;

-- 4.
select m.product_name ,count(*) as 'purchased_number'
from sales s
join menu m on s.product_id=m.product_id
group by product_name
order by purchased_number desc;

-- 5.
with cte as (
select s.customer_id,m.product_name, count(*) as'mostpopular',
rank() over (partition by customer_id order by count(*) desc) as 'ranked'
from sales s join menu m on 
s.product_id=m.product_id
group by s.customer_id,m.product_name)
select customer_id, product_name from cte 
where ranked=1;

-- 6.
with filteredsales as(
select s.customer_id, m.product_name, s.order_date,me.join_date,
rank() over(partition by customer_id order by order_date asc) as ranked
from sales s 
join menu m on s.product_id=m.product_id 
join members me on s.customer_id=me.customer_id
where s.order_date >= me.join_date
order by customer_id)
select customer_id,product_name,order_date from filteredsales
where ranked= 1;

-- 7.
with cte as (select s.customer_id, m.product_name, s.order_date,me.join_date,
rank() over(partition by customer_id order by order_date desc) as ranked
from sales s 
join menu m on s.product_id=m.product_id 
join members me on s.customer_id=me.customer_id
where s.order_date < me.join_date
order by customer_id)
select customer_id, product_name,order_date,join_date from cte 
where ranked=1;

-- 8.
with cte as (
select s.customer_id, m.product_name, s.order_date,me.join_date,m.price
from sales s 
join menu m on s.product_id=m.product_id 
join members me on s.customer_id=me.customer_id
where s.order_date < me.join_date
order by customer_id)
select customer_id, count(*) as TotalItems,sum(price) as TotalPrice from cte
group by customer_id
order by customer_id ;

-- 9.
select s.customer_id,
sum(case when m.product_name="sushi" then m.price*10*2 else m.price*10 end) as total_points 
from sales s join menu m 
on s.product_id=m.product_id
group by s.customer_id;

-- 10.
select s.customer_id, 
sum(case when s.order_date between me.join_date and date_add(me.join_date, interval 6 day) then m.price*10*2
when m.product_name="sushi" then m.price*10*2 
else m.price*10 end) as total_points 
from sales s 
join menu m on s.product_id=m.product_id
join members me on s.customer_id = me.customer_id
where s.order_date <='2021-01-31'
group by s.customer_id
order by customer_id;



-- explanation of 10 in detail
select s.customer_id, s.order_date, me.join_date,m.product_name,
sum(case when s.order_date between me.join_date and date_add(me.join_date, interval 6 day) then m.price*10*2
when m.product_name="sushi" then m.price*10*2 
else m.price*10 end) as total_points 
from sales s 
join menu m on s.product_id=m.product_id
join members me on s.customer_id = me.customer_id
where s.order_date <='2021-01-31'
group by s.customer_id,s.order_date,me.join_date,m.product_name
order by customer_id;

  