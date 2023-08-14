-- Part A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT
  COUNT(*)
FROM customer_orders1;

-- 2. How many unique customer orders were made?
SELECT
  count(DISTINCT order_id)
FROM customer_orders1;

-- 3. How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(DISTINCT order_id) AS successful_orders
FROM runner_orders1
WHERE cancellation IS NULL
GROUP BY 1;

SELECT * FROM runner_orders1;

-- 4. How many of each type of pizza was delivered?
SELECT
  COUNT(r.order_id) as pizza_amt,
  p.pizza_name
FROM runner_orders1 AS r
JOIN customer_orders1 AS c
ON r.order_id = c.order_id
JOIN pizza_runner.pizza_names AS p
ON c.pizza_id = p.pizza_id
WHERE r.cancellation IS NULL
GROUP BY p.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  customer_id,
  SUM(CASE
    WHEN pizza_id = 1 THEN 1 ELSE 0
  END) AS meat_lovers,
  SUM(CASE
    WHEN pizza_id = 2 THEN 2 ELSE 0
  END) AS vegetarian
FROM customer_orders1
GROUP BY 1;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH max_pizza_cte AS (
  SELECT
    COUNT(c.pizza_id) as pizza_count
  FROM customer_orders1 c
  JOIN runner_orders1 r
  ON c.order_id = r.order_id
  WHERE cancellation IS NULL
  GROUP BY c.order_id
)
SELECT MAX(pizza_count) FROM max_pizza_cte;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
  c.customer_id,
  SUM(CASE
    WHEN exclusions is not null or extras is not null THEN 1 ELSE 0
  END) AS changes,
  SUM(CASE WHEN extras IS NULL AND extras IS NULL THEN 1 ELSE 0
  END) AS no_changes
FROM runner_orders1 r
JOIN customer_orders1 c
ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY 1;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
  c.customer_id,
  SUM(CASE
    WHEN exclusions is not null AND extras is not null THEN 1 ELSE 0
  END) AS changes
FROM runner_orders1 r
JOIN customer_orders1 c
ON r.order_id = c.order_id
WHERE cancellation IS NULL
GROUP BY 1;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
  EXTRACT(HOUR FROM order_time) as hour_day,
  COUNT(pizza_id)
FROM customer_orders1 c
GROUP BY 1
ORDER BY 1;

-- 10. What was the volume of orders for each day of the week?
SELECT
  EXTRACT(DAYOFWEEK FROM order_time) AS day_week,
  COUNT(order_id)
FROM customer_orders1
GROUP BY 1
ORDER BY 1;
