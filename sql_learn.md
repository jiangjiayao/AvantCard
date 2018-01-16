```
SELECT
	table_name
FROM
	information_schema.tables
WHERE
	table_type='BASE TABLE' AND
	table_schema='public''
```

# Sql functions
- **split_par** similar to substr
	- https://docs.aws.amazon.com/redshift/latest/dg/SPLIT_PART.html
- **initcap** capitalize initial letter of all words
	- https://docs.aws.amazon.com/redshift/latest/dg/r_INITCAP.html
- **nullif** compare two strings specified, return null if equal, return 1st string if not
	- https://docs.aws.amazon.com/redshift/latest/dg/r_NULLIF_function.html
- **cast/::** declare type of the variable
	- https://docs.aws.amazon.com/redshift/latest/dg/r_CAST_function.html
- **round** round the numnber to a specific information
	- https://docs.aws.amazon.com/redshift/latest/dg/r_ROUND.html
- **least** compare numbers, return the smallest
	- https://docs.aws.amazon.com/redshift/latest/dg/r_GREATEST_LEAST.html
