tables crated:
	cc_application
	mla_reports
	credit_report_details
	cc_model_scores
	loan_app_pre_card
	cc_partner_offers
	cc_offers





	cc_applications ca
	cc_model_scores ccms
	credit_report_details crd
	loan_app_pre_card lapc
	cc_offers cco
	customer_application_events cae
	credit_card_accounts cca
	verification_tasks vt





'
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
	, camf.val as declined_loan_app_uuid
	, ca.cannot_apply_reasons

from
	customer_applications ca
		left join customer_application_metadata_fields camf
			on camf.customer_application_uuid=ca.uuid and camf.key='decline_offer_source_application_uuid'
where
	ca.product_type='credit_card' and ca.created_at>'2017-11-15 04:43:00' and camf.created_at>ca.created_at-interval '1 day'),
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
	),

loan_app_pre_card as (
select
	loap.uuid as loan_app_uuid,
	ccap.uuid as cc_app_uuid,
	ccap.id as credit_card_app_id,
	loap.id as loan_app_id,
	loap.stage,
	loap.source,
	split_part(split_part(loap.information,'amount: ',2),E'\n',1) as requested_amount,
	case when
		left(loap.source,4)='bing'
		or left(loap.source,8)='facebook'
		or left(loap.source,6)='google'
		or loap.source in
			('commission_junction','other','sofi','lendingtree','impact_radius','creditsesame','bestegg','ams','creditcom_B','creditcom','mint','radio2','steelhouse','experian','mybankrate','tv','avantblog','gsp',
			'fast50','android_prefill','referral','elr_tmgl','android','avantdotcom','ios','mint_center','wisepiggy', 'organic')
		then true
		else false
		end
		as sellable_source,
	split_part(split_part(loap.information,'state: ',2),E'\n',1) as state,
	case when
		split_part(split_part(loap.information,'state: ',2),E'\n',1)
			in ('AL','AK','AZ','AR','CA','CT','DE','FL','GA','HI','ID','IL','IN','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VA','WA','WY','DC')
			then true
			else false
			end
		as state_pass,
	case when (position('ineligible_customer' in cd.decline_reasons) <>0 and split_part(split_part(loap.information,'amount: ',2),E'\n',1)::numeric>1000) or position('fraud' in cd.decline_reasons)<>0 then true else false end as ineligible_customer,
	case when position('loan_stacking' in cd.decline_reasons) <> 0 then true else false end as loan_stacking,
	case when position('factor_trust_inquiries' in cd.decline_reasons)<>0 then true else false end as factor_trust_inquiries,
	coalesce(cd.decline_reasons,ed.decline_reasons,loap.cannot_apply_reasons) as decline_reasons
	, split_part(split_part(cd.inputs,'count_30_days_past_due_active_tradelines: ',2),E'\n',1) AS count_30_days_past_due_active_tradelines
	, split_part(split_part(cd.inputs,'has_open_bankruptcy: ',2),E'\n',1) AS has_open_bankruptcy
	, split_part(split_part(cd.inputs,'monthly_housing_expense: ',2),E'\n',1)::money AS monthly_housing_expense
	, split_part(split_part(cd.inputs,'amount_monthly_mortgage_payments: ',2),E'\n',1)::money AS monthly_mortgage_payment
	, split_part(split_part(cd.inputs,'new_rent_or_own: ',2),E'\n',1) AS rent_or_own
	, coalesce(ccd.decline_reasons,ced.decline_reasons,ccap.cannot_apply_reasons) as card_decline_reasons


from
	cc_applications ccap
	left join customer_applications loap on loap.uuid=ccap.declined_loan_app_uuid
	left join credit_decisions cd on cd.id=loap.credit_decision_id
	left join eligibility_decisions ed on ed.id=(select id from eligibility_decisions  where customer_application_id=loap.id order by created_at desc limit 1)
	left join credit_decisions ccd on ccd.id=ccap.credit_decision_id
	left join eligibility_decisions ced on ced.id=(select id from eligibility_decisions  where customer_application_id=ccap.id order by created_at desc limit 1)

where
	--ccap.product_type='credit_card' and ccap.created_at>'2017-11-15 04:43:00' ),
	loap.created_at>ccap.created_at-interval '1 day'
	and cd.created_at>'2017-11-15'
	),
cc_partner_offers as (
select
	id,
	customer_id,
	viewed_at,
	clicked_at,
	cannot_offer_reasons,
	customer_application_id,
	decline_monetization_decision_uuid,
	template,
	(data->>'apr') as apr,
	(data->>'annual_membership_fee') as amf
from
	partner_offers
where
	partner_code='avant_card' and created_at>'2017-11-15'
),
cc_offers as (
select

	dmd.customer_application_uuid,

	--outcome,
	(dmd.outcome->'partner_outcomes'->'avant_card'->>'disqualified_reasons') as disqualified_reasons,
	(dmd.outcome->'partner_outcomes'->'avant_card'->>'not_displayed_reasons') as not_displayed_reasons,
	ccpo.template,
	ccpo.apr,
	ccpo.amf

from
	decline_monetization_decisions dmd
	left join cc_partner_offers ccpo on ccpo.decline_monetization_decision_uuid=dmd.uuid
	--left join partner_offers po on po.id=(select id from partner_offers where dmd.uuid=decline_monetization_decision_uuid and po.created_at>dmd.created_at-Interval '15 seconds' and created_at>'2017-11-15' order by created_at desc limit 1)
where --
	dmd.customer_application_uuid in (select loan_app_uuid from loan_app_pre_card))
select
	--distinct on (ca.id)
	crd.customer_id,
	ca.id as cust_app_id,
	ca.first_name,
	ca.last_name,
	cca.status as card_status,
	cae.stage::text as cc_app_stage,
	lapc.stage::text as loan_app_stage,
	vt.name as last_verifications_stage,
	vt.result as last_ver_stage_progress,
	lapc.source,
	lapc.sellable_source,
	lapc.decline_reasons as loan_decline_reasons,
	lapc.state,
	lapc.state_pass,
	lapc.ineligible_customer,
	case when
		lapc.ineligible_customer or not lapc.state_pass or not lapc.sellable_source
		then 'no card offer'
		else
		case when
			lapc.sellable_source
			and lapc.state_pass
			and not lapc.ineligible_customer
			and crd.fico_score>=550
			and lapc.requested_amount::numeric<=5000
			and ccms.net_income::numeric>=1000
			and crd.open_bankruptcy=0
			and crd.late30<=1
			and crd.open_satisfactory_trades>=1
			then
			'card hero'
			else
			'card other product link'
			end
		end
		as expected_card_offer,
	cco.template as actual_card_offer,
	lapc.requested_amount::money as requested_loan_amount,
	cco.disqualified_reasons,
	cco.not_displayed_reasons,
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
	coalesce(ccms.apr,cco.apr) as apr,
	coalesce(ccms.amf,cco.amf)::money as amf,
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
	lapc.count_30_days_past_due_active_tradelines,
	--lapc.has_open_bankruptcy,
	lapc.monthly_housing_expense,
	lapc.monthly_mortgage_payment,
	lapc.rent_or_own,
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
	lapc.loan_stacking,
	lapc.factor_trust_inquiries or position('factor_trust_inquiries' in lapc.decline_reasons)<>0 as factor_trust_inquiries
	, crd.total_credit_inquires
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
	, position('bankruptcy_model_score' in lapc.decline_reasons)<>0 as bankruptcy_model_score_decline
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
	, lapc.card_decline_reasons
	, case when ca.created_at>'2017-12-18 21:00:00' then true else false end as applied_after_new_rules
	, crd.original_rules_pass


from
	cc_applications ca
	left join
		cc_model_scores ccms
			on ccms.credit_decision_id=ca.credit_decision_id
	left join
		credit_report_details crd on ccms.transunion_credit_report_id=crd.credit_report_id
	--left join
	--	customer_applications ca on ca.credit_decision_id=ccms.credit_decision_id
	left join
		loan_app_pre_card lapc on lapc.cc_app_uuid=ca.uuid
	left join
		cc_offers cco on cco.customer_application_uuid=lapc.loan_app_uuid
	left join
		customer_application_events cae on cae.id=(select id from customer_application_events where customer_application_uuid=ca.uuid order by created_at desc limit 1)
	left join
		credit_card_accounts cca on cca.customer_application_uuid=ca.uuid
	left join
		verification_tasks vt on vt.id=(select id from verification_tasks where product_uuid=cca.uuid and product_type='CreditCardAccount' order by created_at desc limit 1)
where
	ca.product_type='credit_card' and ca.created_at>'2017-11-15'
	and ca.customer_id<>49307425 --no Tyler Bakanas Avant Test Employee
	and ca. customer_id<>76729523 --no Igor Simkin, Card King
order by card_status, cc_app_stage, customer_id, ca.created_at desc
--limit 5000

'
