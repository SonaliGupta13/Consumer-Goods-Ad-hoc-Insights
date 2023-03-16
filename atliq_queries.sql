/* Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region. */

SELECT DISTINCT market 
FROM dim_customer
WHERE customer='Atliq Exclusive' AND region ='APAC';

/* What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

WITH unique_product AS
 (
  SELECT 
    COUNT(DISTINCT CASE WHEN fiscal_year ='2020' THEN product_code ELSE NULL END)
    AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year ='2021' THEN product_code ELSE NULL END) 
    AS unique_products_2021
    FROM fact_sales_monthly
  ) 
   SELECT unique_products_2020, unique_products_2021,
   ROUND((
   (unique_products_2021-unique_products_2020)/unique_products_2020) * 100,2)
   AS percentage_chg
  FROM unique_product ;
    
/* Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */

SELECT segment,COUNT(*) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH product_count AS
   (
    SELECT segment,
	COUNT(DISTINCT CASE WHEN fiscal_year='2020' THEN d.product_code END) 
    AS product_count_2020,
	COUNT(DISTINCT CASE WHEN fiscal_year='2021' THEN d.product_code END) 
    AS product_count_2021
      FROM dim_product AS d
	  JOIN fact_sales_monthly AS f
	  ON d.product_code=f.product_code
      GROUP BY segment
    )  
     SELECT segment,product_count_2020,product_count_2021,
     (product_count_2021-product_count_2020) AS difference
     FROM product_count
     ORDER BY difference DESC;

/* Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */

SELECT f.product_code,d.product,
  ROUND((f.manufacturing_cost),2) AS manufacturing_cost
  FROM dim_product AS d JOIN  fact_manufacturing_cost AS f
  ON d.product_code=f.product_code
  WHERE manufacturing_cost in (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
  OR manufacturing_cost in (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);
  
/* Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

SELECT d.customer_code, customer,
   ROUND(AVG(pre_invoice_discount_pct)*100,2)
   AS average_discount_percentage
FROM dim_customer AS d
   JOIN fact_pre_invoice_deductions AS f
   ON d.customer_code=f.customer_code
   WHERE fiscal_year='2021'
   AND market='India'
GROUP BY d.customer_code,customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

SELECT MONTHNAME(date) AS Month,
	  YEAR(date) AS Year,
      ROUND(sum(gross_price * sold_quantity),2) AS GrossSalesAmount 
FROM fact_sales_monthly AS sales
   JOIN fact_gross_price AS gross
      ON sales.product_code=gross.product_code
   JOIN dim_customer AS cust
      ON sales.customer_code=cust.customer_code
WHERE customer = 'Atliq Exclusive'
GROUP BY Month,Year
ORDER BY Year ;

/* In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */

SELECT 
  CASE 
  WHEN month(date) IN (9,10,11) THEN 'Q1' 
  WHEN month(date) IN (12,1,2) THEN 'Q2'
  WHEN month(date) IN (3,4,5) THEN 'Q3' 
  ELSE 'Q4'
  END AS Quarter,
  SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year='2020'
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

/* Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

WITH gross_sales AS 
(
  SELECT cust.channel,
   ROUND((sum(gross_price * sold_quantity)/1000000),2) AS gross_sales_mln 
  FROM dim_customer AS cust 
   JOIN fact_sales_monthly AS sale
    ON cust.customer_code=sale.customer_code
   JOIN fact_gross_price AS gross
    ON sale.product_code=gross.product_code
  WHERE sale.fiscal_year= 2021
  GROUP BY cust.channel
 )
 SELECT channel,
 gross_sales_mln,
 CONCAT(ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2),'%') AS percentage
 FROM gross_sales
 ORDER BY percentage DESC;
 
/* Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code */

WITH sold_quantity_by_division AS
(
  SELECT division, sale.product_code, product,
  SUM(sold_quantity) AS total_sold_quantity,
    DENSE_RANK() OVER(PARTITION BY division 
    ORDER BY SUM(sold_quantity) DESC) AS rank_order
  FROM dim_product AS prod
   JOIN fact_sales_monthly AS sale
    ON prod.product_code=sale.product_code
  WHERE fiscal_year=2021
  GROUP BY division,sale.product_code,product
 )
  SELECT * FROM sold_quantity_by_division
  WHERE rank_order < 4;





