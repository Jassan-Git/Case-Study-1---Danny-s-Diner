# [Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)
### Project Summary
Danny's Diner is a Japanese-themed restaurant that began operations in early 2021. The owner, Danny, is passionate about Japanese cuisine and offers three key menu items: sushi, curry, and ramen. While the restaurant has gained some traction, Danny is looking to leverage data analytics to enhance customer satisfaction, improve operational efficiency, and make informed decisions about the restaurant's growth.

### Objective
As a data analyst, our role is to dive deep into the data collected by Danny’s Diner and provide actionable insights that can:

1. Identify customer behavior and visiting patterns: Understand how frequently customers visit the diner.
2. Analyze spending habits: Determine how much customers spend and identify the most profitable customers.
3. Determine menu preferences: Highlight the most popular menu items based on sales data.
4. Evaluate the loyalty program: Assess the performance of existing loyalty efforts to decide on potential program expansion.
   
These insights will not only help Danny optimize the dining experience but also guide him in scaling the business effectively.

### Key Datasets
Danny has provided the following datasets for analysis:

1. Sales Data: Captures transactions, including which customers visited and what they ordered.
2. Menu Data: Contains details about menu items, including prices.
3. Member Data: Includes information about customers and their membership status.

These datasets form the foundation for answering critical business questions.

### Scope of Analysis
This case study focuses on answering the following questions to provide actionable insights for Danny's Diner:

1. Customer Spending Patterns
    - What is the total amount each customer spent at the restaurant?
2. Visitation Behavior
    - How many days has each customer visited the restaurant?
3. Menu Item Preferences
    - What was the first item from the menu purchased by each customer?
    - What is the most purchased item on the menu, and how many times was it purchased by all customers?
    - Which item was the most popular for each customer?
4. Membership Insights
    - Which item was purchased first by the customer after they became a member?
    - Which item was purchased just before the customer became a member?
    - What is the total number of items and amount spent by each customer before they became a member?
5. Points and Rewards
    - If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?
    - In the first week after a customer joins the program (including their join date), they earn 2x points on all items. How many points do customer A and customer B have at the end of January?

### SQL Queries
1. What is the total amount each customer spent at the restaurant?
```sql
select s.customer_id , sum(m.price) total_amount
from dannys_diner.sales s
join dannys_diner.menu m
on s.product_id = m.product_id
group by 1;
```
2. How many days has each customer visited the restaurant?
```sql
select customer_id, count(distinct order_date) no_of_days
from dannys_diner.sales
group by 1;
```
3. What was the first item from the menu purchased by each customer?
```sql
select customer_id, product_name
from (
select customer_id , product_id , row_number() over(partition by customer_id order by order_date) numb
from dannys_diner.sales) sub
join dannys_diner.menu m 
on sub.product_id = m.product_id
where numb =1;
```
4. What is the most purchased item on the menu, and how many times was it purchased by all customers?
```sql
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
```
5. Which item was the most popular for each customer?
```sql
select customer_id, product_name
from (select customer_id, product_id, dense_rank() over(partition by customer_id order by count(*)  desc) ranking
from dannys_diner.sales
group by customer_id, product_id) sub
join menu m
on m.product_id = sub.product_id
where ranking = 1;
```
6. Which item was purchased first by the customer after they became a member?
```sql
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
```
7. Which item was purchased just before the customer became a member?
```sql
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
```
8. What is the total items and amount spent for each member before they became a member?
```sql
select s.customer_id, count( p.product_name) num_of_prod, sum(p.price) sum_of_price
from sales s
join members m 
on s.order_date < m.join_date and s.customer_id = m.customer_id
join menu p 
on s.product_id = p.product_id
group by 1;
```
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
select customer_id , sum(if(product_name != 'sushi', price*10, price*20)) points
from sales s
join menu m 
on s.product_id = m.product_id
group by customer_id
;
```
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
select s.customer_id , sum(if((s.order_date between join_date and date_add(join_date, interval 7 Day)) or m.product_name = 'sushi', price*20, price*10)) points
from sales s
join menu m 
on s.product_id = m.product_id
join members mem
on mem.customer_id = s.customer_id
where month(order_date) = 1
group by customer_id
;
```







