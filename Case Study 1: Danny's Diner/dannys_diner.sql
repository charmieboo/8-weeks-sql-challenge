-- 1. What is the total amount each customer spent at the restaurant?
select ds.customer_id, sum(dmenu.price) from dannys_diner.sales as ds
inner join dannys_diner.menu as dmenu on ds.product_id = dmenu.product_id
group by ds.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as days_visited from dannys_diner.sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select distinct a.customer_id, a.product_name from
(select ds.customer_id, ds.order_date, dm.product_name, rank() over (partition by ds.customer_id order by ds.order_date) as r
from dannys_diner.sales as ds
inner join dannys_diner.menu as dm on ds.product_id = dm.product_id
order by ds.customer_id) as a
where r=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select * from dannys_diner.menu;

select * from dannys_diner.sales;

select count(ds.product_id) as most_purchased, dm.product_name from dannys_diner.sales as ds
inner join dannys_diner.menu as dm on ds.product_id = dm.product_id
group by ds.product_id, dm.product_name
order by most_purchased desc;

-- 5. Which item was the most popular for each customer?
with popular_item as
(
select ds.customer_id, dm.product_name, count(ds.product_id) as order_count, rank() over (partition by ds.customer_id order by count(ds.product_id) DESC) as r
from dannys_diner.menu as dm
inner join dannys_diner.sales as ds on dm.product_id = ds.product_id
group by ds.customer_id, ds.product_id, dm.product_name
)

select customer_id, product_name, order_count from popular_item
where r = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_item AS (
select ds.customer_id, ds.order_date, ds.product_id, dm.join_date,
rank() over (partition by ds.customer_id order by ds.order_date) as order_date_rank
from dannys_diner.sales as ds
join dannys_diner.members as dm on ds.customer_id = dm.customer_id
where ds.order_date >= dm.join_date)

select customer_id, order_date, product_id from first_item
where order_date_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH last_item AS
(select ds.customer_id, ds.order_date, ds.product_id, rank() over (partition by ds.customer_id order by ds.order_date) as order_rank_date
from dannys_diner.sales as ds
join dannys_diner.members as dm on ds.customer_id = dm.customer_id
where dm.join_date > ds.order_date)

select * from last_item
where order_rank_date = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
select ds.customer_id, count(distinct(ds.product_id)) as total_items, sum(dm.price) as amount_spent
from dannys_diner.sales as ds
join dannys_diner.menu as dm on ds.product_id = dm.product_id
join dannys_diner.members as de on de.customer_id = ds.customer_id
where ds.order_date < de.join_date
group by ds.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH food_points AS (
select *,
case when product_id = 1 then price*20
	else price*10
end as points
from dannys_diner.menu as dm )

select ds.customer_id, sum(f.points) from food_points as f
join dannys_diner.sales as ds on f.product_id = ds.product_id
group by ds.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
select * from dannys_diner.menu as dm;
select * from dannys_diner.sales as ds;
select * from dannys_diner.members as de;

WITH dates AS
(select *,
	date '2021-01-01' + 30 as jan_end,
 	join_date + 7 AS join_week
from dannys_diner.members as de)

select ds.customer_id,
	sum(CASE WHEN ds.product_id = 1 then dm.price*20
	   WHEN ds.order_date BETWEEN join_date AND join_week then dm.price*20
	   ELSE dm.price*10
	   END) as points
from dannys_diner.menu as dm
join dannys_diner.sales as ds on dm.product_id = ds.product_id
join dates as d on d.customer_id = ds.customer_id
where ds.order_date < d.jan_end
group by ds.customer_id;

-- 11: Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
select ds.customer_id, ds.order_date, dm.product_name, dm.price,
	(case when ds.customer_id in ('A', 'B') and ds.order_date < de.join_date then 'N'
		when ds.customer_id = 'C' then 'N'
		else 'Y' end) as member
from dannys_diner.sales as ds
inner join dannys_diner.menu as dm on ds.product_id = dm.product_id
full join dannys_diner.members as de on ds.customer_id = de.customer_id
order by ds.customer_id, ds.order_date;

-- 12. Danny also requires further information about the ranking of customer products, but he purposely
-- does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
with new_table as
(select ds.customer_id, ds.order_date, dm.product_name, dm.price,
	(case when ds.customer_id in ('A', 'B') and ds.order_date < de.join_date then 'N'
		when ds.customer_id = 'C' then 'N'
		else 'Y' end)
from dannys_diner.sales as ds
inner join dannys_diner.menu as dm on ds.product_id = dm.product_id
full join dannys_diner.members as de on ds.customer_id = de.customer_id
order by ds.customer_id, ds.order_date)

select customer_id, order_date, product_name, price, 
	(case when customer_id in ('A','B') and order_date >= new_table.join_date
	then rank() over (partition by customer_id order by order_date)
	end) as ranking
from new_table