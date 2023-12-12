#Adhoc Request 1 
#Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT 
	DISTINCT market 
FROM dim_customer 
WHERE customer='Atliq Exclusive' AND region="APAC";
#Request 2
#What is the percentage of unique product increase in 2021 vs. 2020? 
WITH cte1 AS
(
	SELECT COUNT(DISTINCT product_code) AS unique_products_2020 FROM fact_sales_monthly WHERE fiscal_year=2020
),
cte2 AS
(
	SELECT COUNT(DISTINCT product_code) AS unique_products_2021  FROM fact_sales_monthly WHERE fiscal_year=2021
)
SELECT 
	unique_products_2020,
    unique_products_2021,
    ((unique_products_2021/unique_products_2020)-1)*100 AS pct_change
FROM cte1,cte2;
#Request 3
#Provide a report with all the unique product counts for each segment and sort them in descending order of product counts
SELECT 
	segment,
    COUNT(DISTINCT product_code) AS unique_product_count 
FROM dim_product GROUP BY segment ORDER BY unique_product_count DESC;
#Request 4
#Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
WITH products_2020 AS
(
	SELECT 
		segment,
        COUNT(DISTINCT s.product_code) AS unique_products_2020 
	FROM dim_product p JOIN fact_sales_monthly s 
    ON s.product_code = p.product_code
    WHERE fiscal_year=2020 
    GROUP BY p.segment 
),
products_2021 AS
(
	SELECT 
		segment,
        COUNT(DISTINCT s.product_code) AS unique_products_2021 
	FROM dim_product p JOIN fact_sales_monthly s 
    ON s.product_code = p.product_code
    WHERE fiscal_year=2021 
    GROUP BY p.segment 
)
SELECT 
	p21.segment,
    unique_products_2020,
    unique_products_2021,
    unique_products_2021-unique_products_2020 AS difference
FROM products_2021 p21
JOIN products_2020 p20
on p21.segment = p20.segment
ORDER BY difference DESC
;
#Request 5
#Get the products that have the highest and lowest manufacturing costs.
SELECT 
	m.product_code,
    product,
    manufacturing_cost FROM dim_product p
JOIN fact_manufacturing_cost m 
USING (product_code)
WHERE manufacturing_cost IN 
(
	(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost),
	(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
)
ORDER BY manufacturing_cost DESC
;
#Request 6
#Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
SELECT 
	customer_code,
    customer,
    pre_invoice_discount_pct 
FROM dim_customer  
JOIN fact_pre_invoice_deductions 
USING (customer_code)
WHERE market = "India" 
AND fiscal_year="2021"
AND pre_invoice_discount_pct > 
(
	SELECT 
		AVG(pre_invoice_discount_pct)
	FROM fact_pre_invoice_deductions
)
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5
;
#Request 7
#Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
SELECT 
    MONTHNAME(date) AS month,
    s.fiscal_year,
    ROUND(SUM(gross_price*sold_quantity),2) AS gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g
USING(product_code)
JOIN dim_customer c 
USING(customer_code)
WHERE c.customer="Atliq Exclusive"
GROUP BY month,s.fiscal_year;
#Request 8
#In which quarter of 2020, got the maximum total_sold_quantity? 
SELECT
	get_quarter(month(date)) AS quarter,
    SUM(sold_quantity) AS total_sales_quantity_2020
FROM fact_sales_monthly
WHERE fiscal_year="2020"
GROUP BY quarter
ORDER BY total_sales_quantity_2020 DESC
LIMIT 1;
#Request 9
#Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH channel_sales_pct AS
(	
	SELECT 
		c.channel,
		ROUND(SUM(s.sold_quantity*g.gross_price)/1000000,2) AS gross_sales_mln
	FROM dim_customer c 
	JOIN fact_sales_monthly s
	USING (customer_code)
	JOIN fact_gross_price g
	USING (product_code)
    WHERE s.fiscal_year = "2021"
    GROUP BY c.channel
)
SELECT 
	*,
	FORMAT(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2)  AS pct
FROM channel_sales_pct
ORDER BY pct DESC
;
#Request 10
#Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH product_details AS
(
	SELECT 
		division,
        s.product_code,
		product,
		SUM(sold_quantity) AS total_sold_quantity
	FROM dim_product JOIN
	fact_sales_monthly s
	USING (product_code)
    WHERE fiscal_year="2021"
	GROUP BY division,s.product_code,product
)
,product_rankings AS(
	SELECT 
		*,
    DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM product_details
)

SELECT * FROM product_rankings WHERE rank_order < 4;
