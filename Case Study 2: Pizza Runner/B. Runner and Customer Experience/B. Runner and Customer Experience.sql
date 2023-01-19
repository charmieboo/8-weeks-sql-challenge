SELECT *
 FROM runners;
 
 SELECT *
FROM customer_orders;

SELECT *
FROM runner_orders;

SELECT *
FROM pizza_names;

SELECT *
FROM pizza_recipes;

SELECT *
FROM pizza_toppings;

-- CLEANING THE DATA
-- for customer_orders table
CREATE TEMP TABLE customer_orders1 AS
	(select
		order_id,
	 	customer_id,
	 	pizza_id,
		case
			when exclusions = '' OR exclusions = 'null' THEN NULL
			else exclusions
			end as exclusions,
		case
			when extras = '' OR extras = 'null' THEN NULL
			else extras
			end as extras,
		order_time
	from pizza_runner.customer_orders);
select * from customer_orders1;

-- for runner_orders table
CREATE TEMP TABLE runner_orders1 AS
	(select
		order_id,
		runner_id,
		CASE
			WHEN pickup_time = 'null' then NULL
			else pickup_time
			end as pickup_time,
		CASE
			WHEN distance = 'null' then NULL
	 		WHEN distance = '%km' then TRIM('km' from distance)
			else distance
			end as distance,
		CASE
			WHEN duration = 'null' then NULL
			WHEN duration = '%minutes' then TRIM('minutes' from duration)
	 		WHEN duration = '%mins' then TRIM('mins' from duration)
	 		WHEN duration = '%minute' then TRIM('minute' from duration)
			end as duration,
		CASE
			WHEN cancellation = 'null' OR cancellation = '' then NULL
			else cancellation
			end as cancellation
	from pizza_runner.runner_orders);
	
select * from runner_orders2;

CREATE TEMP TABLE runner_orders2 AS 
SELECT 
order_id, runner_id, 
CASE 
  WHEN pickup_time LIKE 'null' THEN NULL 
  ELSE pickup_time 
  END AS pickup_time, 
CASE 
  WHEN distance LIKE 'null' THEN NULL
  WHEN distance LIKE '%km' THEN TRIM ('km' from distance)
  ELSE distance 
  END AS distance, 
CASE   
  WHEN duration LIKE 'null' THEN NULL
	WHEN duration LIKE '%minutes' THEN TRIM ('minutes'from  duration)
	WHEN duration LIKE '%minute' THEN TRIM ('minute'from  duration)
	WHEN duration LIKE '%mins' THEN TRIM ('mins' from duration)
	ELSE duration
	END AS duration, 
CASE 
	WHEN cancellation = '' OR cancellation LIKE 'null' THEN NULL
	ELSE cancellation
	END AS cancellation
FROM pizza_runner.runner_orders;

ALTER TABLE runner_orders2
ALTER COLUMN distance TYPE FLOAT USING nullif(distance, '')::float,
ALTER COLUMN duration TYPE INT USING nullif(duration, '')::int;

ALTER TABLE runner_orders2
ALTER COLUMN pickup_time TYPE TIMESTAMP USING nullif (pickup_time, '')::timestamp;

SELECT *
FROM runner_orders2;

-- for pizza_recipes table
-- give each csv value in table a separate row
SELECT 
  pizza_id,
  UNNEST(STRING_TO_ARRAY(toppings, ',')) AS pizza_toppings
FROM pizza_runner.pizza_recipes;
--then separate each value with a comma
SELECT 
  pizza_id,
  STRING_TO_ARRAY(toppings, ',') AS pizza_toppings
FROM pizza_runner.pizza_recipes;


-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select
	extract(week from registration_date) as Wk,
	count(runner_id) as runner_amt
from pizza_runner.runners
group by 1;

select * from pizza_runner.runners;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with cte as(
select
	DATE_PART('minute', (r.pickup_time::timestamp - c.order_time::timestamp))::INTEGER as mins_taken
from runner_orders2 r
join customer_orders1 c
on r.order_id = c.order_id
where r.pickup_time is not null
)
select
	round(avg(mins_taken), 2)
from cte;

SELECT * FROM runner_orders2;
select * from customer_orders1;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT
	count(c.order_id) as pizza_amt,
	date_part('minute', AGE(r.pickup_time::TIMESTAMP, c.order_time))::INTEGER as pickup_minutes
FROM runner_orders2 AS r
  INNER JOIN customer_orders1 AS c
    ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
group by c.order_id, pickup_minutes;

-- 4. What was the average distance travelled for each customer?
select
	c.customer_id,
	round(avg(r.distance)::INTEGER, 2)
from runner_orders2 as r
JOIN customer_orders1 c
ON r.order_id = c.order_id
where r.cancellation is null
group by c.customer_id

-- 5. What was the difference between the longest and shortest delivery times for all orders?
select
	MAX(duration) - MIN(duration) as difference
from runner_orders2 r

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- speed is distance/duration
select
	runner_id,
	order_id,
	round(avg(distance / duration*60)::INTEGER,2) as avg_speed
from runner_orders2
where cancellation is null
group by runner_id, order_id

-- 8. What is the successful delivery percentage for each runner?
select
	runner_id,
	count(pickup_time) as delivered_orders,
	count(*) as total_orders,
	(100 * count(pickup_time)/count(*)) as delivery_percentage
from runner_orders2
group by runner_id
order by runner_id