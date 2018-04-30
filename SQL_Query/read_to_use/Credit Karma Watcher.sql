With 
cc_applications as (
-- get credit card applications from launch date and ongoing, link the loan app if it is decline path, so it can be used in decline_offer_monetization_decisions and partner_offers
select 
	ca.created_at
	, ca.customer_id
	, ca.stage
	, ca.source
	, ca.credit_decision_id
	, ca.status
	, ca.uuid
	, ca.id
	, initcap(split_part(split_part(ca.information,'first_name: ',2),E'\n',1)) as first_name
	, initcap(split_part(split_part(ca.information,'last_name: ',2),E'\n',1)) as last_name
	, split_part(split_part(ca.information,'income_type: ',2),E'\n',1) AS income_type
	--, split_part(split_part(ca.information,'monthly_net_income: ',2),E'\n',1)::numeric AS monthly_net_income
	, NULLIF(split_part(split_part(ca.information,'date_of_birth: ',2),E'\n',1),'')::date AS dob
	, round((current_date-NULLIF(split_part(split_part(ca.information,'date_of_birth: ',2),E'\n',1),'')::date)/365::numeric,1) AS age
	, ca.product_type
	--, camf.val as declined_loan_app_uuid
	, ca.cannot_apply_reasons
	
from 
	customer_applications ca
		--left join customer_application_metadata_fields camf 
		--	on camf.customer_application_uuid=ca.uuid and camf.key='decline_offer_source_application_uuid'
where	
	ca.product_type='credit_card' and ca.created_at>'2018-01-10 04:43:00' --and camf.created_at>ca.created_at-interval '1 day'
	),
mla_reports as (
select 
	tsr.id, 
	tsr.created_at,
	tsr.credit_report_id, 
	tsr.military_lending_act_confirmed ,
	cr.customer_id
	--tsr.uuid, 
	--thrfa.message_text as high_risk_fraud_alert
from 
	transunion_secondary_reports tsr
	left join credit_reports cr on tsr.credit_report_id=cr.id
	--left join transunion_high_risk_fraud_alerts thrfa on thrfa.tsr_uuid=tsr.uuid

where 
	tsr.created_at>'2017-11-15'),
	--and customer_id in (select customer_id from cc_applications)),

credit_report_details as (
Select
	tcr.created_at
	,tcr.id as credit_report_id
	,tcr.customer_id
	,tcr.vantage_score
	,tcr.fico_score
	,case when tcr.vantage_score between 500 and 999 then true else false end as vantage_valid
	,case when tcr.fico_score between 350 and 850 then true else false end as fico_valid
	,tcr.fraud_flag
	, ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int open_bankruptcy
	, ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int open_satisfactory_trades -- open and satisfactory trades six months or older
	, ((tcd.parsed_data->>'00V71')::json->>'G093S')::int number_of_public_records
	, ((tcd.parsed_data->>'00V71')::json->>'G215A')::int open_collections_accounts -- Number of third party collections with balance >0
	, ((tcd.parsed_data->>'00V71')::json->>'AT01S')::int total_trades
	, ((tcd.parsed_data->>'00V71')::json->>'G960S')::int total_credit_inquires -- deduped
	, ((tcd.parsed_data->>'00V71')::json->>'G980S')::int credit_inquiries_last_6_months -- deduped
	, ((tcd.parsed_data->>'00V71')::json->>'G990S')::int credit_inquiries_last_12_months -- deduped
	, ((tcd.parsed_data->>'00V71')::json->>'G231S')::int collections_inquiries
	, ((tcd.parsed_data->>'00V71')::json->>'G233S')::int collections_inquiries_last_6_months
	, ((tcd.parsed_data->>'00V71')::json->>'G099S')::int bankruptcies_last_24_months
	, ((tcd.parsed_data->>'00V71')::json->>'G094S')::int count_bankruptcies
	, ((tcd.parsed_data->>'00V71')::json->>'S064A')::int total_amount_collections
	, ((tcd.parsed_data->>'00V71')::json->>'S064B')::int total_amount_non_medical_collections
	, ((tcd.parsed_data->>'00V71')::json->>'S208S')::int tax_liens
	, ((tcd.parsed_data->>'00V71')::json->>'S207S')::int months_since_most_recent_public_record_bankruptcy
	, ((tcd.parsed_data->>'00V71')::json->>'AT20S')::int age_oldest_trade_months
	, ((tcd.parsed_data->>'00V71')::json->>'AT21S')::int age_newest_trade_months
	, ((tcd.parsed_data->>'00V71')::json->>'FI02S')::int open_finance_installment_trades
	, ((tcd.parsed_data->>'00V71')::json->>'G104S')::int months_since_most_recent_collections_inquiry
	, ((tcd.parsed_data->>'00V71')::json->>'G103S')::int months_since_most_recent_credit_inquiry
	, ((tcd.parsed_data->>'00V71')::json->>'AT101B')::int total_balance_excluding_housing
	, ((tcd.parsed_data->>'00V71')::json->>'BC101S')::int total_credit_card_balance
	, ((tcd.parsed_data->>'00V71')::json->>'BC31S')::int percentage_of_open_cc_with75p_util
	, ((tcd.parsed_data->>'00V71')::json->>'BC34S')::int utilization_credit_card
	, ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int late30 --Number of open trade lines (excluding student loans) which have a Last Payment Date in the last six (6) months and which have a 30-day or more past due current manner of payment
	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 'established' else 'emerging' end as segment
	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
		case when tcr.fico_score >=630 then 1000
			else case when tcr.fico_score>=600 then 750 else
				case when tcr.fico_score>=570 then 500 else
					case when tcr.fico_score>=550 then 300 else NULL 
					end
				end
			end
		end
		else
		case when tcr.fico_score>=630 then 500 else
			case when tcr.fico_score>=550 then 300 else NULL 
			end
		end
	end as fico_tier
	, --start with overall rules introduced on December 18th 2017
	Case when 
		cca.created_at>'2017-12-18 21:00:00'
		-- fill in all rules here
		and (((tcd.parsed_data->>'00V71')::json->>'G094S')::int>1 			-- count of bankruptcies
		or ((tcd.parsed_data->>'00V71')::json->>'BC101S')::int>30000 			-- total credit card balance
		or ((tcd.parsed_data->>'00V71')::json->>'S064B')::int>5000 			-- total amount non medical collections
		or ((tcd.parsed_data->>'00V71')::json->>'S208S')::int>0 			-- count of tax liens
		or (((tcd.parsed_data->>'00V71')::json->>'S207S')::int between 0 and 12) 	-- months since last bankruptcy
		or ((tcd.parsed_data->>'00V71')::json->>'G980S')::int>10			-- number of inquiries last 6 months
		or case when 									-- account exists that was opened after most recent bankruptcy
			((tcd.parsed_data->>'00V71')::json->>'G094S')::int=1 
			and ((tcd.parsed_data->>'00V71')::json->>'S207S')::int<((tcd.parsed_data->>'00V71')::json->>'AT21S')::int 
			then true else false end
		)
		then false 
		Else
			Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
				-- established case
				case when 
				
					 ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
					 and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
					 and tcr.fico_score >549 
					 then	true
					else	false
					end
				else
				-- emerging case
				case when
					((tcd.parsed_data->>'00V71')::json->>'AT01S')::int>0
					and ((tcd.parsed_data->>'00V71')::json->>'G093S')::int<1
					and ((tcd.parsed_data->>'00V71')::json->>'G215A')::int<1
					and ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
					and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
					and least(tcr.fico_score,tcr.vantage_score)>549
					then true
					else false
				end
			end
		end as rules_pass
	,Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
				-- established case
				case when 
				
					 ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
					 and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
					 and tcr.fico_score >549 
					 then	true
					else	false
					end
				else
				-- emerging case
				case when
					((tcd.parsed_data->>'00V71')::json->>'AT01S')::int>0
					and ((tcd.parsed_data->>'00V71')::json->>'G093S')::int<1
					and ((tcd.parsed_data->>'00V71')::json->>'G215A')::int<1
					and ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
					and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
					and least(tcr.fico_score,tcr.vantage_score)>549
					then true
					else false
				end
			end as original_rules_pass
	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 
		then tcr.fico_score 
		else least(tcr.fico_score,tcr.vantage_score) 
		end as score_used
	, mlar.military_lending_act_confirmed as mla
	--, mlar.high_risk_fraud_alert
	--, tia.message_text as ID_alert
	
from	
	cc_applications cca 
		left join transunion_credit_reports tcr 
			on tcr.id=(select transunion_credit_report_id from credit_decisions where id=cca.credit_decision_id)
		 left join transunion_characteristic_data tcd 
			on tcd.transunion_credit_report_id=tcr.id
		left join mla_reports mlar 
			on mlar.id=(select id from mla_reports where customer_id=tcr.customer_id order by created_at desc limit 1)), 
cc_model_scores as (
select 		
	distinct on (customer_id)
	--cms.id as score_id
	 cd.customer_id
	, cd.id as credit_decision_id  
	, round(cd.model_decline_score::numeric,4) as cc_model_score
	, case when cd.model_decline_score between 0 and 1 then true else false end as valid_model_score
	, case when cd.model_decline_score between 0 and 0.16 then true else false end as model_score_pass
	, case when cd.model_decline_score <= .05 then 1000 else 
		case when cd.model_decline_score <=.07 then 750  else
			case when cd.model_decline_score <=0.1 then 500  else
				case when cd.model_decline_score<=0.16 then 300 
				else 0
				end  
			end
		end
	  end as established_model_score_tier
	, case when cd.model_decline_score <=0.07 then 500 else
		case when cd.model_decline_score<=0.16 then 300 else 0 end end as emerging_model_score_tier
	, cd.created_at
	, cd.transunion_credit_report_id
	, split_part(split_part(cd.inputs,'count_30_days_past_due_active_tradelines: ',2),E'\n',1) AS count_30_days_past_due_active_tradelines
	, split_part(split_part(cd.inputs,'has_open_bankruptcy: ',2),E'\n',1) AS has_open_bankruptcy 
	, split_part(split_part(cd.inputs,'monthly_housing_expense: ',2),E'\n',1) AS monthly_housing_expense
	, split_part(split_part(cd.inputs,'amount_monthly_mortgage_payments: ',2),E'\n',1) AS monthly_mortgage_payment
	, split_part(split_part(cd.inputs,'new_rent_or_own: ',2),E'\n',1) AS rent_or_own
	, split_part(split_part(cd.inputs,'income_type: ',2),E'\n',1) AS income_type
	, (pd.stats->'apr'->'inputs'->'spread'->'inputs'->>'pricing_strategy_id') as pricing_strategy
	, (pd.stats->'line'->>'output') as line_assigned
	, (pd.stats->'line'->'inputs'->'maximum_line_amount'->>'output') as max_line
	, coalesce(split_part(split_part(cd.inputs,'monthly_net_income: ',2),E'\n',1),
		(pd.stats->'line'->'inputs'->'maximum_line_amount'->'inputs'->'debt_for_dti'->'inputs'->'monthly_housing_expense'->'inputs'->>'net_income')) as net_income
	, (pd.stats->'line'->'inputs'->'maximum_line_amount'->'inputs'->'debt_for_dti'->>'output') as monthly_debt
	, (pd.stats->'fees'->'inputs'->'annual_membership_fee'->>'output') as amf
	, (pd.stats->'apr'->>'output') as apr
	--, cast(substr(substring(cd.inputs,'requested_amount:\s([\d]+)'),1,9) as float) as requested_amount
	, split_part(split_part(cd.inputs,'monthly_net_income: ',2),E'\n',1) as monthly_net_income
from 	credit_decisions cd 		
		left join
		product_decisions pd on pd.credit_decision_id=cd.id
where 
	cd.id in (select credit_decision_id from cc_applications)
	and cd.version='default/credit-card/en-US/1.1'
	--and cd.created_at>'2017-11-15'
	--and pd.created_at>'2017-11-15'
	)
select
	crd.customer_id,
	ca.id as cust_app_id,
	ca.first_name,
	ca.last_name,
	cca.status as card_status,
	cae.stage::text as cc_app_stage,
	vt.name as last_verifications_stage,
	vt.result as last_ver_stage_progress,
	cae.stage::text as cc_app_events_stage,
	tzcorrect(cae.created_at) as most_recent_ca_event,
	cca.apr_percentage as Card_apr,
	round(cca.annual_membership_fee_amount_cents/100,2)::money as Card_AMF,
	round(cca.credit_line_amount_cents/100,2)::money as Card_line,
	cca.cash_apr_percentage as card_cash_apr,
	crd.fico_score,
	crd.segment,
	crd.mla,
	case when 
		ca.age>18 
			then true 
			else false end 
			as age_pass,
	case when ccms.monthly_debt is null 
		then null 
		else
		case when
			(ccms.monthly_debt::numeric+GREATEST(25,0.04*ccms.line_assigned::numeric))/nullif(ccms.net_income::numeric,0) <=0.7 
			then true 
			else false 
		end 
	end
	as dti_pass,
	case when ccms.net_income::numeric>=1000 then true else false end as income_pass,
	crd.rules_pass and ccms.model_score_pass as credit_pass,
	crd.rules_pass,
	ccms.model_score_pass as model_pass,
	ccms.cc_model_score,
	case when 
		ca.age>18
		and crd.rules_pass and ccms.model_score_pass
		then 
			case when 
				crd.segment='established' 
				then
				case when crd.fico_score>=630 and ccms.cc_model_score<=0.05 then 1000::money else
					case when crd.fico_score>=600 and ccms.cc_model_score<=0.07 then 750::money else
						case when crd.fico_score>=570 and ccms.cc_model_score<=0.1 then 500::money else 300::money end
					end
				end
				else
				case when crd.fico_score>=630 and ccms.cc_model_score<=0.07 then 500::money else 300::money end
			end
			else 0::money	
		end
		
		as expected_line,
	ccms.line_assigned::money,
	ccms.apr as apr,
	ccms.amf as amf,
	ccms.max_line::money,
	ccms.net_income::money as net_income,
	ccms.monthly_debt::money,
	round((ccms.monthly_debt::numeric+GREATEST(25,0.04*ccms.line_assigned::numeric))/nullif(ccms.net_income::numeric,0),2) as DTI,
	ccms.pricing_strategy,
	------------------------------------Details--------from report------------------------------------
	'monsters/details' as here_there_be,
	ca.age,
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
	ca.income_type,
	ccms.credit_decision_id,
	case when crd.segment='established' 
		then ccms.established_model_score_tier 
			else 
			case when crd.segment='emerging' 
				then ccms.emerging_model_score_tier 
				else NULL 
			end 
	end as model_score_tier,
	crd.fico_tier,
	 crd.total_credit_inquires
	, crd.credit_inquiries_last_6_months
	, crd.credit_inquiries_last_12_months
	, crd.collections_inquiries
	, crd.collections_inquiries_last_6_months
	, crd.bankruptcies_last_24_months
	, crd.total_amount_collections
	, crd.total_amount_non_medical_collections
	, crd.tax_liens
	, crd.age_oldest_trade_months
	, crd.age_newest_trade_months
	, crd.open_finance_installment_trades
	, crd.months_since_most_recent_collections_inquiry
	, crd.months_since_most_recent_credit_inquiry
	, crd.total_balance_excluding_housing
	, crd.total_credit_card_balance
	, case when ccms.net_income::numeric>7500 then true else false end as income_high
	, case when ccms.net_income::numeric>7500 and ccms.net_income::numeric<12000 then true else false end as potential_income_policy_fail
	, case when ccms.net_income::numeric>=12000 and 
		(ccms.monthly_debt::numeric+GREATEST(25,0.04*ccms.line_assigned::numeric))/(nullif(ccms.net_income::numeric,0)::numeric/12)>0.7 then true 
		else false end as potential_dti_fail
	, case when crd.fico_score>680 then true else false end as fico_score_high
	, case when crd.vantage_score>680 then true else false end as vantage_score_high
	, crd.percentage_of_open_cc_with75p_util
	, crd.utilization_credit_card
	, crd.months_since_most_recent_public_record_bankruptcy
	--, crd.ID_alert
	--, crd.high_risk_fraud_alert
	, ca.created_at::date as app_created_at
	, case when crd.months_since_most_recent_public_record_bankruptcy>=0 then
		case when crd.months_since_most_recent_public_record_bankruptcy-age_newest_trade_months>0 then true else false end
		else NULL end as trade_opened_after_bankruptcy
	, round(crd.total_credit_card_balance/nullif(ccms.net_income::numeric,0)::numeric*100,2) as cc_debt_of_net_income
	, round(GREATEST(0,crd.total_amount_non_medical_collections)/nullif(ccms.net_income::numeric,0)::numeric*100,2) as open_non_medical_collections_of_net_income
	, round(GREATEST(0,crd.total_amount_collections)/nullif(ccms.net_income::numeric,0)::numeric*100,2) as open_collections_of_net_income
	, case when cca.status is null then true else false end as declined
	, crd.count_bankruptcies
	, case when crd.total_credit_card_balance>30000 then true else false end as cc_balance_limit_too_high
	, case when crd.total_amount_non_medical_collections>5000 then true else false end as nm_collections_balance_too_high
	, case when
		crd.count_bankruptcies>1 
		or crd.total_credit_card_balance>30000 
		or crd.total_amount_non_medical_collections>5000 
		or crd.tax_liens>0 
		or (crd.months_since_most_recent_public_record_bankruptcy between 0 and 12) 
		or crd.credit_inquiries_last_6_months>10
		or case when 
			crd.count_bankruptcies=1 
			and crd.months_since_most_recent_public_record_bankruptcy<age_newest_trade_months 
			then true else false end
		then true else false end as fails_new_rules
	, case when cca.id is null then null else
			case when cca.credit_line_amount_cents is null 
			then false else true end 
			end as liked_offer
	, case when ca.created_at>'2017-12-18 21:00:00' then true else false end as applied_after_new_rules
	, crd.original_rules_pass
	
	
from
	cc_applications ca
	left join
		cc_model_scores ccms 
			on ccms.credit_decision_id=ca.credit_decision_id
	left join 
		credit_report_details crd on ccms.transunion_credit_report_id=crd.credit_report_id	
	left join 
		customer_application_events cae on cae.id=(select id from customer_application_events where customer_application_uuid=ca.uuid order by created_at desc limit 1)
	left join 
		credit_card_accounts cca on cca.customer_application_uuid=ca.uuid
	left join
		verification_tasks vt on vt.id=(select id from verification_tasks where product_uuid=cca.uuid and product_type='CreditCardAccount' order by created_at desc limit 1)
where 
	ca.product_type='credit_card' and ca.created_at>'2018-01-10 18:25:00'
	and ca.customer_id<>49307425 --no Tyler Bakanas Avant Test Employee
	and ca. customer_id<>76729523 --no Igor Simkin, Card King
	and ca.id<>94619950
order by card_status, cc_app_stage, customer_id, ca.created_at desc
--limit 5000