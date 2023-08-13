SELECT * FROM dannys_diner.members as members;
SELECT * FROM dannys_diner.menu as menu;
SELECT * FROM dannys_diner.sales as sales;

-- questions
-- 1. What is the total amount each customer spent at the restaurant?
SELECT
  sales.customer_id,
  sum(menu.price) AS total_amount
FROM dannys_diner.menu AS menu JOIN dannys_diner.sales AS sales
ON menu.product_id = sales.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
  customer_id,
  COUNT(DISTINCT(order_date)) as days_visited
FROM dannys_diner.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    RANK() OVER (
      PARTITION BY sales.customer_id ORDER BY sales.order_date 
    ) AS ranking
  FROM dannys_diner.sales AS sales
  JOIN dannys_diner.menu AS menu ON
  sales.product_id = menu.product_id
)
SELECT
  *
FROM ordered_sales
WHERE ranking = 1
ORDER BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
  menu.product_name,
  COUNT(sales.product_id) AS item_quantity
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY number_purchase DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH customer_cte AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(sales.*) AS item_quantity,
    RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY COUNT(sales.*)
      ) AS item_rank
  FROM dannys_diner.sales AS sales INNER JOIN dannys_diner.menu AS menu
  ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
)
SELECT
  customer_id,
  product_name
  item_quantity,
FROM customer_cte
WHERE item_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member and what date was it? (including the date they joined)
WITH first_purchase_cte AS (
  SELECT
    members.customer_id,
    sales.order_date,
    menu.product_name,
    RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS ranking
  FROM dannys_diner.members as members
  JOIN dannys_diner.sales AS sales ON members.customer_id = sales.customer_id
  JOIN dannys_diner.menu AS menu ON sales.product_id = menu.product_id
  WHERE sales.order_date >= members.join_date
)
SELECT
  customer_id,
  product_name,
  order_date
FROM first_purchase_cte
WHERE ranking = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH before_member_cte AS (
  SELECT
    members.customer_id,
    members.join_date,
    sales.product_id,
    RANK() OVER (
      PARTITION BY sales.customer_id ORDER BY sales.order_date ASC
    ) AS ranking
  FROM dannys_diner.members as members
  JOIN dannys_diner.sales AS sales
  ON members.customer_id = sales.customer_id
  WHERE sales.order_date < members.join_date
)
SELECT * FROM before_member_cte
WHERE ranking > 1;

-- 8. What are the total items and amount spent for each member before they became a member?
SELECT
  sales.customer_id,
  COUNT(DISTINCT sales.product_id) AS total_items,
  SUM(menu.price) AS amt_spent
FROM dannys_diner.members AS members
INNER JOIN dannys_diner.sales AS sales
ON members.customer_id = sales.customer_id
INNER JOIN dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
  sales.customer_id,
  SUM(CASE WHEN menu.product_name = 'sushi' THEN menu.price * 20
    else menu.price * 10
    END) AS points
FROM dannys_diner.sales AS sales
JOIN dannys_diner.menu AS menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS (
  select
    *,
    date '2021-01-01' +30 as jan_end,
    join_date + 7 AS join_week
  from dannys_diner.members as members
)

SELECT
  sales.customer_id,
  SUM(CASE
    WHEN product_name = 'sushi' THEN menu.price*20
    WHEN sales.order_date BETWEEN members.join_date AND join_week THEN menu.price*20
    ELSE menu.price*10
  END)
FROM dannys_diner.menu AS menu
JOIN dannys_diner.sales AS sales
ON menu.product_id = sales.product_id
JOIN dannys_diner.members AS members
ON sales.customer_id = members.customer_id
JOIN dates AS d
ON members.customer_id = d.customer_id
WHERE order_date < jan_end
GROUP BY sales.customer_id;

-- 11. Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL Recreate the following table output using the available data.
SELECT
  sales.customer_id,
  sales.order_date,
  menu.product_name,
  menu.price,
  CASE
    WHEN sales.order_date > members.join_date THEN 'N' ELSE 'Y'
  END AS member_status
FROM dannys_diner.menu AS menu
JOIN dannys_diner.sales AS sales
ON menu.product_id = sales.product_id
JOIN dannys_diner.members AS members
ON sales.customer_id = members.customer_id;
