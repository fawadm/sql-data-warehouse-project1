 /*
 ========================================================================================
 DDL Script: Create Gold Views
 ========================================================================================
 Script Purpose:
     This script creates views for the gold layer in the data warehouse.
	 The Gold Layer represnts the final dimension and fact tables (Star Schema).

	 Each view performs transformations and combines data from silver layer
	 to produce a clean, enriched, and business-ready dataset.
	 
Usage:
    - These views can be queried directly for analytics and reporting.
==========================================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
  ROW_NUMBER() OVER(
    ORDER BY 
      cst_id
  ) AS Customer_key, 
  ci.cst_id AS Customer_id, 
  ci.cst_key AS Customer_number, 
  ci.cst_firstname AS firs_name, 
  ci.cst_lastname AS last_name, 
  la.cntry AS country, 
  ci.cst_marital_status AS marital_status, 
  CASE WHEN ci.cst_gndr ! = 'n/a' THEN ci.cst_gndr ELSE COALESCE(ca.gen, 'n/a') END AS gender, 
  cst_create_date AS create_date, 
  ca.bdate AS birthdate 
FROM 
  silver.crm_cust_info ci 
  LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid 
  LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid 
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
  
  CREATE VIEW gold.dim_products AS 
SELECT 
  ROW_NUMBER() OVER(
    ORDER BY 
      prd_start_dt, 
      prd_key
  ) AS product_key, 
  prd_id AS Product_id, 
  prd_key AS Product_number, 
  prd_nm AS Product_name, 
  cat_id AS category_id, 
  pc.cat AS Category, 
  pc.subcat AS subcategory, 
  pc.maintenance, 
  prd_cost AS cost, 
  prd_line AS product_line, 
  prd_start_dt AS start_date 
FROM 
  silver.crm_prd_info pn 
  LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id 
WHERE 
  prd_end_dt IS NULL 
GO
  
  

---  =====================================================================================
---  Create fact:  gold.fact_sales
---  =====================================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
   DROP VIEW gold.fact_sales;
GO
  CREATE VIEW gold.fact_sales AS 
SELECT 
  sls_ord_num AS order_number, 
  pr.product_key, 
  cu.Customer_key, 
  sls_order_dt AS order_date, 
  sls_ship_dt AS shipping_date, 
  sls_due_dt AS due_date, 
  sls_sales AS sales_amount, 
  sls_quantity AS quantity, 
  sls_price AS price 
FROM 
  silver.crm_sales_details sd 
  LEFT JOIN gold.dim_products pr ON SD.sls_prd_key = pr.Product_number 
  LEFT JOIN gold.dim_customers cu ON sd.sls_cust_id = cu.Customer_id
GO
