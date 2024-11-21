-- What is the total amount each customer spent at the restaurant?
select s.customer_id , sum(m.price) total_amount
from dannys_diner.sales s
join dannys_diner.menu m
on s.product_id = m.product_id
group by 1;

-- How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) no_of_days
from dannys_diner.sales
group by 1;

-- What was the first item from the menu purchased by each customer?
select customer_id, product_name
from (
select customer_id , product_id , row_number() over(partition by customer_id order by order_date) numb
from dannys_diner.sales) sub
join dannys_diner.menu m 
on sub.product_id = m.product_id
where numb =1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, customer_id, count(*) cnt
from (
select product_id, count(*) 
from dannys_diner.sales
group by 1 
order by 2 desc
limit 1) sub
join dannys_diner.menu m
on sub.product_id = m.product_id
join dannys_diner.sales s
on s.product_id = sub.product_id
group by 1,2 ;

--  Which item was the most popular for each customer?
select customer_id, product_name
from (select customer_id, product_id, dense_rank() over(partition by customer_id order by count(*)  desc) ranking
from dannys_diner.sales
group by customer_id, product_id) sub
join menu m
on m.product_id = sub.product_id
where ranking = 1;

-- Which item was purchased first by the customer after they became a member?
select sub.customer_id, sub.order_date, sub.join_date , p.product_name
from 
(	select s.customer_id, s.order_date, s.product_id, m.customer_id as m_cust_id, m.join_date , 
		   dense_rank() over(partition by s.customer_id order by order_date) as ranking
	from sales s
	join members m 
	on s.order_date > m.join_date and s.customer_id = m.customer_id
) sub
join menu p
on sub.product_id = p.product_id
where ranking = 1
;

-- Which item was purchased just before the customer became a member?
select sub.customer_id, sub.order_date, sub.join_date , p.product_name
from 
(	select s.customer_id, s.order_date, s.product_id, m.customer_id as m_cust_id, m.join_date , 
		   dense_rank() over(partition by s.customer_id order by order_date desc) as ranking
	from sales s
	join members m 
	on s.order_date < m.join_date and s.customer_id = m.customer_id
) sub
join menu p
on sub.product_id = p.product_id
where ranking = 1
;

-- What is the total items and amount spent for each member before they became a member?
select s.customer_id, count( p.product_name) num_of_prod, sum(p.price) sum_of_price
from sales s
join members m 
on s.order_date < m.join_date and s.customer_id = m.customer_id
join menu p 
on s.product_id = p.product_id
group by 1;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id , sum(if(product_name != 'sushi', price*10, price*20)) points
from sales s
join menu m 
on s.product_id = m.product_id
group by customer_id
;

-- In the first week after a customer joins the program (including their join date) they earn 
-- 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select s.customer_id , sum(if((s.order_date between join_date and date_add(join_date, interval 7 Day)) or m.product_name = 'sushi', price*20, price*10)) points
from sales s
join menu m 
on s.product_id = m.product_id
join members mem
on mem.customer_id = s.customer_id
where month(order_date) = 1
group by customer_id
;

-- The following questions are related creating basic data tables that Danny and his team can use 
-- to quickly derive insights without needing to join the underlying tables using SQL.
select * , if(`member` = 'Y'  ,rank() over(partition by s.customer_id, `member` order by order_date), null) ranking
from 
(select s.customer_id , s.order_date, m.product_name, m.price, if(order_date >= join_date, 'Y','N') as `member`
from sales s
join menu m 
on s.product_id = m.product_id
left join members mem
on mem.customer_id = s.customer_id
order by s.customer_id,order_date, product_name) sub
;