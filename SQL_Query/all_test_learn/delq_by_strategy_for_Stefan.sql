select
	fda.card_account_16_identifier,
	fda.credit_line_amount,
	fda.cycle_date,
	fda.delinquent_start_date,
	fda.account_system_entry_date,

	fdad.card_account_delinquent_day_count
from
	first_data_prod.account fda
left join
	first_data_prod.account_delinquency fdad on fda.card_account_16_identifier = fdad.card_account_16_identifier
left join
	credit_card_api.accounts cca on fda.card_account_16_identifier = cca.first_data_account_reference
left join
	avant_basic.customers fpc on cca.customer_id = fpc.uuid
left join
	avant_basic.customer_applications fpca on fpc.id = fpca.customer_id and fpca.product_type = 'credit_card'
where
	fda.account_system_entry_date > '15 nov 2017' and
	fda.account_system_entry_date < '05 dec 2018'











select
	rawacct.chd_account_number,
	rawacct.chd_open_date,
	rawacct.chd_credit_line,
	rawacct.chd_cycle_code,
	rawacct.chd_start_date_of_delq,

	rawad.chd_del_no_days
from
	credit_card_raw.account rawacct
left join
	credit_card_raw.account_delinquency rawad on rawad.chd_account_number = rawad.chd_account_number
left join
	credit_card_api.accounts cca on rawacct.chd_account_number = cca.first_data_account_reference
left join
	avant_basic.customers fpc on cca.customer_id = fpc.uuid
left join
	avant_basic.customer_applications fpca on fpc.id = fpca.customer_id and fpca.product_type = 'credit_card'
where
	rawacct.chd_open_date '171118')









	select
	  accounts.id,
	  accounts.first_data_account_reference,
	  accounts.created_at,
	  case
	    when (accounts.created_at >= '16 nov 2017' and accounts.created_at < '18 nov 2017') then '12/11'
	    when (accounts.created_at >= '18 nov 2017' and accounts.created_at < '24 nov 2017') then '12/17'
	    when (accounts.created_at >= '24 nov 2017' and accounts.created_at < '02 dec 2017') then '12/23'
	    when (accounts.created_at >= '02 dec 2017' and accounts.created_at < '06 dec 2017') then '01/01'
	    when (accounts.created_at >= '06 dec 2017' and accounts.created_at < '12 dec 2017') then '01/05'
	    else 'wrong'
	  end as cycle_date,

	  case
	    when (accounts.created_at >= '15 nov 2017' and accounts.created_at < '18 nov 2017') then '01/07'
	    when (accounts.created_at >= '18 nov 2017' and accounts.created_at < '24 nov 2017') then '01/13'
	    when (accounts.created_at >= '24 nov 2017' and accounts.created_at < '02 dec 2017') then '01/19'
	    when (accounts.created_at >= '02 dec 2017' and accounts.created_at < '06 dec 2017') then '01/25'
	    when (accounts.created_at >= '06 dec 2017' and accounts.created_at < '12 dec 2017') then '02/01'
	    else 'wrong'
	  end as due_date,


	  payments.date,
	  payments.created_at,
	  payments.scheduled_amount_cents

	from
	  accounts
	left join
	  payments on accounts.id = payments.account_id
	where
	  accounts.created_at > '15 nov 2017' and
	  accounts.created_at < '12 dec 2017'
	order by
	  accounts.id,
	  accounts.created_at,
	  payments.date





















	  with
	  fdta as(
	  SELECT
	  	account.chd_account_number  AS "fdta_account_reference",
	  	DATE_FORMAT(cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) , '%Y-%m-%d') AS "account.account_system_entry_date",
	  	DATE_FORMAT(CASE
	      WHEN (historical_cardholder_data.chd_date_prev_stmt = '0' OR historical_cardholder_data.chd_date_prev_stmt IS NULL)  THEN NULL
	      ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_prev_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,5,2)) as date) END , '%Y-%m-%d') AS "historical_cardholder_data.previous_statement_date",
	  	DATE_FORMAT(CASE
	        WHEN (cast(chdls_pymt_due_rljl_dt as integer) <= 365 AND chdls_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chdls_pymt_due_rljl_dt), '%Y%j')
	        WHEN (cast(chdls_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chdls_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
	        ELSE null END, '%Y-%m-%d') AS "current_monetary_activity.last_statement_payment_due_date",
	  	CAST(historical_cardholder_data.chd_hist_ps_bal as double)  AS "historical_cardholder_data.previous_statement_balance_amount",
	  	CAST(current_monetary_activity.chdps_billed_pay_due as double) AS "cma.previous_statement_minimum_pay_due_amount",
	  	CAST(current_monetary_activity.chd_ls_amt_payment as double) AS "current_monetary_activity.last_statement_payment_amt",
	  	DATE_FORMAT(CASE
	      WHEN (historical_cardholder_data.chd_date_last_stmt = '0' OR historical_cardholder_data.chd_date_last_stmt IS NULL)  THEN NULL
	      ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_last_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,5,2)) as date) END , '%Y-%m-%d') AS "historical_cardholder_data.last_statement_date",
	  	DATE_FORMAT(CASE
	        WHEN (cast(chd_pymt_due_rljl_dt as integer) <= 365 AND chd_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chd_pymt_due_rljl_dt), '%Y%j')
	        WHEN (cast(chd_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chd_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
	        ELSE null END, '%Y-%m-%d') AS "current_monetary_activity.current_cycle_payment_due_date",
	  	CAST(current_monetary_activity.chd_last_statemented_bal as double) AS "current_monetary_activity.last_statement_balance_amount",
	  	CAST(current_monetary_activity.chdls_billed_pay_due as double) AS "current_monetary_activity.last_statement_minimum_pay_due_amount",
	  	CAST(current_monetary_activity.chd_ctd_amt_payment as double) AS "current_monetary_activity.cycle_to_date_payments_posted_amount"
	  FROM hive.credit_card_raw.current_monetary_activity  AS current_monetary_activity
	  FULL OUTER JOIN hive.credit_card_raw.account  AS account ON current_monetary_activity.chd_account_number = account.chd_account_number
	  FULL OUTER JOIN hive.credit_card_raw.historical_cardholder_data  AS historical_cardholder_data ON current_monetary_activity.chd_account_number = historical_cardholder_data.chd_account_number

	  WHERE
	  	(((cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) >= (TIMESTAMP '2017-11-16') AND (cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) < (TIMESTAMP '2017-12-06')))
	  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
	  ),


	  api as(
	  select
	    ccaa.id,
	    ccaa.first_data_account_reference,
	    ccaa.created_at,
	    case
	      when (ccaa.created_at >= '16 nov 2017' and ccaa.created_at < '18 nov 2017') then '12/11'
	      when (ccaa.created_at >= '18 nov 2017' and ccaa.created_at < '24 nov 2017') then '12/17'
	      when (ccaa.created_at >= '24 nov 2017' and ccaa.created_at < '02 dec 2017') then '12/23'
	      when (ccaa.created_at >= '02 dec 2017' and ccaa.created_at < '06 dec 2017') then '01/01'
	      when (ccaa.created_at >= '06 dec 2017' and ccaa.created_at < '12 dec 2017') then '01/05'
	      else 'wrong'
	    end as cycle_date,

	    case
	      when (ccaa.created_at >= '15 nov 2017' and ccaa.created_at < '18 nov 2017') then '01/07'
	      when (ccaa.created_at >= '18 nov 2017' and ccaa.created_at < '24 nov 2017') then '01/13'
	      when (ccaa.created_at >= '24 nov 2017' and ccaa.created_at < '02 dec 2017') then '01/19'
	      when (ccaa.created_at >= '02 dec 2017' and ccaa.created_at < '06 dec 2017') then '01/25'
	      when (ccaa.created_at >= '06 dec 2017' and ccaa.created_at < '12 dec 2017') then '02/01'
	      else 'wrong'
	    end as due_date,

	    ccap.date,
	    ccap.scheduled_amount_cents
	  from
	    credit_card_api.accounts ccaa
	  left join
	    credit_card_api.payments ccap on ccaa.id = ccap.account_id
	  where
	    ccaa.created_at > '15 nov 2017' and
	    ccaa.created_at < '12 dec 2017'
	  order by
	    ccaa.id,
	    ccaa.created_at,
	    ccap.date
	  )


	  select
	    fdta.*,
	    api.*
	  from
	    fdta
	  left join
	    api on fdta.fdta_account_reference = api.first_data_account_reference
















	  select
	    rawact.chd_account_number,
	    rawact.chd_open_date,
	    rawhcd.chd_date_prev_stmt,
	    rawcma.chdls_pymt_due_rljl_dt,
	    rawhcd.chd_hist_ps_bal,
	    rawcma.chdps_billed_pay_due,
	    rawcma.chd_ls_amt_payment,
	    rawhcd.chd_date_last_stmt,
	    rawcma.chd_pymt_due_rljl_dt,
	    rawcma.chd_last_statemented_bal,
	    rawcma.chdls_billed_pay_due,
	  --  rawcma.chd_ctd_amt_payment,
	    ccap.scheduled_amount_cents / 100 as payment_amt,
	    ccap.date as payment_date
	  from
	    credit_card_raw.account rawact
	  left join
	    credit_card_raw.historical_cardholder_data rawhcd on rawact.chd_account_number = rawhcd.chd_account_number
	  left join
	    credit_card_raw.current_monetary_activity rawcma on rawact.chd_account_number = rawcma.chd_account_number
	  left join
	    credit_card_api.accounts ccaa on rawact.chd_account_number = ccaa.first_data_account_reference
	  left join
	    credit_card_api.payments ccap on ccaa.id = ccap.account_id
	  where
	    rawact.chd_account_number = '5159420100000833'



























with
fdta as(
SELECT
	account.chd_account_number  AS "fdta_account_reference",
	DATE_FORMAT(cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) , '%Y-%m-%d') AS "account_system_entry_date",
	DATE_FORMAT(CASE
    WHEN (historical_cardholder_data.chd_date_prev_stmt = '0' OR historical_cardholder_data.chd_date_prev_stmt IS NULL)  THEN NULL
    ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_prev_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,5,2)) as date) END , '%Y-%m-%d') AS "previous_statement_date",
	DATE_FORMAT(CASE
      WHEN (cast(chdls_pymt_due_rljl_dt as integer) <= 365 AND chdls_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chdls_pymt_due_rljl_dt), '%Y%j')
      WHEN (cast(chdls_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chdls_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
      ELSE null END, '%Y-%m-%d') AS "last_statement_payment_due_date",
	CAST(historical_cardholder_data.chd_hist_ps_bal as double)  AS "previous_statement_balance_amount",
	CAST(current_monetary_activity.chdps_billed_pay_due as double) AS "previous_statement_minimum_pay_due_amount",
	CAST(current_monetary_activity.chd_ls_amt_payment as double) AS "last_statement_payment_amt",
	DATE_FORMAT(CASE
    WHEN (historical_cardholder_data.chd_date_last_stmt = '0' OR historical_cardholder_data.chd_date_last_stmt IS NULL)  THEN NULL
    ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_last_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,5,2)) as date) END , '%Y-%m-%d') AS "last_statement_date",
	DATE_FORMAT(CASE
      WHEN (cast(chd_pymt_due_rljl_dt as integer) <= 365 AND chd_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chd_pymt_due_rljl_dt), '%Y%j')
      WHEN (cast(chd_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chd_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
      ELSE null END, '%Y-%m-%d') AS "current_cycle_payment_due_date",
	CAST(current_monetary_activity.chd_last_statemented_bal as double) AS "last_statement_balance_amount",
	CAST(current_monetary_activity.chdls_billed_pay_due as double) AS "last_statement_minimum_pay_due_amount",
	CAST(current_monetary_activity.chd_ctd_amt_payment as double) AS "cycle_to_date_payments_posted_amount"
FROM hive.credit_card_raw.current_monetary_activity  AS current_monetary_activity
FULL OUTER JOIN hive.credit_card_raw.account  AS account ON current_monetary_activity.chd_account_number = account.chd_account_number
FULL OUTER JOIN hive.credit_card_raw.historical_cardholder_data  AS historical_cardholder_data ON current_monetary_activity.chd_account_number = historical_cardholder_data.chd_account_number

WHERE
	(((cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) >= (TIMESTAMP '2017-11-16') AND (cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) < (TIMESTAMP '2017-12-06')))
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
),


ccapi as(
select
  ccaa.first_data_account_reference,
  ccaa.created_at as open_date,

  ccap.date as payment_date,
  ccap.scheduled_amount_cents / 100 as payment_amount
from
  credit_card_api.accounts ccaa
left join
  credit_card_api.payments ccap on ccaa.id = ccap.account_id
order by
  ccaa.id,
  ccaa.created_at,
  ccap.date
),



prep_1 as(
select
  fdta.*,
  ccapi.*,
  case
    when fdta.account_system_entry_date in ('2017-11-15', '2017-11-16', '2017-11-17') then '2017-12-11'
    when fdta.account_system_entry_date in ('2017-11-18', '2017-11-19', '2017-11-20', '2017-11-21', '2017-11-22', '2017-11-23') then '2017-12-17'
    when fdta.account_system_entry_date in ('2017-11-24', '2017-11-25', '2017-11-26', '2017-11-27', '2017-11-28', '2017-11-29', '2017-11-30', '2017-12-01') then '2017-12-23'
    when fdta.account_system_entry_date in ('2017-12-02', '2017-12-03', '2017-12-04', '2017-12-05') then '2018-01-01'
    when fdta.account_system_entry_date in ('2017-12-06', '2017-12-07', '2017-12-08', '2017-12-09', '2017-12-10', '2017-12-11') then '2018-01-05'
    else 'wrong'
  end as first_cycle_end_dt,

  case
    when fdta.account_system_entry_date in ('2017-11-15','2017-11-16', '2017-11-17') then '2018-01-07'
    when fdta.account_system_entry_date in ('2017-11-18','2017-11-19', '2017-11-20', '2017-11-21', '2017-11-22', '2017-11-23') then '2018-01-13'
    when fdta.account_system_entry_date in ('2017-11-24','2017-11-25', '2017-11-26', '2017-11-27', '2017-11-28', '2017-11-29', '2017-11-30', '2017-12-01') then '2018-01-19'
    when fdta.account_system_entry_date in ('2017-12-02', '2017-12-03', '2017-12-04', '2017-12-05') then '2018-01-25'
    when fdta.account_system_entry_date in ('2017-12-06', '2017-12-07', '2017-12-08', '2017-12-09', '2017-12-10', '2017-12-11') then '2018-02-01'
    else 'wrong'
  end as first_ever_due_date

from
  fdta
left join
  ccapi on fdta.fdta_account_reference = ccapi.first_data_account_reference
order by
  fdta.account_system_entry_date,
  fdta.fdta_account_reference,
  ccapi.payment_date
)


select
  *,
  case when (payment_date is null) or ((payment_date is not null) and (payment_date > first_cycle_end_date) and (payment_date <= first_ever_due_date) then 'keep' else 'no' end as keepornot,
  case when system_entry_date < 2017-12-03 then previous_statement_minimum_pay_due_amount else last_statement_minimum_pay_due_amount end as minpaytouse
from
  prep_1


select
  fdta_account_reference,
  account_system_entry_date,
  first_cycle_end_date,
  first_ever_due_date,
  minpaytouse,
  sum(payment_amount) as tot_pay
from
  prep_2
where
  keepornot = 'keep'
group by
  fdta_account_reference,
  account_system_entry_date,
  first_cycle_end_date,
  first_ever_due_date,
  minpaytouse


select
  *,
  case when (tot_pay >= minpaytouse) then "no delq 1st cycle at due date" else "delq 1st cycle at due date"
from
  prep_3




























-----------------------------------------------------
-- Added measurement_date from credit_card_raw
-- Added customer_id from credit_card_api
-----------------------------------------------------

with
fdta as(
SELECT
	account.chd_account_number  AS "fdta_account_reference",
	DATE_FORMAT(cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) , '%Y-%m-%d') AS "account_system_entry_date",
	DATE_FORMAT(CASE
    WHEN (historical_cardholder_data.chd_date_prev_stmt = '0' OR historical_cardholder_data.chd_date_prev_stmt IS NULL)  THEN NULL
    ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_prev_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_prev_stmt,5,2)) as date) END , '%Y-%m-%d') AS "previous_statement_date",
	DATE_FORMAT(CASE
      WHEN (cast(chdls_pymt_due_rljl_dt as integer) <= 365 AND chdls_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chdls_pymt_due_rljl_dt), '%Y%j')
      WHEN (cast(chdls_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chdls_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
      ELSE null END, '%Y-%m-%d') AS "last_statement_payment_due_date",
	CAST(historical_cardholder_data.chd_hist_ps_bal as double)  AS "previous_statement_balance_amount",
	CAST(current_monetary_activity.chdps_billed_pay_due as double) AS "previous_statement_minimum_pay_due_amount",
	CAST(current_monetary_activity.chd_ls_amt_payment as double) AS "last_statement_payment_amt",
	DATE_FORMAT(CASE
    WHEN (historical_cardholder_data.chd_date_last_stmt = '0' OR historical_cardholder_data.chd_date_last_stmt IS NULL)  THEN NULL
    ELSE cast(concat('20',substr(historical_cardholder_data.chd_date_last_stmt,1,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,3,2),'-',substr(historical_cardholder_data.chd_date_last_stmt,5,2)) as date) END , '%Y-%m-%d') AS "last_statement_date",
	DATE_FORMAT(CASE
      WHEN (cast(chd_pymt_due_rljl_dt as integer) <= 365 AND chd_pymt_due_rljl_dt != '0' ) THEN date_parse(concat(cast(year(current_date) - 1 as varchar),chd_pymt_due_rljl_dt), '%Y%j')
      WHEN (cast(chd_pymt_due_rljl_dt as integer) > 365) THEN date_parse(concat(cast(year(current_date) as varchar), cast(cast(chd_pymt_due_rljl_dt as integer) - 365 as varchar)), '%Y%j')
      ELSE null END, '%Y-%m-%d') AS "current_cycle_payment_due_date",
	CAST(current_monetary_activity.chd_last_statemented_bal as double) AS "last_statement_balance_amount",
	CAST(current_monetary_activity.chdls_billed_pay_due as double) AS "last_statement_minimum_pay_due_amount",
	CAST(current_monetary_activity.chd_ctd_amt_payment as double) AS "cycle_to_date_payments_posted_amount"
FROM hive.credit_card_raw.current_monetary_activity  AS current_monetary_activity
FULL OUTER JOIN hive.credit_card_raw.account  AS account ON current_monetary_activity.chd_account_number = account.chd_account_number AND (DATE_FORMAT(DATE(concat(substr(account.header_cycle_dt,7,4),'-',substr(account.header_cycle_dt,1,2),'-',substr(account.header_cycle_dt,4,2))), '%Y-%m-%d')) = (DATE_FORMAT(DATE(concat(substr(current_monetary_activity.header_cycle_dt,7,4),'-',substr(current_monetary_activity.header_cycle_dt,1,2),'-',substr(current_monetary_activity.header_cycle_dt,4,2))), '%Y-%m-%d'))
FULL OUTER JOIN hive.credit_card_raw.historical_cardholder_data  AS historical_cardholder_data ON account.chd_account_number = historical_cardholder_data.chd_account_number AND (DATE_FORMAT(DATE(concat(substr(account.header_cycle_dt,7,4),'-',substr(account.header_cycle_dt,1,2),'-',substr(account.header_cycle_dt,4,2))), '%Y-%m-%d')) = (DATE_FORMAT(DATE(concat(substr(historical_cardholder_data.header_cycle_dt,7,4),'-',substr(historical_cardholder_data.header_cycle_dt,1,2),'-',substr(historical_cardholder_data.header_cycle_dt,4,2))), '%Y-%m-%d'))

WHERE ((((DATE(concat(substr(account.header_cycle_dt,7,4),'-',substr(account.header_cycle_dt,1,2),'-',substr(account.header_cycle_dt,4,2)))) >= ((TIMESTAMP '2018-02-01')) AND (DATE(concat(substr(account.header_cycle_dt,7,4),'-',substr(account.header_cycle_dt,1,2),'-',substr(account.header_cycle_dt,4,2)))) < ((DATE_ADD('day', 1, TIMESTAMP '2018-02-01')))))) AND ((((cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) >= (TIMESTAMP '2017-11-16') AND (cast(concat('20',substr(account.chd_open_date,1,2),'-',substr(account.chd_open_date,3,2),'-',substr(account.chd_open_date,5,2)) as date) ) < (TIMESTAMP '2017-12-12'))))
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
ORDER BY 2
),


ccapi as(
select
  ccaa.first_data_account_reference,

  ccac.simple_id,

  ccaa.created_at as open_date,

  ccap.date as payment_date,
  ccap.scheduled_amount_cents / 100 as payment_amount
from
  credit_card_api.accounts ccaa
left join
  credit_card_api.payments ccap on ccaa.id = ccap.account_id
left join
  credit_card_api.customers ccac on ccaa.customer_id = ccac.id
order by
  ccaa.id,
  ccaa.created_at,
  ccap.date
)





select
  fdta.*,
  ccapi.*,
  case
    when fdta.account_system_entry_date in ('2017-11-15', '2017-11-16', '2017-11-17') then '2017-12-11'
    when fdta.account_system_entry_date in ('2017-11-18', '2017-11-19', '2017-11-20', '2017-11-21', '2017-11-22', '2017-11-23') then '2017-12-17'
    when fdta.account_system_entry_date in ('2017-11-24', '2017-11-25', '2017-11-26', '2017-11-27', '2017-11-28', '2017-11-29', '2017-11-30', '2017-12-01') then '2017-12-23'
    when fdta.account_system_entry_date in ('2017-12-02', '2017-12-03', '2017-12-04', '2017-12-05') then '2018-01-01'
    when fdta.account_system_entry_date in ('2017-12-06', '2017-12-07', '2017-12-08', '2017-12-09', '2017-12-10', '2017-12-11') then '2018-01-05'
    else 'wrong'
  end as first_cycle_end_dt,

  case
    when fdta.account_system_entry_date in ('2017-11-15','2017-11-16', '2017-11-17') then '2018-01-07'
    when fdta.account_system_entry_date in ('2017-11-18','2017-11-19', '2017-11-20', '2017-11-21', '2017-11-22', '2017-11-23') then '2018-01-13'
    when fdta.account_system_entry_date in ('2017-11-24','2017-11-25', '2017-11-26', '2017-11-27', '2017-11-28', '2017-11-29', '2017-11-30', '2017-12-01') then '2018-01-19'
    when fdta.account_system_entry_date in ('2017-12-02', '2017-12-03', '2017-12-04', '2017-12-05') then '2018-01-25'
    when fdta.account_system_entry_date in ('2017-12-06', '2017-12-07', '2017-12-08', '2017-12-09', '2017-12-10', '2017-12-11') then '2018-02-01'
    else 'wrong'
  end as first_ever_due_date

from
  fdta
left join
  ccapi on fdta.fdta_account_reference = ccapi.first_data_account_reference
order by
  fdta.account_system_entry_date,
  fdta.fdta_account_reference,
  ccapi.payment_date
