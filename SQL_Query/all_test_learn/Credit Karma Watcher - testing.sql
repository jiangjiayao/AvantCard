with 
cc_applications as(

select
	distinct on (customer_id) customer_id,		
	id,	
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00'and 
	status = 'closed' and 
	credit_decision_id is not null
order by
	customer_id, 
	created_at desc
)
/*
select count(id), count(distinct id),

count(customer_id), count(distinct customer_id), 
count(uuid), count(distinct uuid),
count(credit_decision_id), count(distinct credit_decision_id)

 from cc_applications
*/

-- ,
-- mla_reports as(

select 
	distinct on (ca.ca_uuid) ca.ca_uuid,
	
	tsr.id,
	tsr.created_at,
	tsr.credit_report_id,
	tsr.military_lending_act_confirmed as mla,

	cr.customer_id
from
	cc_applications ca
left join 
	credit_reports cr on ca.customer_id = cr.customer_id
left join
	transunion_secondary_reports tsr on cr.id = tsr.credit_report_id and tsr.created_at > '2017-11-15'
order by
	ca_uuid,
	customer_id,
	credit_report_id desc nulls last,
	created_at desc
)



-- select * from credit_reports limit 100

select count(uuid), count(distinct uuid), 
count(id), count(distinct id), 
count(customer_id), count(distinct customer_id) from mla_reports

select * from transunion_secondary_reports order by credit_report_id limit 3000

select count(credit_report_id), count(distinct credit_report_id) from transunion_secondary_reports



with temp_table as(
select 
	tsr.id, 
	tsr.created_at,
	tsr.credit_report_id, 
	tsr.military_lending_act_confirmed ,
	cr.customer_id

from 
	transunion_secondary_reports tsr
left join 
	credit_reports cr on tsr.credit_report_id=cr.id
)
select count(customer_id), count(distinct customer_id), count(credit_report_id), count(distinct credit_report_id) from temp_table















with 
cc_applications as(

select
	distinct on (customer_id) customer_id,
	id,
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00'
order by
	customer_id nulls first, 
	created_at desc
)


select  
distinct on (ca.uuid) ca.uuid, ca.customer_id as iiiiiid,
cr.customer_id, 
tsr.credit_report_id, tsr.military_lending_act_confirmed as mla
from cc_applications ca
left join credit_reports cr on ca.customer_id = cr.customer_id
left join transunion_secondary_reports tsr on cr.id = tsr.credit_report_id
order by ca.uuid, tsr.credit_report_id desc nulls last, tsr.created_at desc nulls last



select count(uuid) from customer_applications where customer_id =119499

select * from credit_decisions limit 348

select count(id), count(distinct id) from credit_decisions


















with 
cc_applications as(

select
	distinct on (customer_id) customer_id,
	id,
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00' and
	status = 'closed' and
	credit_decision_id is not null -- and 
-- 	uuid = 'dd4aa5b0-71e4-4d5a-b90d-30822bfab447'
order by
	customer_id nulls first, 
	created_at desc
)

-- select count(ca_uuid), count(distinct ca_uuid), count(credit_decision_id), count(distinct credit_decision_id) from cc_applications

select 
	ca.ca_uuid,
	tcr.created_at,
	tcr.id as credit_report_id,
	tcr.customer_id,
	tcr.vantage_score,
	tcr.fico_score,
	tcr.fraud_flag,

	((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int open_bankruptcy,
	((tcd.parsed_data->>'00V71')::json->>'AT24S')::int open_satisfactory_trades, 
	((tcd.parsed_data->>'00V71')::json->>'G093S')::int number_of_public_records,
	((tcd.parsed_data->>'00V71')::json->>'G215A')::int open_collections_accounts, 
	((tcd.parsed_data->>'00V71')::json->>'AT01S')::int total_trades,
	((tcd.parsed_data->>'00V71')::json->>'G960S')::int total_credit_inquires, 
	((tcd.parsed_data->>'00V71')::json->>'G980S')::int credit_inquiries_last_6_months, 
	((tcd.parsed_data->>'00V71')::json->>'G990S')::int credit_inquiries_last_12_months,
	((tcd.parsed_data->>'00V71')::json->>'G231S')::int collections_inquiries,
	((tcd.parsed_data->>'00V71')::json->>'G233S')::int collections_inquiries_last_6_months,
	((tcd.parsed_data->>'00V71')::json->>'G099S')::int bankruptcies_last_24_months,
	((tcd.parsed_data->>'00V71')::json->>'G094S')::int count_bankruptcies,
	((tcd.parsed_data->>'00V71')::json->>'S064A')::int total_amount_collections,
	((tcd.parsed_data->>'00V71')::json->>'S064B')::int total_amount_non_medical_collections,
	((tcd.parsed_data->>'00V71')::json->>'S208S')::int tax_liens,
	((tcd.parsed_data->>'00V71')::json->>'S207S')::int months_since_most_recent_public_record_bankruptcy,
	((tcd.parsed_data->>'00V71')::json->>'AT20S')::int age_oldest_trade_months,
	((tcd.parsed_data->>'00V71')::json->>'AT21S')::int age_newest_trade_months,
	((tcd.parsed_data->>'00V71')::json->>'FI02S')::int open_finance_installment_trades,
	((tcd.parsed_data->>'00V71')::json->>'G104S')::int months_since_most_recent_collections_inquiry,
	((tcd.parsed_data->>'00V71')::json->>'G103S')::int months_since_most_recent_credit_inquiry,
	((tcd.parsed_data->>'00V71')::json->>'AT101B')::int total_balance_excluding_housing,
	((tcd.parsed_data->>'00V71')::json->>'BC101S')::int total_credit_card_balance,
	((tcd.parsed_data->>'00V71')::json->>'BC31S')::int percentage_of_open_cc_with75p_util,
	((tcd.parsed_data->>'00V71')::json->>'BC34S')::int utilization_credit_card,
	((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int late30
from
	cc_applications ca 
left join 
	credit_decisions cd on ca.credit_decision_id = cd.id
left join
	transunion_credit_reports tcr on cd.transunion_credit_report_id = tcr.id
left join 
	transunion_characteristic_data tcd on tcr.id = tcd.transunion_credit_report_id
order by
	ca_uuid,
	cd.transunion_credit_report_id,
	created_at desc nulls last



select count(id), count(distinct id) from credit_decisions

select count(id), count(distinct id) from transunion_credit_reports

select * from transunion_credit_reports limit 100

select count(transunion_credit_report_id), count(distinct transunion_credit_report_id) from transunion_characteristic_data

select * from transunion_characteristic_data order by transunion_credit_report_id limit 1000
















with 
cc_applications as(

select
	distinct on (customer_id) customer_id,
	id,
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00' and
	status = 'closed' and
	credit_decision_id is not null -- and 
-- 	uuid = 'dd4aa5b0-71e4-4d5a-b90d-30822bfab447'
order by
	customer_id nulls first, 
	created_at desc
)

select 
	distinct on (ca.ca_uuid) ca.ca_uuid,
	cd.customer_id,
	cd.id as credit_decision_id,
	cd.created_at,
	cd.transunion_credit_report_id,
	round(cd.model_decline_score::numeric,4) as cc_model_score,

	case when cd.model_decline_score between 0 and 1 then true else false end as valid_model_score,
	case when cd.model_decline_score between 0 and 0.16 then true else false end as model_score_pass,
	case 
		when cd.model_decline_score <= 0.05 then 1000
		when cd.model_decline_score > 0.05 and cd.model_decline_score <= 0.07 then 750
		when cd.model_decline_score > 0.07 and cd.model_decline_score <= 0.10 then 500
		when cd.model_decline_score > 0.10 and cd.model_decline_score <= 0.16 then 300
		else 0 
	end as established_model_score_tier, 
	case 
		when cd.model_decline_score <= 0.07 then 500
		when cd.model_decline_score > 0.07 and cd.model_decline_score <= 0.16 then 300
		else 0
	end as emerging_model_score_tier,
	
	split_part(split_part(cd.inputs,'count_30_days_past_due_active_tradelines: ',2),E'\n',1) AS count_30_days_past_due_active_tradelines,
	split_part(split_part(cd.inputs,'has_open_bankruptcy: ',2),E'\n',1) AS has_open_bankruptcy,
	split_part(split_part(cd.inputs,'monthly_housing_expense: ',2),E'\n',1) AS monthly_housing_expense,
	split_part(split_part(cd.inputs,'amount_monthly_mortgage_payments: ',2),E'\n',1) AS monthly_mortgage_payment,
	split_part(split_part(cd.inputs,'new_rent_or_own: ',2),E'\n',1) AS rent_or_own,
	split_part(split_part(cd.inputs,'income_type: ',2),E'\n',1) AS income_type,
	split_part(split_part(cd.inputs,'monthly_net_income: ',2),E'\n',1) as monthly_net_income,

	pd.stats->'apr'->'inputs'->'spread'->'inputs'->>'pricing_strategy_id' as pricing_strategy,
	pd.stats->'line'->>'output' as line_assigned,
	pd.stats->'line'->'inputs'->'maximum_line_amount'->>'output' as max_line,
	pd.stats->'line'->'inputs'->'maximum_line_amount'->'inputs'->'debt_for_dti'->'inputs'->'monthly_housing_expense'->'inputs'->>'net_income' as net_income,
	pd.stats->'line'->'inputs'->'maximum_line_amount'->'inputs'->'debt_for_dti'->>'output' as monthly_debt,
	pd.stats->'fees'->'inputs'->'annual_membership_fee'->>'output' as amf,
	pd.stats->'apr'->>'output' as apr
from
	cc_applications ca
left join 
	credit_decisions cd on ca.credit_decision_id = cd.id
left join
	product_decisions pd on cd.id = pd.credit_decision_id and cd.version = 'default/credit-card/en-US/1.1'
order by
	ca_uuid, 
	customer_id


























select * from credit_decisions limit 100
select count(id), count(distinct id) from credit_decisions 










select * from verification_tasks limit 100
select * from credit_card_accounts limit 100
select * from products limit 100











with 
cc_applications as(

select
	distinct on (customer_id) customer_id,
	id,
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00' and
	status = 'closed' and
	credit_decision_id is not null -- and 
-- 	uuid = 'dd4aa5b0-71e4-4d5a-b90d-30822bfab447'
order by
	customer_id nulls first, 
	created_at desc
)


select
	distinct on (ca.ca_uuid) ca.ca_uuid,
	cca.uuid,
	vt.id,
	vt.name,
	vt.result,
	vt.product_uuid, 
	vt.product_type
from 
	cc_applications ca
left join
	credit_card_accounts cca on ca.ca_uuid = cca.customer_application_uuid
left join
	verification_tasks vt on cca.uuid = vt.product_uuid and vt.product_type='CreditCardAccount'
order by
	ca_uuid,
	vt.created_at desc nulls last






select * from credit_card_accounts order by customer_application_uuid limit 1000

select 
count(uuid), count(distinct uuid),
count(customer_application_uuid), count(distinct customer_application_uuid) 
from credit_card_accounts



select ca.uuid, cca.uuid, cca.customer_application_uuid from credit_card_accounts cca left join customer_applications ca on cca.customer_application_uuid = ca.uuid where ca.product_type = 'credit_card' and ca.created_at > '2018-01-10 18:25:00' 





















with 
cc_applications as(

select
	distinct on (customer_id) customer_id,
	id,
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			

	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	age(NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date) as age_1
from
	customer_applications
where
	product_type = 'credit_card' and 
	created_at > '2018-01-10 18:25:00' and
	status = 'closed' and
	credit_decision_id is not null -- and 
-- 	uuid = 'dd4aa5b0-71e4-4d5a-b90d-30822bfab447'
order by
	customer_id nulls first, 
	created_at desc
)

select
	distinct on (ca.ca_uuid) ca.ca_uuid,
	cae.customer_application_uuid,
	cae.stage, 
	cae.created_at
from 
	cc_applications ca 
left join
	customer_application_events cae on ca.ca_uuid = cae.customer_application_uuid
order by
	ca_uuid,
	cae.created_at desc nulls last


select * from customer_application_events order by customer_application_uuid limit 1000

select count(customer_application_uuid), count(distinct customer_application_uuid) from customer_application_events























