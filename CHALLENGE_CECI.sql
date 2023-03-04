
###1. Provide the list of markets in which customer "Atliq Exclusive" operates its
##business in the APAC region.


SELECT DISTINCT market FROM gdb023.dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";


#2. What is the percentage of unique product increase in 2021 vs. 2020? The
#final output contains these fields,
#unique_products_2020
#unique_products_2021
#percentage_chg

WITH products_2020 as (
SELECT count(distinct(product_code))  as unique_p2020 from gdb023.fact_sales_monthly  
WHERE fiscal_year = '2020' ),
products_2021 as (
SELECT count(distinct(product_code)) as unique_p2021 from gdb023.fact_sales_monthly  
WHERE fiscal_year = '2021' )
SELECT 
  unique_p2020, 
  unique_p2021, 
  round(
    (
      unique_p2021 - unique_p2020
    )* 100 / unique_p2020, 
    2
  ) AS percentage_change 

FROM products_2020 CROSS 
  JOIN products_2021;
  
  ##Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains
#2 fields,
#segment
#product_count

SELECT segment, COUNT(distinct(product_code)) as Product_count
FROM gdb023.dim_product
group by segment 
ORDER BY Product_count DESC;

#4. Follow-up: Which segment had the most increase in unique products in
#2021 vs 2020? The final output contains these fields,
#segment
#product_count_2020
#product_count_2021
#difference

  WITH products_2020_ as (
SELECT  p.segment, count(distinct(product_code))  as pcount_2020, fiscal_year from gdb023.dim_product p 
JOIN gdb023.fact_sales_monthly s USING (product_code)  
WHERE fiscal_year = '2020' 
group by segment 
),
products_2021_ as (
SELECT  p.segment, count(distinct(product_code))  as pcount_2021, fiscal_year from gdb023.dim_product p 
JOIN gdb023.fact_sales_monthly s USING (product_code)  
WHERE fiscal_year = '2021' 
group by segment )

SELECT pcount_2020, pcount_2021, pcount_2021 - pcount_2020 AS difference
FROM products_2020_  
  JOIN products_2021_ USING (segment)
  GROUP BY segment
  ORDER BY difference DESC;
  
  # Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields,
#product_code
#product
#manufacturing_cost

SELECT p.product_code , p.product, m.manufacturing_cost
FROM gdb023.dim_product  p
JOIN gdb023.fact_manufacturing_cost m USING (product_code)
WHERE manufacturing_cost = ( SELECT max(manufacturing_cost) from gdb023.fact_manufacturing_cost ) 
OR manufacturing_cost = ( SELECT min(manufacturing_cost) from gdb023.fact_manufacturing_cost   )
ORDER BY manufacturing_cost DESC
;
#6. Generate a report which contains the top 5 customers who received an
#average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#Indian market. The final output contains these fields,
#customer_code
#customer
#average_discount_percentage

SELECT c.customer , c.customer_code, round( avg( i.pre_invoice_discount_pct),4) as avg_discount, i.fiscal_year
  from gdb023.fact_pre_invoice_deductions i
JOIN gdb023.dim_customer c USING (customer_code)
WHERE 
  fiscal_year = 2021 
  AND market = "India"
GROUP BY   i.fiscal_year, c.customer_code, c.customer
ORDER BY avg_discount DESC

LIMIT 5;

#7. Get the complete report of the Gross sales amount for the customer “Atliq
#Exclusive” for each month. This analysis helps to get an idea of low and
#high-performing months and take strategic decisions.
#The final report contains these columns:
#Month
#Year
#Gross sales Amount

SELECT monthname(sm.date) as month_ , sm.fiscal_year , round(SUM(f.gross_price * sm.sold_quantity),2) as gross_sales_amount FROM gdb023.fact_gross_price gp
JOIN gdb023.fact_sales_monthly sm USING (product_code)
JOIN gdb023.dim_customer c USING (customer_code)
JOIN gdb023.fact_gross_price f USING( product_code)
WHERE c.customer = 'Atliq Exclusive'
GROUP BY 
  monthname(sm.date), 
  fiscal_year 
ORDER BY 
  sm.fiscal_year;

#8. In which quarter of 2020, got the maximum total_sold_quantity? Note that fiscal_year
#for Atliq Hardware starts from September(09)
# The final output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity

SELECT 
  CASE WHEN MONTH(date) IN (9, 10, 11) THEN "Q1" WHEN MONTH(date) IN (12, 1, 2) THEN "Q2" WHEN MONTH(date) IN (3, 4, 5) THEN "Q3" ELSE "Q4" END AS quarter, 
  SUM(sold_quantity) AS total_sold_quantity 
FROM 
  gdb023.fact_sales_monthly 
WHERE 
  fiscal_year = 2020 
GROUP BY 
  quarter 
ORDER BY 
  total_sold_quantity DESC;



#9. Which channel helped to bring more gross sales in the fiscal year 2021
#and the percentage of contribution? The final output contains these fields,
#channel
#gross_sales_mln
#percentage


WITH gross_sales_by_channel AS (
SELECT c.channel, round(SUM(sm.sold_quantity * gp.gross_price)/1000000,2)  as ventas FROM 
 gdb023.dim_customer c   
join gdb023.fact_sales_monthly sm  USING(customer_code)
JOIN gdb023.fact_gross_price  gp USING(product_code)
WHERE sm.fiscal_year = 2021
GROUP BY c.channel)
SELECT channel,ventas , round(ventas *100/ SUM(ventas) OVER(),2) AS percentage 
FROM gross_sales_by_channel
ORDER BY percentage DESC;

#10. Get the Top 3 products in each division that have a high
#total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,
#division
#product_code

WITH quant_sold_division AS (
SELECT p.product, SUM(sm.sold_quantity) AS sales, p.division FROM  gdb023.dim_product as p
JOIN gdb023.fact_sales_monthly as sm USING( product_code)
WHERE fiscal_year = 2021
GROUP BY p.division , p.product),

prod_rank_sold_quant AS (
  SELECT 
    *, 
    DENSE_RANK() OVER (
      PARTITION BY division 
      ORDER BY 
        sales DESC
    ) AS rank_order 
  FROM 
  quant_sold_division
) 
SELECT 
  * 
FROM 
  prod_rank_sold_quant 
WHERE 
  rank_order <= 3;












  
  
