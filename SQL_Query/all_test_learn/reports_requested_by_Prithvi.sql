/* 1. Need overall #s and by Decline/CK Originations */
-- select uuid, stage, source, created_at from customer_applications where product_type = 'credit_card' and created_at between '2018-01-18 00:00:00' and '2018-01-18 24:00:00'
-- select count(uuid), source from customer_applications where product_type = 'credit_card' and created_at between '2018-01-18 00:00:00' and '2018-01-18 24:00:00' group by source
select count(uuid), source from customer_applications where product_type = 'credit_card' group by source

/*
select 
	distinct on (ca.uuid) ca.uuid, ca.created_at as application_time, cae.customer_application_uuid, cae.event_name, cae.stage, cae.created_at as event_time
from 
	customer_applications ca
left join 
	customer_application_events cae on ca.uuid = cae.customer_application_uuid
where 
	ca.created_at between '2018-01-18 00:00:00' and '2018-01-18 24:00:00' and product_type = 'credit_card' and cae.event_name = 'viewed' and cae.stage = 'personal'
order by 
	ca.uuid, ca.created_at, cae.created_at



select 
	ca.uuid, ca.source, ca.created_at as application_time, cae_temp.*
from 
	customer_applications ca 
left join 
	(select distinct on (customer_application_uuid) customer_application_uuid, event_name, stage, created_at as event_time 
	from customer_application_events  
	where event_name = 'viewed' and stage = 'personal'
	order by customer_application_uuid, created_at desc nulls last) cae_temp on ca.uuid = cae_temp.customer_application_uuid
where
	ca.created_at between '2018-01-18 00:00:00' and '2018-01-18 24:00:00' and ca.product_type = 'credit_card'
order by 
	ca.uuid, ca.created_at desc nulls last
*/


/* 2. # & $ Issued */
-- select distinct (status) from credit_card_accounts	"rejected" "cancelled" "applied" "issued"
select * from credit_card_accounts where status = 'issued' limit 100
select count(id) from 


/* 3. # & $ Activated */
select distinct on(customer_application_uuid) customer_application_uuid, event_name, stage, created_at from customer_application_events order by customer_application_uuid, created_at desc nulls last 

select * from customer_application_events limit 100
select * from customer_applications where uuid = '000001a6-08a4-4365-869d-97be83764933'
select distinct (event_name) from customer_application_events
select distinct (stage) from customer_application_events


/* 4. Credit approval rate */
-- # of issued accounts / # of (unique) applications?


/* 5. Ver approval rate */
-- ??

/* 6. Profile - Avg. FICO, Avg. model score, Tier distribution, # of trades, Mortgage, BK, etc. */
-- ?? For all activated accounts?









