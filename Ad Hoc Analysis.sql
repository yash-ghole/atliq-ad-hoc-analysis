-- Codebasics Resume Project: Provide Insights to Management in Consumer Goods Domain

-- Problem Statement: 
-- AtliQ Hardwares (imaginary company) is one of the leading computer hardware producers in India and has expanded well in other countries too.
-- However, the management noticed that they do not get enough insights to make quick and smart data-informed decisions. 
-- They want to expand their data analytics team by adding several junior data analysts. 
-- Tony Sharma, their data analytics director, wanted to hire someone good at both tech and soft skills. 
-- Hence, he decided to conduct a SQL challenge, which will help him understand both skills.

-- 1. Provide the list of markets in which customer "Atliq  Exclusive" operates its business in the  APAC  region. 
select distinct market, customer, region
from dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?
with cte1 as (
    select COUNT(distinct product_code) as unique_products_2020
    from fact_gross_price
    where fiscal_year = 2020
    ),
    cte2 as (
    select COUNT(distinct product_code) as unique_products_2021
    from fact_gross_price
    where fiscal_year = 2021
    )
select unique_products_2020,
	   unique_products_2021,
       (unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020 as percentage_change
from cte1, cte2;

-- 3. Provide a report with all the unique product counts for each segment and 
-- sort them in descending order of product counts. The final output contains 2 fields,
select segment, count(distinct product_code) as unique_products
from dim_product
group by segment
order by unique_products desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
with cte1 as (
	select 
		p.segment,
		COUNT(distinct p.product_code) as unique_products_2020
    from fact_gross_price gp
    join dim_product p
		on gp.product_code = p.product_code
    where fiscal_year = 2020
    group by p.segment
    ),
    
    cte2 as (
    select 
		 p.segment,
		 COUNT(distinct p.product_code) as unique_products_2021
	from fact_gross_price gp
	join dim_product p
		on gp.product_code = p.product_code
    where fiscal_year = 2021
    group by p.segment
    )

select 
    c1.segment,
    c1.unique_products_2020,
    c2.unique_products_2021,
    (c2.unique_products_2021 - c1.unique_products_2020) as product_increase
from cte1 c1
join cte2 c2
    on c1.segment = c2.segment
order by product_increase desc;

-- 5.  Get the products that have the highest and lowest manufacturing costs. 
with cte1 as (
		select mc.product_code,
			   p.product,
			   mc.manufacturing_cost
		from fact_manufacturing_cost mc
		join dim_product p
			   on mc.product_code = p.product_code
		order by manufacturing_cost desc
        limit 1
),

cte2 as (
		select mc.product_code,
			   p.product,
			   mc.manufacturing_cost
		from fact_manufacturing_cost mc
		join dim_product p
			   on mc.product_code = p.product_code
		order by manufacturing_cost asc
        limit 1
)

select *
from cte1

union

select *
from cte2;

-- 6. Generate a report which contains the top 5 customers who received an 
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian  market.

select pid.customer_code,
	   c.customer,
	   concat(round(avg(pid.pre_invoice_discount_pct) * 100, 2), '%') as avg_discount_percentage
from fact_pre_invoice_deductions pid
join dim_customer c
	on pid.customer_code = c.customer_code
where pid.fiscal_year = 2021 and c.market = 'India'
group by pid.customer_code, c.customer
order by avg(pid.pre_invoice_discount_pct) desc
limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer  “Atliq 
-- Exclusive” for each month. This analysis helps to get an idea of low and 
-- high-performing months and take strategic decisions. 
select year(date) as `year`,
	   month(date) as `month`,
       customer,
       round(sum(sold_quantity * gross_price), 2) as gross_sales_amount
from fact_sales_monthly fcm
join fact_gross_price fgp
	on fcm.product_code = fgp.product_code 
    and fcm.fiscal_year = fgp.fiscal_year
join dim_customer c
	on fcm.customer_code = c.customer_code
where c.customer = 'Atliq Exclusive'
group by `year`, `month`, customer;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
select concat('Q', quarter(date_add(date, interval 4 month))) as fiscal_quarter,
	   sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by fiscal_quarter
order by total_sold_quantity desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?
with cte1 as(
		select c.channel,
			Round(sum(fgp.gross_price * fsm.sold_quantity) / 1000000, 2) as gross_sales_mln
		from fact_gross_price fgp
		join fact_sales_monthly fsm 
			on fgp.fiscal_year = fsm.fiscal_year 
			and fgp.product_code = fsm.product_code
		join dim_customer c 
			on fsm.customer_code = c.customer_code
		where fgp.fiscal_year = 2021
		group by c.channel
)

select channel, 
	   gross_sales_mln,
	   Round(gross_sales_mln/sum(gross_sales_mln) over() *100,2) as percenatge 
from cte1 
group by channel
order by gross_sales_mln desc;

-- 10. Get the Top 3 products in each division that have a high 
-- total_sold_quantity in the fiscal_year 2021?
with cte1 as(
		select p.division,
        p.product_code,
        p.product,
		sum(fsm.sold_quantity) as total_sold_quantity 
        from dim_product p 
        join fact_sales_monthly fsm
			on p.product_code = fsm.product_code 
		where fsm.fiscal_year = 2021
		group by p.division,p.product_code,p.product
        ),
        
	cte2 as (
		select division,
        product_code,
        product,
        total_sold_quantity,
		Dense_Rank() over (partition by division order by total_sold_quantity desc) as `rank`
		from cte1
        )
        
select division,
	   product_code,
	   product,
	   total_sold_quantity,
	   `rank`
from cte2
where `rank` <= 3;
