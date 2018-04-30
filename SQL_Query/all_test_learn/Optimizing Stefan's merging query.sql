-- select distinct stage from customer_applications where product_type = 'credit_card'

with temp_tab as (
select 
	initcap(split_part(split_part(information,'first_name: ',2),E'\n',1)) as first_name,
	initcap(split_part(split_part(information,'last_name: ',2),E'\n',1)) as last_name,
	*
from 
	customer_applications 
where 
	product_type = 'credit_card' and 
	stage is null 
order by 
	customer_id
)

select count(distinct customer_id) from temp_tabcust



select * from customer_application_metadata_fields where key = 'decline_offer_source_application_uuid' limit 100
select count(customer_application_uuid), count(distinct customer_application_uuid) from customer_application_metadata_fields where key = 'decline_offer_source_application_uuid' 

select count(uuid), count(distinct uuid) from customer_applications where product_type='credit_card' and created_at>'2017-11-15 04:43:00'

select * from customer_merges limit 100


-- checking why several merges for one acct
select * from customer_applications where uuid = '01175dc8-e921-4f05-beac-5d01ea25b883'
select * from customers where id = 6413102
select * from customer_merges where new_customer_uuid = 'dd9e9950-a548-42d6-b585-bb3f6d3ecfc7'
-- 



-- check if acct has merege
select * from customer_applications where uuid = 'de1ce4da-392d-43fe-9b6b-189390f8e91d'
select * from customers where id = 114104141
select * from customer_merges where new_customer_uuid = '48e5d1ee-4b70-47e3-8384-0c5f8249a36d'
-- 


-- re-writing Stefan's query
select
	distinct on (ca.uuid) ca.uuid as ca_uuid,
	ca.created_at,
	ca.customer_id,
	ca.stage,
	ca.source,
	ca.credit_decision_id,
	ca.status,
	ca.id,
	ca.product_type,

	c.uuid as customer_uuid,

	camf.val as declined_loan_app_uuid,
	case when camf.val is not null then 'decline_path' else 'CreditKarma' end as origin_source,

	ca.cannot_apply_reasons,
	cm.status as merge_status,
	cm.originated_from,
	cm.matched_via,
	cm.created_at as merge_time,
	case when cm.uuid is not null then true else false end as merged
from 
	customer_applications ca
left join 
	customer_application_metadata_fields camf on ca.uuid = camf.customer_application_uuid and camf.key = 'decline_offer_source_application_uuid'
left join 
	customers c on ca.customer_id = c.id
left join 
	customer_merges cm on c.uuid = cm.new_customer_uuid
where 
	ca.product_type='credit_card' and 
	ca.created_at>'2017-11-15 04:43:00'
order by
	ca.uuid, 
	cm.created_at desc nulls last





-- checking if names can be empty. According to Igor: customer_id is created when one landed on the application page
select 
	id, created_at, customer_id, 
	initcap(split_part(split_part(information,'first_name: ',2),E'\n',1)) as first_name,
	initcap(split_part(split_part(information,'last_name: ',2),E'\n',1)) as last_name,
	stage, uuid, source, credit_decision_id, status, last_seen_ip
from 
	customer_applications 
where 
	product_type = 'credit_card' and 
	created_at > '25 jan 2018' 
order by 
	created_at desc






-- finishing re-writing
select
	distinct on (ca.uuid) ca.uuid as ca_uuid,
	ca.id as customer_application_id,
	ca.customer_id,
	ca.created_at,
	ca.stage,
-- 	ca.source,
-- 	ca.credit_decision_id,
-- 	ca.status,
-- 	ca.cannot_apply_reasons,
--	ca.product_type,

-- 	c.uuid as customer_uuid,

-- 	camf.val as declined_loan_app_uuid,
	case when camf.val is not null then 'decline_path' else 'CreditKarma' end as origin_source,

	case when cm.uuid is not null then true else false end as merged,
	cm.status as merge_status,
	cm.created_at as merge_time
-- 	cm.originated_from,
-- 	cm.matched_via
from 
	customer_applications ca
left join 
	customer_application_metadata_fields camf on ca.uuid = camf.customer_application_uuid and camf.key = 'decline_offer_source_application_uuid'
left join 
	customers c on ca.customer_id = c.id
left join 
	customer_merges cm on c.uuid = cm.new_customer_uuid
where 
	ca.product_type='credit_card' and 
	ca.created_at>'2017-11-15 04:43:00'
order by
	ca.uuid, 
	cm.created_at desc nulls last



























-- Stefan's original merging query
with credit_card_applications as (
select
	ca.created_at,
	ca.customer_id,
	ca.stage,
	ca.source,
	ca.credit_decision_id,
	ca.status,
	ca.uuid,
	ca.id,
	ca.product_type,

	camf.val as declined_loan_app_uuid,
	case when camf.val is not null then 'decline_path' else 'CreditKarma' end as origin_source,

	ca.cannot_apply_reasons,
	cm.status as merge_status,
	cm.originated_from,
	cm.matched_via,
	case when cm.uuid is not null then true else false end as merged
from 
	customer_applications ca
left join 
	customer_application_metadata_fields camf on ca.uuid = camf.customer_application_uuid and camf.key = 'decline_offer_source_application_uuid'
left join 
	customers c on ca.customer_id = c.id
left join 
	customer_merges cm on c.uuid = cm.new_customer_uuid


-- cm.uuid=(select uuid from customer_merges where new_customer_uuid=c.uuid and created_at>ca.created_at order by created_at desc limit 1)
	-- I have no idea why there would be multiple merges coming up in the left join if I go straight, therefore selecting like this, probably it is matched on several things and originated from several
where 
	ca.product_type='credit_card' and 
	ca.created_at>'2017-11-15 04:43:00' --and camf.created_at>ca.created_at-interval '1 day'
)

select 
	cca.id as customer_application_id
	, cca.customer_id
	, cca.created_at
	, cca.stage
	, cca.source
	, cca.origin_source
	, cca.merged
	, cca.merge_status
from
	credit_card_applications cca
order by 
	cca.created_at






