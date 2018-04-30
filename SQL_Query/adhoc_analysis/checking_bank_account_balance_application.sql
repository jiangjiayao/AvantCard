

-- 
-- with 
-- dta_temp as(
select
-- 	distinct on (customer_id) customer_id,	
	ca.customer_id,	
	ca.id,	
	ca.created_at,
	ca.stage,
	ca.source,			
	ca.credit_decision_id,			
	ca.status,			
	ca.product_type,			
	ca.uuid as ca_uuid,			
	ca.cannot_apply_reasons,	
		

	split_part(split_part(ca.information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(ca.information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(ca.information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(ca.information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(ca.information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	split_part(split_part(ca.information,'current_bank_account_balance: "',2),'"',1) as bank_account_balance
from
	customer_applications ca
where
	ca.product_type = 'credit_card' and 
 	ca.created_at > '2017-11-16 00:00:00'  
-- )
-- 
-- select count(ca_uuid), count(distinct ca_uuid), count(customer_id), count(distinct customer_id), count(credit_decision_id), count(distinct credit_decision_id) from dta_temp