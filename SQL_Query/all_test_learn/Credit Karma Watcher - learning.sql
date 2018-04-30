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
	)

-- select count(customer_id), count(distinct customer_id), count(uuid), count(distinct uuid) from cc_applications
-- 				5799				5295						5799			5799
,



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
	tsr.created_at>'2017-11-15')
	--and customer_id in (select customer_id from cc_applications)),

-- select count(id), count(distinct id), count(customer_id), count(distinct customer_id) from mla_reports
-- 			151983		151983				151983					96563

,




credit_report_details as (
Select
	cca.uuid, 
	
	tcr.created_at
	,tcr.id as credit_report_id
	,tcr.customer_id
	,tcr.vantage_score
	,tcr.fico_score
	,case when tcr.vantage_score between 500 and 999 then true else false end as vantage_valid
	,case when tcr.fico_score between 350 and 850 then true else false end as fico_valid
	,tcr.fraud_flag
-- 	, ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int open_bankruptcy
-- 	, ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int open_satisfactory_trades -- open and satisfactory trades six months or older
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G093S')::int number_of_public_records
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G215A')::int open_collections_accounts -- Number of third party collections with balance >0
-- 	, ((tcd.parsed_data->>'00V71')::json->>'AT01S')::int total_trades
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G960S')::int total_credit_inquires -- deduped
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G980S')::int credit_inquiries_last_6_months -- deduped
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G990S')::int credit_inquiries_last_12_months -- deduped
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G231S')::int collections_inquiries
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G233S')::int collections_inquiries_last_6_months
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G099S')::int bankruptcies_last_24_months
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G094S')::int count_bankruptcies
-- 	, ((tcd.parsed_data->>'00V71')::json->>'S064A')::int total_amount_collections
-- 	, ((tcd.parsed_data->>'00V71')::json->>'S064B')::int total_amount_non_medical_collections
-- 	, ((tcd.parsed_data->>'00V71')::json->>'S208S')::int tax_liens
-- 	, ((tcd.parsed_data->>'00V71')::json->>'S207S')::int months_since_most_recent_public_record_bankruptcy
-- 	, ((tcd.parsed_data->>'00V71')::json->>'AT20S')::int age_oldest_trade_months
-- 	, ((tcd.parsed_data->>'00V71')::json->>'AT21S')::int age_newest_trade_months
-- 	, ((tcd.parsed_data->>'00V71')::json->>'FI02S')::int open_finance_installment_trades
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G104S')::int months_since_most_recent_collections_inquiry
-- 	, ((tcd.parsed_data->>'00V71')::json->>'G103S')::int months_since_most_recent_credit_inquiry
-- 	, ((tcd.parsed_data->>'00V71')::json->>'AT101B')::int total_balance_excluding_housing
-- 	, ((tcd.parsed_data->>'00V71')::json->>'BC101S')::int total_credit_card_balance
-- 	, ((tcd.parsed_data->>'00V71')::json->>'BC31S')::int percentage_of_open_cc_with75p_util
-- 	, ((tcd.parsed_data->>'00V71')::json->>'BC34S')::int utilization_credit_card
-- 	, ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int late30 --Number of open trade lines (excluding student loans) which have a Last Payment Date in the last six (6) months and which have a 30-day or more past due current manner of payment
-- 	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 'established' else 'emerging' end as segment
-- 	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
-- 		case when tcr.fico_score >=630 then 1000
-- 			else case when tcr.fico_score>=600 then 750 else
-- 				case when tcr.fico_score>=570 then 500 else
-- 					case when tcr.fico_score>=550 then 300 else NULL 
-- 					end
-- 				end
-- 			end
-- 		end
-- 		else
-- 		case when tcr.fico_score>=630 then 500 else
-- 			case when tcr.fico_score>=550 then 300 else NULL 
-- 			end
-- 		end
-- 	end as fico_tier
-- 	, --start with overall rules introduced on December 18th 2017
-- 	Case when 
-- 		cca.created_at>'2017-12-18 21:00:00'
-- 		-- fill in all rules here
-- 		and (((tcd.parsed_data->>'00V71')::json->>'G094S')::int>1 			-- count of bankruptcies
-- 		or ((tcd.parsed_data->>'00V71')::json->>'BC101S')::int>30000 			-- total credit card balance
-- 		or ((tcd.parsed_data->>'00V71')::json->>'S064B')::int>5000 			-- total amount non medical collections
-- 		or ((tcd.parsed_data->>'00V71')::json->>'S208S')::int>0 			-- count of tax liens
-- 		or (((tcd.parsed_data->>'00V71')::json->>'S207S')::int between 0 and 12) 	-- months since last bankruptcy
-- 		or ((tcd.parsed_data->>'00V71')::json->>'G980S')::int>10			-- number of inquiries last 6 months
-- 		or case when 									-- account exists that was opened after most recent bankruptcy
-- 			((tcd.parsed_data->>'00V71')::json->>'G094S')::int=1 
-- 			and ((tcd.parsed_data->>'00V71')::json->>'S207S')::int<((tcd.parsed_data->>'00V71')::json->>'AT21S')::int 
-- 			then true else false end
-- 		)
-- 		then false 
-- 		Else
-- 			Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
-- 				-- established case
-- 				case when 
-- 				
-- 					 ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
-- 					 and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
-- 					 and tcr.fico_score >549 
-- 					 then	true
-- 					else	false
-- 					end
-- 				else
-- 				-- emerging case
-- 				case when
-- 					((tcd.parsed_data->>'00V71')::json->>'AT01S')::int>0
-- 					and ((tcd.parsed_data->>'00V71')::json->>'G093S')::int<1
-- 					and ((tcd.parsed_data->>'00V71')::json->>'G215A')::int<1
-- 					and ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
-- 					and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
-- 					and least(tcr.fico_score,tcr.vantage_score)>549
-- 					then true
-- 					else false
-- 				end
-- 			end
-- 		end as rules_pass
-- 	,Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 then 
-- 				-- established case
-- 				case when 
-- 				
-- 					 ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
-- 					 and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
-- 					 and tcr.fico_score >549 
-- 					 then	true
-- 					else	false
-- 					end
-- 				else
-- 				-- emerging case
-- 				case when
-- 					((tcd.parsed_data->>'00V71')::json->>'AT01S')::int>0
-- 					and ((tcd.parsed_data->>'00V71')::json->>'G093S')::int<1
-- 					and ((tcd.parsed_data->>'00V71')::json->>'G215A')::int<1
-- 					and ((tcd.parsed_data->>'00W63')::json->>'OPENBKC')::int=0
-- 					and ((tcd.parsed_data->>'00W63')::json->>'ATTR03')::int<2
-- 					and least(tcr.fico_score,tcr.vantage_score)>549
-- 					then true
-- 					else false
-- 				end
-- 			end as original_rules_pass
-- 	, Case when ((tcd.parsed_data->>'00V71')::json->>'AT24S')::int >=2 and tcr.fico_score between 350 and 850 
-- 		then tcr.fico_score 
-- 		else least(tcr.fico_score,tcr.vantage_score) 
-- 		end as score_used
-- 	, mlar.military_lending_act_confirmed as mla
	--, mlar.high_risk_fraud_alert
	--, tia.message_text as ID_alert
	
from	
	cc_applications cca 
		left join transunion_credit_reports tcr 
			on tcr.id=(select transunion_credit_report_id from credit_decisions where id=cca.credit_decision_id)  
			/* 
			1. inner join btwn cc_applications & credit_decisions on CREDIT_DECISION_ID, to get transunion_credit_report_id 
			2. left join, base: (1) on transunion_credit_reports_id

			one customer_id can have multiple credit_decision_id, some credit_decision_id does not have credit_report_id
				one customer_id can have multipel credit_report_id
				one customer_id can have none 	  credit_report_id

				--> accts(with dup, no missing), decision_id(no dup, no missing), report_id(with dup, with missing)
			*/
 		left join 
			transunion_characteristic_data tcd on tcd.transunion_credit_report_id=tcr.id
 		left join 
			mla_reports mlar on mlar.id=(select id from mla_reports where customer_id=tcr.customer_id order by created_at desc limit 1)

)


select count(customer_id), count(distinct customer_id), count(credit_report_id), count(distinct credit_report_id) from credit_report_details
-- 	
/*			2358				2298

select 
	cca.*, cd.id, cd.transunion_credit_report_id
from 
	(select ca.uuid, ca.customer_id, ca.credit_decision_id from customer_applications ca where ca.product_type = 'credit_card' and ca.created_at>'2018-01-10 04:43:00') cca
left join
	credit_decisions cd on cca.credit_decision_id = cd.id



select count(id), count(distinct id), count(transunion_credit_report_id), count(distinct transunion_credit_report_id) from credit_decisions

*/
		
