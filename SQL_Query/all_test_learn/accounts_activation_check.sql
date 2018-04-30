

-- select *,
-- exists (select 1 from activation_attempts aa where aa.customer_id = accounts.customer_id and aa.success is true) as activated
-- from accounts
-- left join payments pp on accounts.id = pp.account_id
-- where accounts.created_at > '15 Nov 2017'
-- and accounts.created_at < '1 Dec 2017'
-- order by accounts.id


-- select * from accounts limit 10
-- select * from activation_attempts limit 10



select
	ac.customer_id , ac.created_at as open_date,
 	at.channel, at.success, at.status, at.created_at as activation_date,

	case when success = 'true' then 'activated' else 'not_activated' end as activation_status
from
	accounts ac
left join
	activation_attempts at on ac.customer_id = at.customer_id and at.success = 'true'
where
	ac.created_at > '15 Nov 2017' and
 	ac.created_at < '2 Dec 2017'
order by
	ac.customer_id,
 	at.created_at desc nulls last
