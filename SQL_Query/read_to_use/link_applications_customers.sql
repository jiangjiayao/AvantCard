




select 
  ca.*
from
  customers
left join
  customer_applications ca on customers.id = ca.customer_id
where
  ca.product_type = 'credit_card' and
  customers.uuid = 'd4d49beb-90d2-42b5-b075-9000bbbec860'
