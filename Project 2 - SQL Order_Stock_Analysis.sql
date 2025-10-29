 CREATE DATABASE Project2;
USE Project2;

SELECT * FROM date_wise_report;
DESCRIBE date_wise_report;
CREATE INDEX DWR_index ON date_wise_report(sale_id);
ALTER TABLE date_wise_report ADD Primary KEY (sale_id);
ALTER TABLE date_wise_report MODIFY sale_date DATE, MODIFY Item_Type VARCHAR(5), MODIFY  Job_Status VARCHAR (15),  MODIFY Created_On_Date DATE;
 
SELECT * FROM order_status;
DESCRIBE Order_status;
CREATE INDEX Os_index ON order_status (sale_id);
ALTER TABLE order_status ADD Primary KEY (sale_id);
ALTER TABLE order_status MODIFY Trans VARCHAR(25), MODIFY  Negative VARCHAR (5),MODIFY Order_type VARCHAR (25);

-- 1. We need to calculate the Stock count & work order count based on order_id
-- Result : This query extracts order type counts, identifying how many entries are classified as "stock" and how many as "work order".
SELECT Order_id , count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id;


-- 2. Next you calculate Work_order_pending Status
-- Result: This query computes the pending status by subtracting the work order count from the stock count.
SELECT Order_id, work_order_count ,stock_count, (work_order_count - stock_count) AS Work_order_pending_status 
From 
(SELECT Order_id,
count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id) AS Counts;


-- 3. finally you close the work_order
-- Conditions
-- (i) creat a new field (Field name work_order_closed_or_not
-- (ii) Work_order_pending status < 0 Then update order_closed other wise Order_pending (apply logical function)
-- Result: This query creates a new field `work_order_closed_or_not` based on whether the `work_order_pending_status` is less than 0.

SELECT order_id, work_order_count, stock_count, work_order_pending_status,
CASE 
	WHEN work_order_pending_status > 0 THEN 'Order_pending'
	ELSE 'Order_closed'
END AS work_order_closed_or_not From (SELECT Order_id, work_order_count ,stock_count, (work_order_count - stock_count) AS Work_order_pending_status 
From 
(SELECT Order_id,
count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id) AS Counts) AS OS_Status;

-- 4. you need to create a new table after completing pending status (table name: Order_pending_status)
-- result: This query creates a new table and populates it with the results of the previous query.

CREATE TABLE Order_pending_status AS SELECT order_id, work_order_count, stock_count, work_order_pending_status,
CASE 
	WHEN work_order_pending_status < 0 THEN 'Order_closed'
	ELSE 'Order_pending'
END AS work_order_closed_or_not From (SELECT Order_id, work_order_count ,stock_count, (work_order_count - stock_count) AS Work_order_pending_status 
From 
(SELECT Order_id,
count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count 
FROM order_status GROUP BY Order_id) AS Counts) AS OS_Status;

-- 5. We need to create a second table while using join (table name : order_supplier_report) Joining tables Table 1 – order_status and Table 2 - Date_wise _supplier

CREATE TABLE order_supplier_report AS
SELECT 
   dws.sale_id,dws.sale_date, dws.created_on_date, dws.job_status, dws.buyer_name, dws.preferred_supplier, dws.qty, os.order_id, os.order_type , Os.Description
FROM Order_Status os JOIN date_wise_report dws ON os.sale_id = dws.sale_id;

SELECT * FROM order_supplier_report;

-- 6. After creating second table find out the reports

-- (i) Date_wise Quantity & Order_id count
SELECT  sale_date, SUM(qty) AS Total_quantity, COUNT(order_id) AS order_id_count
FROM order_supplier_report GROUP BY sale_date;

-- (ii)you can split the supplier_name while using comma delimiter For ex Kumar N, Mr.Vinay will be Kumar N(last_name), Mr.vinay (first_name).
SELECT order_id, order_type, SUBSTRING_INDEX(buyer_name, ',', -1) AS last_name, SUBSTRING_INDEX(buyer_name, ',', 1) AS first_name, sale_date, qty
FROM  order_supplier_report;


-- 7. Finally you stored the all reports and tables while using stored procedure.

DELIMITER ##

CREATE PROCEDURE project2() 
BEGIN
SELECT Order_id , count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id;

SELECT Order_id, work_order_count ,stock_count, (work_order_count - stock_count) AS Work_order_pending_status 
From 
(SELECT Order_id,
count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id) AS Counts;

SELECT order_id, work_order_count, stock_count, work_order_pending_status,
CASE 
	WHEN work_order_pending_status > 0 THEN 'Order_closed'
	ELSE 'Order_pending'
END AS work_order_closed_or_not From (SELECT Order_id, work_order_count ,stock_count, (work_order_count - stock_count) AS Work_order_pending_status 
From 
(SELECT Order_id,
count(if(Order_type = 'stock','1',Null)) AS stock_count , count(if( order_type ='Work_order','1',Null))AS Work_order_count FROM order_status GROUP BY Order_id) AS Counts) AS OS_Status;

SELECT 
   dws.sale_id,dws.sale_date, dws.created_on_date, dws.job_status, dws.buyer_name, dws.preferred_supplier, dws.qty, os.order_id, os.order_type , Os.Description
FROM Order_Status os JOIN date_wise_report dws ON os.sale_id = dws.sale_id;

SELECT  sale_date, SUM(qty) AS Total_quantity, COUNT(order_id) AS order_id_count
FROM order_supplier_report GROUP BY sale_date;

SELECT order_id, order_type, SUBSTRING_INDEX(buyer_name, ',', -1) AS last_name, SUBSTRING_INDEX(buyer_name, ',', 1) AS first_name, sale_date, qty
FROM  order_supplier_report;
END ##
DELIMITER ;

CALL project2()
