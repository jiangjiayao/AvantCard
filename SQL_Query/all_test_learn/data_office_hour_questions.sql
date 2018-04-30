select * from credit_card_raw.account_delinquency where chd_account_number = '5159420100000015'

select * from credit_card_raw.account where chd_account_number = '5159420100000015'

select
	rawad.chd_account_number,
	rawacct.chd_open_date,
	rawacct.chd_credit_line,
	rawacct.chd_cycle_code,
	rawacct.chd_start_date_of_delq,

	rawad.chd_del_no_days
from
	credit_card_raw.account rawacct
inner join
	credit_card_raw.account_delinquency rawad on rawacct.chd_account_number = rawad.chd_account_number
	-- original wrong query: credit_card_raw.account_delinquency rawad on rawad.chd_account_number = rawad.chd_account_number
where
  rawad.chd_account_number = '5159420100000015'
