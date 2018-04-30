
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
