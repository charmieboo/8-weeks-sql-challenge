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
	from customer_orders);
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
	from runner_orders);
	
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
FROM runner_orders;

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

SELECT *
FROM pizza_recipes;


-- Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT
	count(order_id)
FROM customer_orders1;

-- 2. How many unique customer orders were made?
SELECT
	count(distinct(order_id))
FROM customer_orders1;

--3. How many successful orders were delivered by each runner?
SELECT
	runner_id,
	COUNT(DISTINCT order_id) AS successful_deliveries
FROM runner_orders2
WHERE distance is not null
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT
	pizza_id,
	count(pizza_id)
FROM customer_orders1 co
JOIN runner_orders2 ro
on co.order_id = ro.order_id
where ro.distance is not null
group by co.pizza_id

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	count(co.pizza_id),
	pn.pizza_name,
	co.customer_id
FROM customer_orders1 co
JOIN pizza_names pn
on co.pizza_id = pn.pizza_id
group by customer_id, pn.pizza_name
order by customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT
	customer_id,
	count(order_id) as pizzas_ordered
FROM customer_orders1 co
group by customer_id
order by count(order_id) desc;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	c.customer_id,
	SUM(case when exclusions is not null or extras is not null then 1
	else 0
	end) as with_changes,
	SUM(case when exclusions is null and c.extras is null then 1
	else 0
	end) as no_changes
FROM customer_orders1 c
JOIN runner_orders2 r
on c.order_id = r.order_id
where r.distance is not null
group by c.customer_id
order by c.customer_id;


SELECT *
FROM runner_orders2

select *
from customer_orders1 c

-- 8. How many pizzas were delivered that had both exclusions and extras?
select
	c.customer_id,
	SUM(case when exclusions is not null and extras is not null then 1
	else 0
	end) as both_changes
FROM customer_orders1 c
JOIN runner_orders2 r
on c.order_id = r.order_id
where r.distance is not null
AND exclusions IS NOT NULL 
AND extras IS NOT NULL
group by c.customer_id

-- 9. What was the total volume of pizzas ordered for each hour of the day?
select
	count(order_id) as pizzas_ordered,
	extract(hour from order_time) as hour_day
from customer_orders1 c
group by hour_day
order by hour_day;

-- 10. What was the volume of orders for each day of the week?
select
	count(order_id) as order_volume,
	to_char(order_time, 'day') as day_of_week
from customer_orders1
group by order_time
order by order_time;