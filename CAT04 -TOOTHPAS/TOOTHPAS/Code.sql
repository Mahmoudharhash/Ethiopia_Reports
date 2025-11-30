----------------------------------------------------------------------------------------------------------------------------------------
-- Build the dictionary according to the report's requirement
----------------------------------------------------------------------------------------------------------------------------------------				
WITH Cleaned_Dictionary as 
(
	SELECT [category_code]
		,[sku_description]
		,[manufacturer_code]
		,[manufacturer_description]
		,[brand_code]
		,[brand_description]
		,[size_code],
		size_description ,
		sizes_cleaned,
		-- Convert sizes in (g) to (ml)
		case 
			when sizes_cleaned like '%g'
				then 
					ROUND(CAST(TRIM(REPLACE(SIZES_cleaned,'g','')) as Float) /1.4,2)
				ELSE SIZES_cleaned 
			End as Sizes_in_ml
		,[birthdate]
	FROM
---- Build SUBQUERY Including all size corrections to (ml)
	(
		SELECT [category_code]
			  ,[sku_description]
			  ,[manufacturer_code]
			  ,[manufacturer_description]
			  ,[brand_code]
			  ,[brand_description]
			  ,[size_code], size_description,
			CASE
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 1 : sizes like (120g+50g) 170g or (120ml+50ml) 170ml --- Take the number outside the parentheses
				----------------------------------------------------------------------------------------------------------------------------------------		
				WHEN size_description LIKE '%(%+%)%' 
						AND size_description LIKE '%) %'
				THEN
					TRIM( 
						REPLACE(
							RIGHT(size_description, LEN(size_description) - CHARINDEX(')', size_description)),
						'ml','')
					)
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 2 : sizes like 100ml (125g) --- Take the number outside the parentheses
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%ml %(%g%)%'
				THEN 
					TRIM(
						REPLACE(
							LEFT(size_description, CHARINDEX('(',size_description) - 1),
						'ml','')
					)
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 3 : sizes like 100ml/125g --- Take the number in (ml) 
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%ml%/%g%'
				THEN
					TRIM(
						REPLACE(
							LEFT(size_description, CHARINDEX('/',size_description) - 1),
						'ml','')
					)
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 4 : sizes like 100g/77ml --- Take the number in (ml) 
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%g%/%ml%'
				THEN
					TRIM(
						REPLACE(
							SUBSTRING(
								size_description,
								CHARINDEX('/',size_description) + 1,
								LEN(size_description)- CHARINDEX('/',size_description)),
						'ml','')
					)
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 5 : sizes like 3.3oz (100ml) --- Take the number in (ml) inside the parentheses
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%oz%(%ml)%'
				THEN
					TRIM(
						REPLACE( 
							SUBSTRING(
								size_description,
								CHARINDEX('(',size_description) + 1,
								CHARINDEX(')',size_description)  - CHARINDEX('(',size_description) - 1),
						'ml',''))
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 6 : sizes like 2.7oz (77g) --- Take the number in side the parentheses and convert it to (ml) by dividing by 1.4
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%(%g)%' 
					THEN
						TRIM(
							SUBSTRING(
								size_description,
								CHARINDEX('(', size_description) + 1,
								CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
							)
						)
				----------------------------------------------------------------------------------------------------------------------------------------
				-- CASE 7 : sizes like 5.5oz(156) --- Take the number in side the parentheses and convert it to (ml) by dividing by 1.4 
				----------------------------------------------------------------------------------------------------------------------------------------				
				WHEN size_description LIKE '%oz(%' THEN
					CONCAT(
						TRY_CAST(
							NULLIF(
								TRIM(
									SUBSTRING(
										size_description,
										CHARINDEX('(', size_description) + 1,
										CHARINDEX(')', size_description) - CHARINDEX('(', size_description) - 1
									)
								),
							'')
						AS FLOAT),
					'g')
				--------------------------------------------------------------------
				-- CASE 8 : sizes in g , ml , lt
				--------------------------------------------------------------------
				WHEN size_description LIKE '%g' 
					THEN TRIM(REPLACE(size_description,'g','' )) + 'g'
				WHEN size_description LIKE '%ml' 
					THEN TRIM(REPLACE(size_description,'ml','' ))
				WHEN size_description LIKE '%lt' 
					THEN TRIM(REPLACE(size_description,'lt','' )) + '000'
			ELSE null
			END AS sizes_cleaned
		  ,[birthdate]
		  FROM [ethiopia].[dbo].[dim_sku]
		where category_code=4
	) as t
) 
----------------------------------------------------------------------------------------------------------------------------------------
-- Classified all Sizes in Required Groups
----------------------------------------------------------------------------------------------------------------------------------------				
, ReportData as 
(
	select 
		CASE When category_code = 4 THEN 'Toothpaste' END AS Category
		,[sku_description]
		,[manufacturer_code]
		,[manufacturer_description]
		,[brand_code]
		,[brand_description]
		,[size_code],
		size_description ,
		sizes_cleaned,
		Sizes_in_ml,
		CASE
			WHEN Sizes_in_ml is null THEN 'Other'
			WHEN Sizes_in_ml <= 50 THEN '<= 50 ml'
			WHEN Sizes_in_ml Between 51 and 100 THEN ' 51 - 100 ml'
			WHEN Sizes_in_ml Between 101 and 150 THEN ' 101 - 150 ml'
			WHEN Sizes_in_ml > 150 THEN '+150 ml'
		END as Size_Group
		,[birthdate]
	 from Cleaned_Dictionary
)
----------------------------------------------------------------------------------------------------------------------------------------
-- Build the Report's shape
----------------------------------------------------------------------------------------------------------------------------------------				
, Report_hierarchy as 
(
	SELECT
		REPLICATE(' ',0) + Category as Line ,
		Category,
		Null as brand_description,
		Null as Size_Group,
		Null as sku_description ,
		0 as lvl		
	from ReportData 
	Group by Category

	UNION ALL

	SELECT
		REPLICATE(' ',2) + brand_description as Line ,
		Category,
		brand_description as brand_description,
		Null as Size_Group,
		Null as sku_description ,
		1 as lvl		
	from ReportData 
	Group by Category,brand_description

	UNION ALL

	SELECT
		REPLICATE(' ',4) + Size_Group as Line ,
		Category,
		brand_description as brand_description,
		Size_Group as Size_Group,
		Null as sku_description ,
		2 as lvl		
	from ReportData 
	Group by Category,brand_description,Size_Group

	UNION ALL

	SELECT
		REPLICATE(' ',6) + sku_description as Line ,
		Category,
		brand_description as brand_description,
		Size_Group as Size_Group,
		sku_description as sku_description ,
		3 as lvl		
	from ReportData 
	Group by Category,brand_description,Size_Group,sku_description

)

----------------------------------------------------------------------------------------------------------------------------------------
-- Execute the Final Report
----------------------------------------------------------------------------------------------------------------------------------------				
SELECT Line FROM Report_hierarchy
ORDER BY Category,brand_description,Size_Group,sku_description 
