




-- credit_card_api.accounts.customer_id <-> avant_basic.customers.uuid
-- avant_basic.customers.id <-> avant_basic.customer_applications.cusotmer_id

select
  cca.id, cca.first_data_account_reference, cca.created_at as open_date,
  abc.uuid as customer_uuid,
  aba.uuid as application_uuid, aba.customer_id, aba.created_at as application_date, aba.stage, aba.source, aba.credit_decision_id, aba.status, aba.product_type--,
  --	split_part(aba.information,'first_name: ',2) as first_name,
  -- 	split_part(aba.information,'last_name: ',2) as last_name,
  -- 	split_part(aba.information,'income_type: ',2) AS income_type
from
  credit_card_api.accounts cca
left join
  avant_basic.customers abc on cca.customer_id = abc.uuid
left join
  avant_basic.customer_applications aba on abc.id = aba.customer_id and aba.product_type = 'credit_card'
where
  aba.customer_id = 76729523
order by
  aba.customer_id,
  cca.created_at, -- open_date
  aba.created_at -- application_date







-- reverse order
with
temp as(
select
  ca.uuid as application_uuid,
  ca.customer_id,
  ca.created_at as application_date,
  ca.stage,
  ca.source,
  ca.credit_decision_id,
  ca.status,
  ca.product_type,

  c.uuid as customer_uuid,

  a.id as issued_card_id,
  a.first_data_account_reference,
  a.created_at as open_date
from
  avant_basic.customer_applications ca
left join
  avant_basic.customers c on ca.customer_id = c.id
left join
  credit_card_api.accounts a on c.uuid = a.customer_id
where
  ca.product_type = 'credit_card'
)
select count(application_uuid), count(distinct application_uuid), count(issued_card_id), count(distinct issued_card_id) from temp
