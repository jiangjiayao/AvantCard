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
- **distinct on** unique value on one or multiple variabels
	- http://www.postgresqltutorial.com/postgresql-select-distinct/
- **nulls first/last** used to ranking variables, to specify null in the top or bottom
 	- https://www.postgresql.org/docs/8.3/static/queries-order.html



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
	-Test
