# show all tables
```
SELECT
	table_name
FROM
	information_schema.tables
WHERE
	table_schema='public' AND
	table_type='BASE TABLE'
```
# show all columns from a table
```
SELECT
	column_name
FROM
	information_schema.columns
WHERE
	table_schema = 'credit_card_raw' AND
	table_name   = 'account'
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
- **distinct on** unique value on one or multiple variabels
	- http://www.postgresqltutorial.com/postgresql-select-distinct/
- **nulls first/last** used to ranking variables, to specify null in the top or bottom
 	- https://www.postgresql.org/docs/8.3/static/queries-order.html

# Presto
- **show schemas** show all schemas in current connection
	- https://stackoverflow.com/questions/40938321/show-tables-from-all-schemas-in-presto-db
- **show tables from [schema_name]** get all tables under a certain schema
- **show columns from [schema_name].[table_name]**


# Sql mechanisms
- ** multiple joins**
	- https://www.interfacett.com/blogs/multiple-joins-work-just-like-single-joins/
	- e.g. a has 100, b has 50, c has 10,
	```
		from a
		left join b on a.uid = b.uid
		left join c on b.uid = c.uuid
		# 100 records after first join, 50 left after second join.
		# because second join is on table b
	```


- ** nested case statements**
	- https://community.oracle.com/thread/1066018?start=0
