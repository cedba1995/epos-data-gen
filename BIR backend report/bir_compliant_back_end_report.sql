DELIMITER $$

DROP PROCEDURE IF EXISTS test2 $$

CREATE PROCEDURE test2 ()
BEGIN
   DECLARE done INT DEFAULT FALSE;
   DECLARE v_trans_date DATE;
   DECLARE beginning_or_no, ending_or_no INT;
   DECLARE v_gross_sales_amt, v_gross_sales_amt2, v_returns, v_discount DECIMAL(20, 2);
   DECLARE sales_beg_bal, sales_end_bal DECIMAL(20, 2);
   DECLARE counter INT;
   DECLARE cur1 CURSOR FOR SELECT trans_date, beginning_or_no, ending_or_no,
				gross_sales_amt, gross_sales_amt_2, `returns`, discount 
			FROM sales_summary_w_ending_bal;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET  done = TRUE;
		
   SET sales_end_bal = 0;
   SET counter = 0;

   OPEN cur1;
   
   read_loop: LOOP
       FETCH cur1 INTO v_trans_date, beginning_or_no, ending_or_no,
			v_gross_sales_amt, v_gross_sales_amt2, v_returns, v_discount;
       IF done THEN
           LEAVE read_loop;
       END IF;
       SET sales_end_bal = sales_end_bal + IFNULL(v_gross_sales_amt, 0);
       -- set counter = counter + 1;
       UPDATE sales_summary_w_ending_bal 
          SET sales_beginning_bal = sales_end_bal - v_gross_sales_amt, 
		sales_ending_bal = sales_end_bal
       WHERE trans_date = v_trans_date; 
       -- if counter > 4 then
       --    leave read_loop ;
       -- end if; 
   END LOOP;
   
   CLOSE cur1;
 END $$
 
 CALL test2 ()$$ 
 
 SELECT trans_date AS `date`, beginning_or_no, ending_or_no, sales_ending_bal `grand_accum_ending_bal`,
	sales_beginning_bal `grand_accum_beg_bal`, NULL `sales_w_manual_or`, gross_sales_amt `gross_sales_for_the_day`,
	NULL `vatable_sales`, NULL `vat_amount`, NULL `vat_exempt_sales`, NULL `zero_rated_sales`, 
	NULL `sc_discount`, NULL `pwd_discount`, NULL `naac_discount`, NULL `solo_parent_discount`, discount `others_discount`,
	`returns`, NULL `voids`, `discount`+`returns` `total_deductions`, NULL `sc_discoiunt_2`, NULL `sc_discount_2`,
	NULL `pwd_discount_2`, NULL `others_discount_2`, NULL `vat_on_returns`, NULL `others_discount_2`, NULL `total_vat_adjustments`,
	NULL `vat_payable`, gross_sales_amt - (`returns`+`discount`) `net_sales`, NULL `sales_overrun_overflow`, 
	NULL `total_income`, NULL `reset_counter`, NULL `z_counter`, NULL `remarks`
FROM sales_summary_w_ending_bal$$


SELECT SUM(gross_sales_amt - (`returns`+`discount`)) FROM sales_summary_w_ending_bal $$