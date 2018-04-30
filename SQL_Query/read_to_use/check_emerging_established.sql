select
	ca.id as Application_ID,
	split_part(split_part(cd.inputs,'Avant::Decisioning::Policies::Products::Card::Unsecured::US::Webbank::',2),E'\n',1)::text as Policy,
	split_part(split_part(cd.inputs,'vantage_score: ',2),E'\n',1)::varchar as Vantage_Score_2_0,
	split_part(split_part(cd.inputs,'vantage_3_0_score: ',2),E'\n',1)::varchar as Vantage_Score_3_0,
	split_part(split_part(cd.inputs, 'fico_score: ',2),E'\n',1)::varchar as FICO_Score,
	cd.model_decline_score as Model_Score,
	tzcorrect(ca.created_at)::date as Application_Date,
	cd.decline_reasons
from
	customer_applications ca
inner join
	credit_decisions cd on ca.credit_decision_id = cd.id
where
	ca.product_type = 'credit_card' and
	tzcorrect(ca.created_at):: date >= '2018-02-02
order by
	ca.created_at asc
