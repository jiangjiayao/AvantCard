
select
	-- apr
	pd.stats -> 'apr' -> 'inputs' -> 'spread' -> 'inputs' ->> 'pricing_strategy_id' as pricing_strategy_id,
	pd.stats -> 'apr' -> 'inputs' -> 'spread' ->> 'output' as interest_rate,

	pd.stats -> 'apr' -> 'inputs' -> 'prime_rate' ->> 'inputs' as prime_rate_in,
	pd.stats -> 'apr' -> 'inputs' -> 'prime_rate' ->> 'output' as prime_rate,

	pd.stats -> 'apr' ->> 'output' as apr,

	-- fees
	pd.stats -> 'fees' -> 'inputs' -> 'annual_membership_fee' -> 'inputs' ->> 'pricing_strategy_id' as pricing_strategy_id_2,
	pd.stats -> 'fees' -> 'inputs' -> 'annual_membership_fee' ->> 'output' as amf,

	pd.stats -> 'fees' ->> 'output' as fees_out,

	-- line
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'fico_score' as fico_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'model_score' as model_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'vantage_3_0_score' as vantage3_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' ->> 'output' as initial_credit_line,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'dti_ratio' as dti_ratio,

	round(
	((pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' ->> 'output')::numeric + GREATEST(25, 0.04 * (pd.stats -> 'line' ->> 'output')::numeric))
	/
	(nullif((pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'net_income')::numeric, 0)), 4
	) as DTI,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'net_income' as monthly_income,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'rent_or_own' as rent_or_own,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'considered_owning' as considered_owning,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'expense_as_if_owning' as expense_as_if_owning,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'customer_address_rent_or_own' as address_rent_or_own,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'customer_address_monthly_housing_payment' as monthly_housing_payment,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' ->> 'output' as monthly_debt,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' ->> 'amount_monthly_mortgage_payments' as monthly_mortgage_payment,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' ->> 'imputed_amount_monthly_minimum_payments' as imputed_monthly_min_payment,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' ->> 'output' as monthly_debt,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'monthly_net_income' as monthly_income_2,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'min_assumed_monthly_payment' as min_assumed_monthly_payment,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'policy_initial_credit_line_amounts' as initial_credit_line,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' ->> 'output' as max_line,

	pd.stats -> 'line' -> 'inputs' ->> 'policy_initial_credit_line_amounts' as initial_amount,

	pd.stats -> 'line' ->> 'output' as credit_line
from
	product_decisions pd
left join
	customer_applications ca on pd.credit_decision_id = ca.credit_decision_id
left join
	credit_card_accounts cca on ca.uuid = cca.customer_application_uuid
where
	cca.status = 'issued'
order by dti desc




-- select * from product_decisions limit 10
-- select * from credit_decisions limit 10
-- select * from credit_card_accounts limit 10









-- product_decisions.stats
/*
apr
	inputs
		spread
			inputs
				pricing_strategy_id
			output
		prime_rate
			inputs
			output
	output
*/

{
"apr":
	{
	"inputs":
		{
		"spread":
			{
			"inputs": {"pricing_strategy_id": "2002"},
			"output": 0.2074
			},
		"prime_rate":
			{
			"inputs": {},
			"output": 0.0475
			}
		},
	"output": 0.2549
	},


/*
fees
	inputs
		annual_membership_fee
			inputs
				pricing_strategy_id
			output
	output
*/

"fees":
	{
	"inputs":
		{
		"annual_membership_fee":
			{
			"inputs": {"pricing_strategy_id": "2002"},
			"output": 29.0
			}
		},
	"output": null
	},


/*
line
	inputs
		initial_credit_line
			inputs
				fico_score
				model_score
				vantage_3_0_score
			output
		maximum_line_amount
			inputs
				dti_ratio
				debt_for_dti
					inputs
						monthly_housing_expense
							inputs
								net_income
								rent_or_own
								considered_owning
								expense_as_if_owning
								customer_address_rent_or_own
								customer_address_monthly_housing_payment
							output
						amount_monthly_mortgage_payments
						imputed_amount_monthly_minimum_payments
					output
				monthly_net_income
				min_assumed_monthly_payment
				policy_initial_credit_line_amounts
			output
		policy_initial_credit_line_amounts
	output
*/

"line":
	{
	"inputs":
		{
		"initial_credit_line":
			{
			"inputs":
				{
				"fico_score": 627,
				"model_score": 0.08741387494673,
				"vantage_3_0_score": 622
				},
			"output": 500.0
			},

		"maximum_line_amount":
			{
			"inputs":
				{
				"dti_ratio": 0.7,
				"debt_for_dti":
					{
					"inputs":
						{
						"monthly_housing_expense":
							{
							"inputs":
								{
								"net_income": 2500.0,
								"rent_or_own": "own",
								"considered_owning": true,
								"expense_as_if_owning": 0.0,
								"customer_address_rent_or_own": "own",
								"customer_address_monthly_housing_payment": 0.0
								},
							"output": 0.0
							},
						"amount_monthly_mortgage_payments": 0,
						"imputed_amount_monthly_minimum_payments": 1164
						},
					"output": 1164.0
					},
				"monthly_net_income": 2500.0,
				"min_assumed_monthly_payment": 25.0,
				"policy_initial_credit_line_amounts": [1000.0, 750.0, 500.0, 300.0]
				},
			"output": 1000.0
			},
		"policy_initial_credit_line_amounts": [1000.0, 750.0, 500.0, 300.0]
		},
	"output": 500.0
	}

}













-- checking which accounts have adjusted credit lines

with ttable as (
select
	pd.customer_id,
	-- apr
	pd.stats -> 'apr' -> 'inputs' -> 'spread' -> 'inputs' ->> 'pricing_strategy_id' as pricing_strategy_id,
	pd.stats -> 'apr' -> 'inputs' -> 'spread' ->> 'output' as interest_rate,

	pd.stats -> 'apr' -> 'inputs' -> 'prime_rate' ->> 'inputs' as prime_rate_in,
	pd.stats -> 'apr' -> 'inputs' -> 'prime_rate' ->> 'output' as prime_rate,

	pd.stats -> 'apr' ->> 'output' as apr,

	-- fees
	pd.stats -> 'fees' -> 'inputs' -> 'annual_membership_fee' -> 'inputs' ->> 'pricing_strategy_id' as pricing_strategy_id_2,
	pd.stats -> 'fees' -> 'inputs' -> 'annual_membership_fee' ->> 'output' as amf,

	pd.stats -> 'fees' ->> 'output' as fees_out,

	-- line
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'fico_score' as fico_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'model_score' as model_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' -> 'inputs' ->> 'vantage_3_0_score' as vantage3_score,
	pd.stats -> 'line' -> 'inputs' -> 'initial_credit_line' ->> 'output' as initial_credit_line,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'dti_ratio' as dti_ratio,

	round(
	((pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' ->> 'output')::numeric + GREATEST(25, 0.04 * (pd.stats -> 'line' ->> 'output')::numeric))
	/
	(nullif((pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'net_income')::numeric, 0)), 4
	) as DTI,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'net_income' as monthly_income,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'rent_or_own' as rent_or_own,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'considered_owning' as considered_owning,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'expense_as_if_owning' as expense_as_if_owning,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'customer_address_rent_or_own' as address_rent_or_own,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' -> 'inputs' ->> 'customer_address_monthly_housing_payment' as monthly_housing_payment,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' -> 'monthly_housing_expense' ->> 'output' as monthly_debt,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' ->> 'amount_monthly_mortgage_payments' as monthly_mortgage_payment,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' -> 'inputs' ->> 'imputed_amount_monthly_minimum_payments' as imputed_monthly_min_payment,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' -> 'debt_for_dti' ->> 'output' as monthly_debt,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'monthly_net_income' as monthly_income_2,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'min_assumed_monthly_payment' as min_assumed_monthly_payment,
	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' -> 'inputs' ->> 'policy_initial_credit_line_amounts' as policy_initial_credit_line,

	pd.stats -> 'line' -> 'inputs' -> 'maximum_line_amount' ->> 'output' as max_line,

	pd.stats -> 'line' -> 'inputs' ->> 'policy_initial_credit_line_amounts' as initial_amount,

	pd.stats -> 'line' ->> 'output' as credit_line
from
	product_decisions pd
left join
	customer_applications ca on pd.credit_decision_id = ca.credit_decision_id
left join
	credit_card_accounts cca on ca.uuid = cca.customer_application_uuid
where
	cca.status = 'issued'
order by dti desc
)

select * from ttable where initial_credit_line <> credit_line
