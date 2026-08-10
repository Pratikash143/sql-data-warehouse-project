/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- 1. Checks for NULL or Duplicates in Primary Key
-- Expectation: No Results
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- 2. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- 3. Check for Data abbreviations or consistency of values in low cardinality columns
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT DISTINCT	cst_marital_status
FROM bronze.crm_cust_info


-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================
-- 1. Checks for NULL or Duplicates in Primary Key
-- Expectation: No Results
SELECT
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- 2. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- 3. Check for Data abbreviations or consistency of values in low cardinality columns
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- 4. Check for invalid date order
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt


-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================
-- 1. Check for unwanted spaces in string values
-- Expectation: No Results
SELECT sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

-- 2. Checks integrity of other key columns
-- Expectation: No Results
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info)

SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info)

-- 3. Check for date in a integer format or invalid dates
SELECT
NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE 
	sls_order_dt <= 0 
	OR LEN(sls_order_dt) != 8 
	OR sls_order_dt > 20500101 
	OR sls_order_dt < 19000101

-- 4. Check for ORDER date	that sould be lower than SHIP date and DUE date
SELECT *
FROM bronze.crm_sales_details
WHERE 
	sls_order_dt > sls_ship_dt 
	OR sls_order_dt > sls_due_dt

-- 5. Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================
-- 1. Checks for key integration with CRM customer table
-- Expectation: Correct Results
SELECT
	cid,
	CASE
		WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		ELSE cid
	END AS cid,
	bdate,
	gen
FROM bronze.erp_cust_az12;

-- 2. Checks out-of-range Dates
-- Expectation: No NULL and Future Dates
SELECT DISTINCT
	bdate
FROM bronze.erp_cust_az12
WHERE 
	bdate < '1926-01-01' 
	OR bdate > GETDATE()

-- 3. Checks gender
-- Expectation: No NULL, Empty and abbreviated values
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================
-- 1. Checks for key integration with CRM customer table
-- Expectation: Correct Results
SELECT
	cid,
	cntry
FROM bronze.erp_loc_a101;

-- 2. Checks for country
-- Expectation: No null, abbreviations or empty values
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101;

-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================
-- 1. Checks for unwanted spaces in cat, subcat and maintainance column
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE 
	cat != TRIM(cat) 
	OR subcat != TRIM(subcat) 
	OR maintenance != TRIM(maintenance)

-- 2. Checks for Data standardization & consistency
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_g1v2

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_g1v2
