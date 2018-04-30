




/*
	-- step1: get credit card accounts
	-- cc_applicaitons
*/
with 
cc_applications as(
select
-- 	distinct on (customer_id) customer_id,	
	customer_id,	
	id,	
	created_at,
	stage,
	source,			
	credit_decision_id,			
	status,			
	product_type,			
	uuid as ca_uuid,			
	cannot_apply_reasons,			
/*	updated_at,			
	information,			
	contactable,			
	referrer_url,			
	promotion_code,			
	lead_id,			
	step1_variation,			
	loan_purpose,			
	last_viewed_stage,			
	encrypted_information,			
	last_seen_ip,			
	application_owner,
*/	
	split_part(split_part(information, 'first_name: ', 2), E'\n', 1) as first_name,
	split_part(split_part(information, 'last_name: ', 2), E'\n', 1) as last_name,
	split_part(split_part(information,'income_type: ',2),E'\n',1) as income_type,
	NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date AS dob,
	round((current_date-NULLIF(split_part(split_part(information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age,
	split_part(split_part(information,'current_bank_account_balance: "',2),'"',1) as bank_account_balance
from
	customer_applications
where
	product_type = 'credit_card' and 
 	created_at > '2017-11-16 00:00:00' and
-- 	created_at > '2018-01-10 04:43:00' and 
-- 	status = 'closed' and 
-- 	credit_decision_id is not null and
	customer_id not in (49307425, 76729523) and 
	id <> 94649950
order by
	customer_id, 
	created_at desc
),





/*
	step 2.1: get mla info for accts selectd above
	-- mla_reports
*/
mla_reports as(
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
),





/*
	step 2.2.1: get full credit history for accts selectd above
	-- credit_report_details_temp
*/
credit_report_details_temp as (
select 
	distinct on (ca.ca_uuid) ca.ca_uuid,
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
),





/*
	step 2.2.2: business rules
	-- credit_report_details
*/
credit_report_details as (
select 
	*, 
	case when vantage_score between 500 and 999 then true else false end as vantage_valid,
	case when fico_score between 350 and 850 then true else false end as fico_valid,
	case when (fico_score between 350 and 850) and (open_satisfactory_trades >= 2) then 'established' else 'emerging' end as segment,
	case 
		when (fico_score between 350 and 850) and (open_satisfactory_trades >= 2) then -- established
			case 
				when (fico_score >= 630) then 1000
				when (fico_score >= 600) and (fico_score < 630) then 750
				when (fico_score >= 570) and (fico_score < 600) then 500
				when (fico_score >= 550) and (fico_score < 570) then 300
				else null
		end
		else -- emerging
			case 
				when (fico_score >= 630) then 500
				when (fico_score >= 550) and (fico_score < 630) then 300
				else null
		end
	end as fico_tier, 
	
	case 
		when 
			(created_at > '2017-12-18 21:00:00') and 
			(count_bankruptcies > 1) or
			(total_credit_card_balance > 30000) or
			(total_amount_non_medical_collections > 5000) or
			(tax_liens > 0) or
			(months_since_most_recent_public_record_bankruptcy between 0 and 12) or 
			(credit_inquiries_last_6_months > 10) or 
			((count_bankruptcies = 1) and (months_since_most_recent_public_record_bankruptcy < age_newest_trade_months)) then false
		else
			case 
				when (open_satisfactory_trades >= 2) and (fico_score between 350 and 850) then 
				-- established
					case 
						when 
							(open_bankruptcy = 0) and 
							(late30 < 2) and 
							(fico_score > 549) then true
						else false
					end
				else 
				-- emerging
					case 
						when
							(total_trades > 0) and 
							(bankruptcies_last_24_months < 1) and 
							(open_collections_accounts < 1) and 
							(open_bankruptcy = 0) and 
							(late30 < 2) and 
							(fico_score > 549) then true
						else false
					end
			end
	end as rules_pass,	
	
	case 
		when (open_satisfactory_trades >= 2) and (fico_score between 350 and 850) then 
		-- established
			case
				when 
					(open_bankruptcy = 0) and 
					(late30 < 2) and
					(fico_score > 549) then true
				else false
			end
		else
		-- emerging
			case 
				when
					(total_trades > 0) and 
					(number_of_public_records < 1) and 
					(open_collections_accounts < 1) and
					(open_bankruptcy = 0) and 
					(late30 < 2) and 
					(least(fico_score, vantage_score)> 549) then true
				else false
			end
	end as original_rules_pass,

	case when (open_satisfactory_trades >= 2) and (fico_score between 350 and 850) then fico_score else least(fico_score, vantage_score) end as score_used	
from
	credit_report_details_temp
),





/*
	-- step 2.3: get model scores for for accts selectd above
	-- cc_model_scores
*/
cc_model_scores as (
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
),





/*
	-- step 2.4: get latest verfication activity
	-- verification_tasks_temp
*/
verification_tasks_temp as(
select
	distinct on (ca.ca_uuid) ca.ca_uuid,
	vt.id,
	vt.name,
	vt.result,
	vt.product_uuid
from 
	cc_applications ca
left join
	credit_card_accounts cca on ca.ca_uuid = cca.customer_application_uuid
left join
	verification_tasks vt on cca.uuid = vt.product_uuid and vt.product_type='CreditCardAccount'
order by
	ca_uuid,
	vt.created_at desc nulls last
),

	



/*
	-- step 2.5: get latest application event
	-- verification_tasks_temp
*/
customer_application_events_temp as(
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
)





/*
	-- step 3: combine everything above
*/
select
	ca.id as cust_app_id,
	ca.created_at::date as app_created_at,
	ca.first_name,
	ca.last_name,
	ca.customer_id,
	ca.age,
	ca.income_type,
	ca.bank_account_balance,
	case when ca.age > 18 then true else false end as age_pass,
	case when ca.created_at>'2017-12-18 21:00:00' then true else false end as applied_after_new_rules,

	mlar.mla,

	cca.status as card_status,
	cca.apr_percentage as card_apr,
	cca.cash_apr_percentage as card_cash_apr,
	case when cca.status is null then true else false end as declined,
	round(cca.annual_membership_fee_amount_cents/100,2)::money as card_amf,
	round(cca.credit_line_amount_cents/100,2)::money as card_line,
	case 
		when cca.id is null then null
		when cca.id is not null and cca.credit_line_amount_cents is null then false 
		else true  
	end as liked_offer,

	caet.stage::text as cc_app_stage, 
	caet.stage::text as cc_app_events_stage,
	tzcorrect(caet.created_at) as most_recent_ca_event,

	vtt.name as last_verifications_stage,
	vtt.result as last_ver_stage_progress, 

	ccms.credit_decision_id,
	ccms.model_score_pass as model_pass,
	ccms.cc_model_score,
	ccms.line_assigned::money,
	ccms.apr as apr,
	ccms.amf as amf,
	ccms.max_line::money,
	ccms.net_income::money as net_income,
	ccms.monthly_debt::money,
	round((ccms.monthly_debt::numeric+GREATEST(25,0.04*ccms.line_assigned::numeric))/nullif(ccms.net_income::numeric,0),2) as DTI,
	ccms.pricing_strategy,
	case 
		when ccms.monthly_debt is null then null
		when (ccms.monthly_Debt is not null) and ((ccms.monthly_debt::numeric + GREATEST(25,0.04*ccms.line_assigned::numeric)) / nullif(ccms.net_income::numeric,0) <= 0.7) then true
		else false
	end as dti_pass, 
	case when ccms.net_income::numeric >= 1000 then true else false end as income_pass,
	case 
		when (age > 18) and (crd.rules_pass) and (ccms.model_score_pass) then
			case
				when crd.segment = 'established' then
					case
						when 
							(crd.fico_score >= 630) and
							(ccms.cc_model_score <= 0.05) then 1000
						when 
							(crd.fico_score >= 600) and
							(crd.fico_score < 630) and 
							(ccms.cc_model_score <= 0.07) and 
							(ccms.cc_model_score > 0.05) then 750
						when 
							(crd.fico_score >= 570) and
							(crd.fico_score < 600) and
							(ccms.cc_model_score <= 0.1) and
							(ccms.cc_model_score > 0.07) then 500
						when 
							(crd.fico_score >= 550) and
							(crd.fico_score < 570) and
							(ccms.cc_model_score <= 0.16) and
							(ccms.cc_model_score > 0.1) then 300
						else null
					end
				when crd.segment = 'emerging' then 
					case
						when
							(crd.fico_score >= 630) and 
							(ccms.cc_model_score <= 0.07) then 500
						when
							(crd.fico_score >= 550) and 
							(crd.fico_score < 630) and 
							(ccms.cc_model_score <= 0.16) and
							(ccms.cc_model_score > 0.07) then 300
						else null
					end
				else null
			end
		else null
	end as expected_line, 
	
	crd.customer_id,
	crd.fico_score,
	crd.segment,
	crd.rules_pass, 
	crd.rules_pass and ccms.model_score_pass as credit_pass,
	crd.vantage_score,
	crd.fico_valid,
	crd.vantage_valid,
	crd.fraud_flag,
	crd.open_bankruptcy,
	crd.open_satisfactory_trades,
	crd.number_of_public_records,
	crd.open_collections_accounts,
	crd.total_trades,
	crd.late30,
	crd.score_used,
	crd.created_at as credit_report_created_at,
	crd.fico_tier, 
	crd.credit_inquiries_last_6_months,
	crd.credit_inquiries_last_12_months,
	crd.collections_inquiries,
	crd.collections_inquiries_last_6_months,
	crd.bankruptcies_last_24_months,
	crd.total_amount_collections,
	crd.total_amount_non_medical_collections,
	crd.tax_liens,
	crd.age_oldest_trade_months,
	crd.age_newest_trade_months,
	crd.open_finance_installment_trades,
	crd.months_since_most_recent_collections_inquiry,
	crd.months_since_most_recent_credit_inquiry,
	crd.total_balance_excluding_housing,
	crd.total_credit_card_balance,
	crd.percentage_of_open_cc_with75p_util,
	crd.utilization_credit_card,
	crd.months_since_most_recent_public_record_bankruptcy,
	crd.count_bankruptcies,
	crd.original_rules_pass,
	case when crd.fico_score>680 then true else false end as fico_score_high,
	case when crd.vantage_score>680 then true else false end as vantage_score_high,
	case
		when crd.segment = 'established' then ccms.established_model_score_tier 
		when crd.segment = 'emerging' then ccms.emerging_model_score_tier
		else null
	end as model_score_tier, 
	case 
		when (crd.months_since_most_recent_public_record_bankruptcy >= 0) and (crd.months_since_most_recent_public_record_bankruptcy - age_newest_trade_months > 0) then true 
		when (crd.months_since_most_recent_public_record_bankruptcy >= 0) and (crd.months_since_most_recent_public_record_bankruptcy - age_newest_trade_months <= 0) then false
		else NULL 
	end as trade_opened_after_bankruptcy,
	case when crd.total_credit_card_balance > 30000 then true else false end as cc_balance_limit_too_high,
	case when crd.total_amount_non_medical_collections > 5000 then true else false end as nm_collections_balance_too_high,
	case 
		when
			(crd.count_bankruptcies > 1) or
			(crd.total_credit_card_balance > 30000) or
			(crd.total_amount_non_medical_collections) > 5000 or
			(crd.tax_liens > 0) or
			(crd.months_since_most_recent_public_record_bankruptcy between 0 and 12) or
			(crd.credit_inquiries_last_6_months > 10) or 
			((crd.count_bankruptcies = 1) and (crd.months_since_most_recent_public_record_bankruptcy < age_newest_trade_months)) then true
		else false
	end as fails_new_rules,

	round(crd.total_credit_card_balance/nullif(ccms.net_income::numeric,0)::numeric*100,2) as cc_debt_of_net_income,
	round(GREATEST(0,crd.total_amount_non_medical_collections)/nullif(ccms.net_income::numeric,0)::numeric*100,2) as open_non_medical_collections_of_net_income,
	round(GREATEST(0,crd.total_amount_collections)/nullif(ccms.net_income::numeric,0)::numeric*100,2) as open_collections_of_net_income
from
	cc_applications ca
left join
	cc_model_scores ccms on ca.ca_uuid = ccms.ca_uuid
left join
	credit_report_details crd on ca.ca_uuid = crd.ca_uuid
left join
	customer_application_events_temp caet on ca.ca_uuid = caet.ca_uuid
left join
	credit_card_accounts cca on ca.ca_uuid = cca.customer_application_uuid
left join
	verification_tasks_temp vtt on ca.ca_uuid = vtt.ca_uuid
left join
	mla_reports mlar on ca.ca_uuid = mlar.ca_uuid
order by
	cust_app_id











