DROP TABLE IF EXISTS sales_summary ; 

CREATE TABLE sales_summary (trans_date DATE, beginning_or_no INT, 
			ending_or_no INT, gross_sales_amt DECIMAL(20, 2), `returns` DECIMAL(20, 2),
			discount DECIMAL(20, 2), terminalno INT, userid VARCHAR(20));
			
INSERT INTO sales_summary 

SELECT CONVERT(h.`ERDAT`, DATE) AS `trans_date`, CONVERT(RIGHT(MIN(h.`ORDNUM`), 10), SIGNED) AS `beginning_or_no`, CONVERT(RIGHT(MAX(h.`ORDNUM`), 10), SIGNED) AS `ending_or_no` 
	,SUM(d.`QTYORDERED`*d.`KBETR`) AS `gross_sales_amt`, 0, SUM(d.`QTYORDERED`*d.`KBETR`*d.`DISCPER`/100) AS `discount`, h.TERMINALNO, h.USERID
FROM zsd_eposordh h
INNER JOIN zsd_eposordd d ON h.`MANDT` = d.`MANDT`
			AND h.`ORDNUM` = d.`ORDNUM`
-- left join (select MANDT, ORDNUM, RET `returns` from zsd_eposcrdh rh GROUP BY ERDAT) ret ON h.MANDT = ret.MANDT
-- 										AND h.ORDNUM = ret.ORDNUM
WHERE TERMINALNO = 3
GROUP BY h.`ERDAT` ;

DROP TABLE IF EXISTS sales_summary_w_ending_bal ;

CREATE TABLE sales_summary_w_ending_bal (trans_date DATE, beginning_or_no INT, 
			ending_or_no INT, gross_sales_amt DECIMAL(20, 2), `returns` DECIMAL(20, 2),
			discount DECIMAL(20, 2), gross_sales_amt_2 DECIMAL(20, 2), terminalno INT, userid VARCHAR(20)) ;

INSERT INTO sales_summary_w_ending_bal 
SELECT s2.`trans_date`, s2.`beginning_or_no`, s2.`ending_or_no`
	,s2.`gross_sales_amt`, s2.`returns`, s2.`discount`
	, s1.`gross_sales_amt`, s2.TERMINALNO, s2.USERID
-- s1.`trans_date`, s1.`beginning_or_no`, s1.`ending_or_no`
-- 	,s1.`gross_sales_amt`, IFNULL(s2.`gross_sales_amt`, 0)+s1.`gross_sales_amt` as gross_ending_bal
-- 	,IFNULL(s2.`gross_sales_amt`, 0) as gross_beginning_bal
FROM sales_summary s1
RIGHT JOIN sales_summary s2 
ON s1.ending_or_no+1 = s2.beginning_or_no;
-- where s2.trans_date >= '2014-03-01';
			
ALTER TABLE sales_summary_w_ending_bal ADD COLUMN sales_beginning_bal DECIMAL(20, 2) NULL ;
ALTER TABLE sales_summary_w_ending_bal ADD COLUMN sales_ending_bal DECIMAL(20, 2) NULL ;

CREATE INDEX UNIQUE_trans_date ON sales_summary (trans_date) ;
CREATE INDEX INDEX_beg_or_no ON sales_summary (beginning_or_no) ;
CREATE INDEX INDEX_ending_or_no ON sales_summary (ending_or_no) ;

-- select * from sales_summary_w_ending_bal;

DELIMITER $$
 
DROP TABLE IF EXISTS `tbl_returns` $$

CREATE TABLE `tbl_returns` (
    trans_date DATE, return_amt DECIMAL(20, 2)
) $$

INSERT INTO `tbl_returns` 
SELECT CONVERT(h.ERDAT, DATE) AS `trans_date`, 
	SUM(RET)
FROM zsd_eposcrdh h
WHERE TERMINALNO = 3
GROUP BY h.ERDAT $$

UPDATE sales_summary_w_ending_bal
INNER JOIN tbl_returns ON sales_summary_w_ending_bal.`trans_date` = tbl_returns.`trans_date`
SET sales_summary_w_ending_bal.`returns` = tbl_returns.`return_amt` $$
 
-- select * from sales_summary_w_ending_bal $$


SELECT SUM(gross_sales_amt-`discount`-`returns`) FROM sales_summary_w_ending_bal WHERE TERMINALNO = 3

SELECT * fro m